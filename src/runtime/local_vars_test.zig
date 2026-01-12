const std = @import("std");
const testing = std.testing;
const LocalVars = @import("local_vars.zig").LocalVars;
const Value = @import("value.zig").Value;

test "LocalVars - init with default values" {
    const allocator = testing.allocator;
    const locals = try LocalVars.init(&allocator, 5);
    defer allocator.free(locals.vars);

    try testing.expectEqual(@as(usize, 5), locals.vars.len);

    // All should be initialized to Top
    for (locals.vars) |v| {
        try testing.expectEqual(@as(void, {}), v.Top);
    }
}

test "LocalVars - set and get" {
    const allocator = testing.allocator;
    var locals = try LocalVars.init(&allocator, 5);
    defer allocator.free(locals.vars);

    locals.set(0, Value{ .Int = 100 });
    locals.set(2, Value{ .Float = 3.14 });
    locals.set(4, Value{ .Long = 999 });

    const v0 = locals.get(0);
    try testing.expectEqual(@as(i32, 100), v0.Int);

    const v2 = locals.get(2);
    try testing.expectEqual(@as(f32, 3.14), v2.Float);

    const v4 = locals.get(4);
    try testing.expectEqual(@as(i64, 999), v4.Long);

    // Index 1 and 3 should still be default (0)
    const v1 = locals.get(1);
    try testing.expectEqual(@as(void, {}), v1.Top);
}

test "LocalVars - overwrite values" {
    const allocator = testing.allocator;
    var locals = try LocalVars.init(&allocator, 3);
    defer allocator.free(locals.vars);

    locals.set(0, Value{ .Int = 10 });
    locals.set(0, Value{ .Int = 20 });
    locals.set(0, Value{ .Int = 30 });

    const v = locals.get(0);
    try testing.expectEqual(@as(i32, 30), v.Int);
}

test "LocalVars - boundary indices" {
    const allocator = testing.allocator;
    var locals = try LocalVars.init(&allocator, 10);
    defer allocator.free(locals.vars);

    // Test first and last index
    locals.set(0, Value{ .Int = 111 });
    locals.set(9, Value{ .Int = 999 });

    try testing.expectEqual(@as(i32, 111), locals.get(0).Int);
    try testing.expectEqual(@as(i32, 999), locals.get(9).Int);
}

test "LocalVars - mixed types" {
    const allocator = testing.allocator;
    var locals = try LocalVars.init(&allocator, 6);
    defer allocator.free(locals.vars);

    locals.set(0, Value{ .Int = 42 });
    locals.set(1, Value{ .Float = 1.5 });
    locals.set(2, Value{ .Long = 123456789 });
    locals.set(3, Value{ .Double = 2.718 });
    locals.set(4, Value{ .Reference = 0xABCD });

    try testing.expectEqual(@as(i32, 42), locals.get(0).Int);
    try testing.expectEqual(@as(f32, 1.5), locals.get(1).Float);
    try testing.expectEqual(@as(i64, 123456789), locals.get(2).Long);
    try testing.expectEqual(@as(f64, 2.718), locals.get(3).Double);
    try testing.expectEqual(@as(usize, 0xABCD), locals.get(4).Reference);
}
