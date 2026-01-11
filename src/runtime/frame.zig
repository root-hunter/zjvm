const std = @import("std");
const OperandStack = @import("operand_stack.zig").OperandStack;
const LocalVars = @import("local_vars.zig").LocalVars;
const ca = @import("../classfile/code.zig");

pub const Frame = struct {
    operand_stack: OperandStack,
    local_vars: LocalVars,
    code: []const u8,
    pc: usize,

    pub fn init(
        allocator: *const std.mem.Allocator,
        codeAttr: ca.CodeAttribute,
    ) !Frame {
        return Frame{
            .operand_stack = try OperandStack.init(allocator, codeAttr.max_stack),
            .local_vars = try LocalVars.init(allocator, codeAttr.max_locals),
            .code = codeAttr.code,
            .pc = 0,
        };
    }
};
