const std = @import("std");
const testing = std.testing;
const bitonic = @import("bitonic.zig");

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

    std.debug.print("\n=== Running bitonic test ===\n", .{});

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

    std.debug.print("\n=== Running bitonic test ===\n", .{});

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
