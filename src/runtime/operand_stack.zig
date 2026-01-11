const std = @import("std");
const Value = @import("value.zig").Value;

pub const OperandStack = struct {
    data: []Value,
    top: usize,
    size: usize,

    pub fn init(allocator: *const std.mem.Allocator, max: usize) !OperandStack {
        return OperandStack{
            .data = try allocator.alloc(Value, max),
            .top = 0,
            .size = max,
        };
    }

    pub fn push(self: *OperandStack, v: Value) !void {
        if (self.top >= self.data.len)
            return error.StackOverflow;
        self.data[self.top] = v;
        self.top += 1;
    }

    pub fn pop(self: *OperandStack) !Value {
        if (self.top == 0)
            return error.StackUnderflow;
        self.top -= 1;
        return self.data[self.top];
    }
};