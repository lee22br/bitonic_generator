const std = @import("std");
const testing = std.testing;
const bitonic = @import("bitonic.zig");
const MyRedisModule = @import("main.zig");
const okredis = @import("okredis");
const net = std.net;

var redis_client: ?okredis.Client = null;
var redis_rbuf: [1024]u8 = undefined;
var redis_wbuf: [1024]u8 = undefined;

test "bitonicArray specific case: length 7, start 2, end 5" {
    const allocator = testing.allocator;

    std.debug.print("\n=== Running bitonic test ===\n", .{});

    const result = try bitonic.bitonicArray(allocator, 7, 2, 5);
    defer allocator.free(result);

    std.debug.print("Generated sequence: ", .{});
    for (result) |val| {
        std.debug.print("{} ", .{val});
    }
    std.debug.print("\n", .{});

    const expected = [_]i32{ 2, 3, 4, 5, 4, 3, 2 };

    std.debug.print("Expected sequence:  ", .{});
    for (expected) |val| {
        std.debug.print("{} ", .{val});
    }
    std.debug.print("\n", .{});

    try testing.expect(result.len == expected.len);

    for (result, 0..) |val, i| {
        try testing.expect(val == expected[i]);
    }

    std.debug.print("Test PASSED!\n", .{});
}

test "bitonicArray exception case: length 2" {
    const allocator = testing.allocator;

    std.debug.print("\n=== Running bitonic test length <= 2 should throw exception ===\n", .{});

    _ = bitonic.bitonicArray(allocator, 2, 2, 5) catch |e| {
        try testing.expect(e == error.InvalidInput);
        std.debug.print("InvalidInput error for length 2. Test PASSED!\n", .{});
    };

    _ = bitonic.bitonicArray(allocator, 1, 2, 5) catch |e| {
        try testing.expect(e == error.InvalidInput);
        std.debug.print("InvalidInput error for length 1. Test PASSED!\n", .{});
    };

    _ = bitonic.bitonicArray(allocator, 0, 2, 5) catch |e| {
        try testing.expect(e == error.InvalidInput);
        std.debug.print("InvalidInput error for length 0. Test PASSED!\n", .{});
    };

    return;
}

test "bitonicArray exception case: length greater than possible" {
    const allocator = testing.allocator;

    std.debug.print("\n=== Running bitonic test length > possible should throw exception ===\n", .{});

    // length > (max - min) * 2 + 1
    _ = bitonic.bitonicArray(allocator, 10, 2, 5) catch |e| {
        try testing.expect(e == error.InvalidInput);
        std.debug.print("InvalidInput error for length 10 with range [2,5]. Test PASSED!\n", .{});
    };

    return;
}

test "bitonicArray specific case: length 29, start 1, end 15" {
    const allocator = testing.allocator;

    std.debug.print("\n=== Running bitonic test length 29 ===\n", .{});

    const result = try bitonic.bitonicArray(allocator, 29, 1, 15);
    defer allocator.free(result);

    std.debug.print("Generated sequence: ", .{});
    for (result) |val| {
        std.debug.print("{} ", .{val});
    }
    std.debug.print("\n", .{});

    const expected = [_]i32{ 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1 };

    std.debug.print("Expected sequence:  ", .{});
    for (expected) |val| {
        std.debug.print("{} ", .{val});
    }
    std.debug.print("\n", .{});

    try testing.expect(result.len == expected.len);

    for (result, 0..) |val, i| {
        try testing.expect(val == expected[i]);
    }

    std.debug.print("Test PASSED!\n", .{});
}

test "bitonicArray corner case: length 5, start 1, end 5" {
    const allocator = testing.allocator;

    std.debug.print("\n=== Running bitonic test length 5 ===\n", .{});

    const result = try bitonic.bitonicArray(allocator, 5, 0, 3);
    defer allocator.free(result);

    std.debug.print("Generated sequence: ", .{});
    for (result) |val| {
        std.debug.print("{} ", .{val});
    }
    std.debug.print("\n", .{});

    const expected = [_]i32{ 2,3,2,1,0 };

    std.debug.print("Expected sequence:  ", .{});
    for (expected) |val| {
        std.debug.print("{} ", .{val});
    }
    std.debug.print("\n", .{});

    try testing.expect(result.len == expected.len);

    for (result, 0..) |val, i| {
        try testing.expect(val == expected[i]);
    }

    std.debug.print("Test PASSED!\n", .{});
}

test "Redis client connection test" {
    std.debug.print("\n=== Running Redis test Connection ===\n", .{});

    redis_client = blk: {
        std.debug.print("Connecting to redis service...\n", .{});

        var address_list = std.net.getAddressList(std.heap.page_allocator, "localhost", 6379) catch |err| {
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
    try testing.expect(redis_client != null);
    std.debug.print("Test PASSED!\n", .{});
}

test "Redis client SET and GET test" {
    const allocator = std.heap.page_allocator;
    const cache_key = "Key";
    var response: []u8 = undefined;

    std.debug.print("\n=== Running Redis test SET and GET ===\n", .{});

    if (redis_client == null) {
        std.debug.print("Redis client is not initialized. Skipping test.\n", .{});
        return;
    }
    if (redis_client) |*client| {
        client.send(void, .{ "SET", cache_key, "Test1" }) catch |err| {
            std.debug.print("Warning: Could not cache result: {}\n", .{err});
        };
    }
    // Try to get from cache first
    if (redis_client) |*client| {
        if (client.sendAlloc([]u8, allocator, .{ "GET", cache_key })) |cached_sequence| {
            defer allocator.free(cached_sequence);
            std.debug.print("Cache HIT for key: {s}\n", .{cache_key});
            response = try allocator.dupe(u8, cached_sequence);
        } else |_| {
            std.debug.print("Cache MISS for key: {s}\n", .{cache_key});
        }
    }
    try testing.expect(std.mem.eql(u8,response,"Test1"));

    std.debug.print("Test PASSED!\n", .{});
}