const std = @import("std");

pub fn bitonicArray(allocator: std.mem.Allocator, n: usize, l: i32, r: i32) ![]i32 {
    const max_possible = (r - l) * 2 + 1;
    var deque = try std.ArrayList(i32).initCapacity(allocator, n);
    defer deque.deinit(allocator);

    if (n > max_possible) {
        return error.InvalidInput;
    }

    try deque.append(allocator, r - 1);

    var i = r;
    while (i >= l and deque.items.len < n) : (i -= 1) {
        try deque.append(allocator, i);
    }

    i = r - 2;
    while (i >= l and deque.items.len < n) : (i -= 1) {
        try deque.insert(allocator, 0, i);
    }

    return deque.toOwnedSlice(allocator);
}
