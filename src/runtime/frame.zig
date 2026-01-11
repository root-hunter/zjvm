const std = @import("std");
const OperandStack = @import("operand_stack.zig").OperandStack;
const LocalVars = @import("local_vars.zig").LocalVars;
const Value = @import("value.zig").Value;
const ValueTag = @import("value.zig").ValueTag;
const ca = @import("../classfile/code.zig");

pub const Frame = struct {
    operand_stack: OperandStack,
    local_vars: LocalVars,
    code: []const u8,
    pc: usize,
    size: usize,

    pub fn init(
        allocator: *const std.mem.Allocator,
        codeAttr: ca.CodeAttribute,
    ) !Frame {
        return Frame{
            .operand_stack = try OperandStack.init(allocator, codeAttr.max_stack),
            .local_vars = try LocalVars.init(allocator, codeAttr.max_locals),
            .code = codeAttr.code,
            .pc = 0,
            .size = codeAttr.max_locals,
        };
    }

    /// Dump function to print all local variables in the frame
    pub fn dump(self: *const Frame) void {
        std.debug.print("\n=== Frame Dump ===\n", .{});
        std.debug.print("PC: {d}\n", .{self.pc});
        std.debug.print("Code Length: {d}\n", .{self.code.len});
        std.debug.print("\nLocal Variables ({d}):\n", .{self.local_vars.vars.len});

        for (self.local_vars.vars, 0..) |v, i| {
            std.debug.print("  [{}] = ", .{i});
            switch (v) {
                ValueTag.Int => std.debug.print("{d} (Int)\n", .{v.Int}),
                ValueTag.Float => std.debug.print("{d} (Float)\n", .{v.Float}),
                ValueTag.Long => std.debug.print("{d} (Long)\n", .{v.Long}),
                ValueTag.Double => std.debug.print("{d} (Double)\n", .{v.Double}),
                ValueTag.Reference => std.debug.print("0x{x} (Reference)\n", .{v.Reference}),
                ValueTag.ArrayRef => std.debug.print("{any} (ArrayRef)\n", .{v.ArrayRef}),
            }
        }

        std.debug.print("\nOperand Stack:\n", .{});
        std.debug.print("  Size: {d}/{d}\n", .{ self.operand_stack.top, self.operand_stack.data.len });
        std.debug.print("==================\n\n", .{});
    }
};
