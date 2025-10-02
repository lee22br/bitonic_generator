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
