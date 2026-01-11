const std = @import("std");
const testing = std.testing;
const OperandStack = @import("operand_stack.zig").OperandStack;
const Value = @import("value.zig").Value;

test "OperandStack - init and basic properties" {
    const allocator = testing.allocator;
    const stack = try OperandStack.init(&allocator, 10);
    defer allocator.free(stack.data);

    try testing.expectEqual(@as(usize, 0), stack.top);
    try testing.expectEqual(@as(usize, 10), stack.size);
    try testing.expectEqual(@as(usize, 10), stack.data.len);
}

test "OperandStack - push and pop single value" {
    const allocator = testing.allocator;
    var stack = try OperandStack.init(&allocator, 5);
    defer allocator.free(stack.data);

    const v = Value{ .Int = 42 };
    try stack.push(v);

    try testing.expectEqual(@as(usize, 1), stack.top);

    const popped = try stack.pop();
    try testing.expectEqual(@as(i32, 42), popped.Int);
    try testing.expectEqual(@as(usize, 0), stack.top);
}

test "OperandStack - push and pop multiple values" {
    const allocator = testing.allocator;
    var stack = try OperandStack.init(&allocator, 5);
    defer allocator.free(stack.data);

    try stack.push(Value{ .Int = 10 });
    try stack.push(Value{ .Int = 20 });
    try stack.push(Value{ .Int = 30 });

    try testing.expectEqual(@as(usize, 3), stack.top);

    // Pop in reverse order (LIFO)
    const v3 = try stack.pop();
    try testing.expectEqual(@as(i32, 30), v3.Int);

    const v2 = try stack.pop();
    try testing.expectEqual(@as(i32, 20), v2.Int);

    const v1 = try stack.pop();
    try testing.expectEqual(@as(i32, 10), v1.Int);

    try testing.expectEqual(@as(usize, 0), stack.top);
}

test "OperandStack - overflow error" {
    const allocator = testing.allocator;
    var stack = try OperandStack.init(&allocator, 2);
    defer allocator.free(stack.data);

    try stack.push(Value{ .Int = 1 });
    try stack.push(Value{ .Int = 2 });

    // This should fail with StackOverflow
    try testing.expectError(error.StackOverflow, stack.push(Value{ .Int = 3 }));
}

test "OperandStack - underflow error" {
    const allocator = testing.allocator;
    var stack = try OperandStack.init(&allocator, 5);
    defer allocator.free(stack.data);

    // Pop from empty stack should fail
    try testing.expectError(error.StackUnderflow, stack.pop());
}

test "OperandStack - mixed value types" {
    const allocator = testing.allocator;
    var stack = try OperandStack.init(&allocator, 5);
    defer allocator.free(stack.data);

    try stack.push(Value{ .Int = 42 });
    try stack.push(Value{ .Float = 3.14 });
    try stack.push(Value{ .Long = 1000 });

    const v3 = try stack.pop();
    try testing.expectEqual(@as(i64, 1000), v3.Long);

    const v2 = try stack.pop();
    try testing.expectEqual(@as(f32, 3.14), v2.Float);

    const v1 = try stack.pop();
    try testing.expectEqual(@as(i32, 42), v1.Int);
}

test "OperandStack - fill to capacity" {
    const allocator = testing.allocator;
    const capacity = 10;
    var stack = try OperandStack.init(&allocator, capacity);
    defer allocator.free(stack.data);

    // Fill the stack completely
    var i: i32 = 0;
    while (i < capacity) : (i += 1) {
        try stack.push(Value{ .Int = i });
    }

    try testing.expectEqual(@as(usize, capacity), stack.top);

    // Should not be able to push more
    try testing.expectError(error.StackOverflow, stack.push(Value{ .Int = 999 }));
}
