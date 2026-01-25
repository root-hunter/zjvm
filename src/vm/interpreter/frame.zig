const std = @import("std");
const OperandStack = @import("operand_stack.zig").OperandStack;
const OperandStackJSON = @import("operand_stack.zig").OperandStackJSON;
const LocalVars = @import("local_vars.zig").LocalVars;
const LocalVarsJSON = @import("local_vars.zig").LocalVarsJSON;
const v = @import("value.zig");
const ca = @import("../class//code.zig");
const p = @import("../class/parser.zig");
const OpcodeEnum = @import("../interpreter/opcode.zig").OpcodeEnum;

pub const FrameJSON = struct {
    operand_stack: OperandStackJSON,
    local_vars: LocalVarsJSON,
    pc: usize,
    code_length: usize,

    // ZJVM adds
    class: p.ClassInfoJSON,

    pub fn init(frame: Frame) !FrameJSON {
        return FrameJSON{
            .operand_stack = try frame.operand_stack.toJSON(),
            .local_vars = try frame.local_vars.toJSON(),
            .pc = frame.pc,
            .code_length = frame.getCodeLength(),
            .class = try frame.class.toJSON(),
        };
    }
};

pub const Frame = struct {
    operand_stack: OperandStack,
    local_vars: LocalVars,
    codeAttr: ?ca.CodeAttribute,
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
            .codeAttr = codeAttr,
            .pc = 0,
            .class = class,
        };
    }

    pub fn initStdFunctionFrame(
        allocator: *const std.mem.Allocator,
        std_function: ca.StdFunction,
        num_locals: usize,
        class: *const p.ClassInfo,
    ) !Frame {
        return Frame{
            .operand_stack = try OperandStack.init(allocator, 10), // Arbitrary stack size for std functions
            .local_vars = try LocalVars.init(allocator, num_locals),
            .codeAttr = null,
            .pc = 0,
            .std_function = std_function,
            .class = class,
        };
    }

    pub fn getCodeLength(self: *const Frame) usize {
        return self.codeAttr.?.getCodeLength();
    }

    pub fn getCodeByte(self: *const Frame, index: usize) u8 {
        return self.codeAttr.?.getByte(index);
    }

    pub fn pushOperand(self: *Frame, value: v.Value) !void {
        try self.operand_stack.push(value);
    }

    pub fn popOperand(self: *Frame) !v.Value {
        return try self.operand_stack.pop();
    }

    pub fn push2Operand(self: *Frame, value: v.Value) !void {
        try self.operand_stack.push2Value(value);
    }

    pub fn pop2Operand(self: *Frame) !v.Value {
        return try self.operand_stack.pop2Value();
    }

    pub fn pushLocalVarToStackVar(self: *Frame, index: usize) !void {
        const value = self.local_vars.vars[index];

        switch (value) {
            .Double => {
                try self.push2Operand(value);
            },
            .Long => {
                try self.push2Operand(value);
            },
            else => {
                try self.pushOperand(value);
            },
        }
    }

    pub fn popStackVarToLocalVar(self: *Frame, opcode: OpcodeEnum, index: usize) !void {
        // TODO Add LSTORE
        if (opcode == OpcodeEnum.DStore or opcode == OpcodeEnum.DStore1 or opcode == OpcodeEnum.DStore3 or opcode == OpcodeEnum.LStore or opcode == OpcodeEnum.LStore1 or opcode == OpcodeEnum.LStore3) {
            const value = try self.pop2Operand();
            self.local_vars.vars[index] = value;
            self.local_vars.vars[index + 1] = v.Value.Top;
        } else {
            const value = try self.popOperand();
            self.local_vars.vars[index] = value;
        }
    }

    /// Dump function to print all local variables in the frame
    pub fn dump(self: *const Frame) void {
        std.debug.print("\n=== Frame Dump ===\n", .{});
        std.debug.print("PC: {d}\n", .{self.pc});
        std.debug.print("Code Length: {d}\n", .{self.getCodeLength()});
        std.debug.print("\nLocal Variables ({d}):\n", .{self.local_vars.vars.len});

        for (self.local_vars.vars, 0..) |val, i| {
            std.debug.print("  [{}] = ", .{i});
            switch (val) {
                v.ValueTag.Top => std.debug.print("<reserved>\n", .{}),
                v.ValueTag.Int => std.debug.print("{d} (Int)\n", .{val.Int}),
                v.ValueTag.Float => std.debug.print("{d} (Float)\n", .{val.Float}),
                v.ValueTag.Long => std.debug.print("{d} (Long)\n", .{val.Long}),
                v.ValueTag.Double => std.debug.print("{d} (Double)\n", .{val.Double}),
                v.ValueTag.Reference => std.debug.print("{any} (Reference)\n", .{val.Reference}),
                v.ValueTag.ArrayRef => std.debug.print("{any} (ArrayRef)\n", .{val.ArrayRef}),
            }
        }

        std.debug.print("\nOperand Stack:\n", .{});
        std.debug.print("  Size: {d}/{d}\n", .{ self.operand_stack.top, self.operand_stack.data.len });
        std.debug.print("==================\n\n", .{});
    }

    pub fn toJSON(self: Frame) !FrameJSON {
        return try FrameJSON.init(self);
    }
};
