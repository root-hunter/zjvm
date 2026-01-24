const std = @import("std");
const Value = @import("value.zig").Value;
const ValueJSON = @import("value.zig").ValueJSON;

pub const OperandStackJSON = struct {
    data: []ValueJSON,
    top: usize,
    size: usize,

    pub fn toJSON(stack: OperandStack) !OperandStackJSON {
        const allocator = std.heap.page_allocator;
        var data_json = try std.ArrayList(ValueJSON).initCapacity(allocator, stack.data.len);
        defer data_json.deinit(allocator);

        for (stack.data) |v| {
            try data_json.append(allocator, try v.toJSON());
        }

        return OperandStackJSON{
            .data = try data_json.toOwnedSlice(allocator),
            .top = stack.top,
            .size = stack.size,
        };
    }
};

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

    pub fn pushFloat(self: *OperandStack, v: f32) !void {
        if (self.top >= self.data.len)
            return error.StackOverflow;

        self.data[self.top] = Value{ .Float = v };
        self.top += 1;
    }

    pub fn popFloat(self: *OperandStack) !f32 {
        if (self.top == 0)
            return error.StackUnderflow;

        self.top -= 1;

        const val = self.data[self.top];
        return switch (val) {
            .Float => |f| f,
            else => error.TypeMismatch,
        };
    }

    pub fn pushLong(self: *OperandStack, v: i64) !void {
        if (self.top + 1 >= self.data.len)
            return error.StackOverflow;

        self.data[self.top] = Value{ .Long = v };
        self.data[self.top + 1] = Value.Top;
        self.top += 2;
    }

    pub fn popLong(self: *OperandStack) !i64 {
        if (self.top == 0)
            return error.StackUnderflow;

        const top = self.data[self.top - 1];
        if (top != .Top) {
            std.debug.print("Expected Top value on operand stack but got {any}\n", .{top});
            return error.TypeMismatch;
        }

        self.top -= 2;

        const val = self.data[self.top];
        return switch (val) {
            .Long => |l| l,
            else => error.TypeMismatch,
        };
    }

    pub fn pushDouble(self: *OperandStack, v: f64) !void {
        if (self.top + 1 >= self.data.len)
            return error.StackOverflow;

        self.data[self.top] = Value{ .Double = v };
        self.data[self.top + 1] = Value.Top;
        self.top += 2;
    }

    pub fn popDouble(self: *OperandStack) !f64 {
        if (self.top == 0)
            return error.StackUnderflow;

        const top = self.data[self.top - 1];
        if (top != .Top) {
            std.debug.print("Expected Top value on operand stack but got {any}\n", .{top});
            return error.TypeMismatch;
        }

        self.top -= 2;

        const val = self.data[self.top];
        return switch (val) {
            .Double => |d| d,
            else => error.TypeMismatch,
        };
    }

    pub fn toJSON(self: OperandStack) !OperandStackJSON {
        return try OperandStackJSON.toJSON(self);
    }
};
