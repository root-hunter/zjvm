const std = @import("std");
const testing = std.testing;
const v = @import("value.zig");

test "Value - Int creation and access" {
    const val = v.Value{ .Int = 42 };
    try testing.expectEqual(@as(i32, 42), val.Int);
}

test "Value - Float creation and access" {
    const val = v.Value{ .Float = 3.14 };
    try testing.expectEqual(@as(f32, 3.14), val.Float);
}

test "Value - Long creation and access" {
    const val = v.Value{ .Long = 9223372036854775807 };
    try testing.expectEqual(@as(i64, 9223372036854775807), val.Long);
}

test "Value - Double creation and access" {
    const val = v.Value{ .Double = 2.718281828 };
    try testing.expectEqual(@as(f64, 2.718281828), val.Double);
}

test "Value - Reference creation and access" {
    const val = v.Value{ .Reference = 0x1234 };
    try testing.expectEqual(@as(usize, 0x1234), val.Reference);
}

test "Value - negative Int" {
    const val = v.Value{ .Int = -100 };
    try testing.expectEqual(@as(i32, -100), val.Int);
}

test "Value - zero values" {
    const v1 = v.Value{ .Int = 0 };
    const v2 = v.Value{ .Float = 0.0 };
    const v3 = v.Value{ .Long = 0 };
    const v4 = v.Value{ .Double = 0.0 };

    try testing.expectEqual(@as(i32, 0), v1.Int);
    try testing.expectEqual(@as(f32, 0.0), v2.Float);
    try testing.expectEqual(@as(i64, 0), v3.Long);
    try testing.expectEqual(@as(f64, 0.0), v4.Double);
}
