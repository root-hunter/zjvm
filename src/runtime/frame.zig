const std = @import("std");
const OperandStack = @import("operand_stack.zig").OperandStack;
const LocalVars = @import("local_vars.zig").LocalVars;

pub const Frame = struct {
    operand_stack: OperandStack,
    local_vars: LocalVars,
    code: []const u8,
    pc: usize,

    pub fn init(
        allocator: *std.mem.Allocator,
        max_stack: usize,
        max_locals: usize,
        code: []const u8,
    ) !Frame {
        return Frame{
            .operand_stack = try OperandStack.init(allocator, max_stack),
            .local_vars = try LocalVars.init(allocator, max_locals),
            .code = code,
            .pc = 0,
        };
    }
};