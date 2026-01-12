const std = @import("std");
const OperandStack = @import("operand_stack.zig").OperandStack;
const LocalVars = @import("local_vars.zig").LocalVars;
const v = @import("value.zig");
const ca = @import("../classfile/code.zig");
const p = @import("../classfile/parser.zig");

pub const Frame = struct {
    operand_stack: OperandStack,
    local_vars: LocalVars,
    code: []const u8,
    pc: usize,

    // ZJVM adds
    class: *const p.ClassInfo,

    pub fn init(
        allocator: *const std.mem.Allocator,
        codeAttr: ca.CodeAttribute,
        class: *const p.ClassInfo,
    ) !Frame {
        return Frame{
            .operand_stack = try OperandStack.init(allocator, codeAttr.max_stack),
            .local_vars = try LocalVars.init(allocator, codeAttr.max_locals),
            .code = codeAttr.code,
            .pc = 0,
            .class = class,
        };
    }

    /// Dump function to print all local variables in the frame
    pub fn dump(self: *const Frame) void {
        std.debug.print("\n=== Frame Dump ===\n", .{});
        std.debug.print("PC: {d}\n", .{self.pc});
        std.debug.print("Code Length: {d}\n", .{self.code.len});
        std.debug.print("\nLocal Variables ({d}):\n", .{self.local_vars.vars.len});

        for (self.local_vars.vars, 0..) |val, i| {
            std.debug.print("  [{}] = ", .{i});
            switch (val) {
                v.ValueTag.Top => std.debug.print("<reserved>\n", .{}),
                v.ValueTag.Int => std.debug.print("{d} (Int)\n", .{val.Int}),
                v.ValueTag.Float => std.debug.print("{d} (Float)\n", .{val.Float}),
                v.ValueTag.Long => std.debug.print("{d} (Long)\n", .{val.Long}),
                v.ValueTag.Double => std.debug.print("{d} (Double)\n", .{val.Double}),
                v.ValueTag.Reference => std.debug.print("0x{x} (Reference)\n", .{val.Reference}),
                v.ValueTag.ArrayRef => std.debug.print("{any} (ArrayRef)\n", .{val.ArrayRef}),
            }
        }

        std.debug.print("\nOperand Stack:\n", .{});
        std.debug.print("  Size: {d}/{d}\n", .{ self.operand_stack.top, self.operand_stack.data.len });
        std.debug.print("==================\n\n", .{});
    }
};
