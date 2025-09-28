const std = @import("std");
const zap = @import("zap");
const bitonic = @import("bitonic.zig");

pub fn main() !void {
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

    const result = bitonic.bitonicArray(allocator, @intCast(length.integer), @intCast(start.integer), @intCast(end.integer)) catch {
        r.setStatus(.bad_request);
        const error_msg = std.fmt.allocPrint(allocator, "{{ \"error\": \"It's not possible to generate sequence of length {} in range [{}, {}]\" }}", .{ length.integer, start.integer, end.integer }) catch "{ \"error\": \"Invalid input\" }";
        r.sendBody(error_msg) catch {};
        return;
    };

    // Format the array as JSON
    var json_array = try std.ArrayList(u8).initCapacity(allocator, 256);
    defer json_array.deinit(allocator);

    try json_array.appendSlice(allocator, "[");
    for (result, 0..) |val, i| {
        if (i > 0) try json_array.appendSlice(allocator, ",");
        const val_str = try std.fmt.allocPrint(allocator, "{}", .{val});
        try json_array.appendSlice(allocator, val_str);
    }
    try json_array.appendSlice(allocator, "]");

    const json_response = try std.fmt.allocPrint(allocator, "{{ \"sequence\": {s} }}", .{json_array.items});

    r.setStatus(.ok);
    r.sendBody(json_response) catch {};
}
