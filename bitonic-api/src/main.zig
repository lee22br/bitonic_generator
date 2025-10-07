const std = @import("std");
const zap = @import("zap");
const bitonic = @import("bitonic.zig");
const okredis = @import("okredis");
const net = std.net;

var redis_client: ?okredis.Client = null;
var redis_rbuf: [1024]u8 = undefined;
var redis_wbuf: [1024]u8 = undefined;

pub fn main() !void {
    std.debug.print("Connecting to Redis at redis:6379\n", .{});
    
    // Initialize Redis client
    redis_client = blk: {
        std.debug.print("Connecting to redis service...\n", .{});
        
        // Use getAddressList as primary method (works better in Docker)
        var address_list = std.net.getAddressList(std.heap.page_allocator, "redis", 6379) catch |err| {
            std.debug.print("Could not resolve redis service: {}\n", .{err});
            break :blk null;
        };
        defer address_list.deinit();
        
        if (address_list.addrs.len == 0) {
            std.debug.print("No addresses found for redis service\n", .{});
            break :blk null;
        }
        
        const redis_addr = address_list.addrs[0];
        
        const connection = net.tcpConnectToAddress(redis_addr) catch |err| {
            std.debug.print("Could not connect to Redis: {}\n", .{err});
            break :blk null;
        };
        
        const client = okredis.Client.init(connection, .{
            .reader_buffer = &redis_rbuf,
            .writer_buffer = &redis_wbuf,
        }) catch |err| {
            std.debug.print("Could not initialize Redis client: {}\n", .{err});
            break :blk null;
        };
        
        std.debug.print("Successfully connected to Redis!\n", .{});
        break :blk client;
    };

    var listener = zap.HttpListener.init(.{
        .port = 8080,
        .on_request = handleRequest,
    });
    try listener.listen();
    zap.start(.{
        .threads = 2,
        .workers = 2,
    });
}

fn handleRequest(r: zap.Request) !void {
    if (r.path) |path| {
        if (std.mem.eql(u8, path, "/bitonic") and std.mem.eql(u8, r.method.?, "POST")) {
            try handleBitonic(&r);
            return;
        }
    }
    r.setStatus(.not_found);
    r.sendBody("Not Found") catch {};
}

fn handleBitonic(r: *const zap.Request) !void {
    const allocator = std.heap.page_allocator;

    const body = r.body orelse {
        r.setStatus(.bad_request);
        r.sendBody("{ \"error\": \"Missing request body\" }") catch {};
        return;
    };

    var parsed = std.json.parseFromSlice(std.json.Value, allocator, body, .{}) catch {
        r.setStatus(.bad_request);
        r.sendBody("{ \"error\": \"Invalid JSON\" }") catch {};
        return;
    };
    defer parsed.deinit();

    const obj = parsed.value;
    const length = obj.object.get("length") orelse {
        r.setStatus(.bad_request);
        r.sendBody("{ \"error\": \"Missing 'length'\" }") catch {};
        return;
    };
    const start = obj.object.get("start") orelse {
        r.setStatus(.bad_request);
        r.sendBody("{ \"error\": \"Missing 'start'\" }") catch {};
        return;
    };
    const end = obj.object.get("end") orelse {
        r.setStatus(.bad_request);
        r.sendBody("{ \"error\": \"Missing 'end'\" }") catch {};
        return;
    };

    if (length != .integer or start != .integer or end != .integer) {
        r.setStatus(.bad_request);
        r.sendBody("{ \"error\": \"Invalid field types\" }") catch {};
        return;
    }

    const length_val = @as(usize, @intCast(length.integer));
    const start_val = @as(i32, @intCast(start.integer));
    const end_val = @as(i32, @intCast(end.integer));

    // Create cache key: "length,start,end"
    const cache_key = try std.fmt.allocPrint(allocator, "{},{},{}", .{ length_val, start_val, end_val });
    defer allocator.free(cache_key);

    std.debug.print("Checking cache for key: {s}\n", .{cache_key});

    var json_response: []u8 = undefined;
    var from_cache = false;

    // Try to get from cache first
    if (redis_client) |*client| {
        if (client.sendAlloc([]u8, allocator, .{ "GET", cache_key })) |cached_sequence| {
            defer allocator.free(cached_sequence);
            std.debug.print("Cache HIT for key: {s}\n", .{cache_key});
            json_response = try std.fmt.allocPrint(allocator, "{{ \"sequence\": {s} }}", .{cached_sequence});
            from_cache = true;
        } else |_| {
            std.debug.print("Cache MISS for key: {s}\n", .{cache_key});
        }
    }

    // If not found in cache, generate new sequence
    if (!from_cache) {
        const result = bitonic.bitonicArray(allocator, length_val, start_val, end_val) catch {
            r.setStatus(.bad_request);
            const error_msg = std.fmt.allocPrint(allocator, "{{ \"error\": \"It's not possible to generate sequence of length {} in range [{}, {}]\" }}", .{ length.integer, start.integer, end.integer }) catch "{ \"error\": \"Invalid input\" }";
            r.sendBody(error_msg) catch {};
            return;
        };
        defer allocator.free(result);

        // Format the array as JSON
        var json_array = try std.ArrayList(u8).initCapacity(allocator, 256);
        defer json_array.deinit(allocator);

        try json_array.appendSlice(allocator, "[");
        for (result, 0..) |val, i| {
            if (i > 0) try json_array.appendSlice(allocator, ",");
            const val_str = try std.fmt.allocPrint(allocator, "{}", .{val});
            defer allocator.free(val_str);
            try json_array.appendSlice(allocator, val_str);
        }
        try json_array.appendSlice(allocator, "]");

        // Cache the result
        if (redis_client) |*client| {
            client.send(void, .{ "SET", cache_key, json_array.items }) catch |err| {
                std.debug.print("Warning: Could not cache result: {}\n", .{err});
            };
        }

        json_response = try std.fmt.allocPrint(allocator, "{{ \"sequence\": {s} }}", .{json_array.items});
    }

    defer allocator.free(json_response);

    r.setStatus(.ok);
    r.sendBody(json_response) catch {};
}
