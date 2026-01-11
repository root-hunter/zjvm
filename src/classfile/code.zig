const std = @import("std");
const types = @import("types.zig");
const Cursor = @import("utils.zig").Cursor;
const AttributesInfo = @import("attributes.zig").AttributesInfo;
const p = @import("parser.zig");
const o = @import("../engine/opcode.zig");

pub const ExceptionTableEntry = struct {
    start_pc: types.U2,
    end_pc: types.U2,
    handler_pc: types.U2,
    catch_type: types.U2,
};

pub const CodeAttribute = struct {
    max_stack: types.U2,
    max_locals: types.U2,
    code: []const u8,

    exception_table: []ExceptionTableEntry,
    attributes: []AttributesInfo,

    pub fn parse(
        allocator: *const std.mem.Allocator,
        cursor: *Cursor,
        class: *const p.ClassInfo,
    ) !CodeAttribute {
        const max_stack = try cursor.readU2();
        const max_locals = try cursor.readU2();

        const code_length = try cursor.readU4();
        const code = try cursor.readBytes(@intCast(code_length));

        const exception_table_length = try cursor.readU2();
        const exceptions = try allocator.alloc(
            ExceptionTableEntry,
            @intCast(exception_table_length),
        );

        for (exceptions) |*e| {
            e.* = .{
                .start_pc = try cursor.readU2(),
                .end_pc = try cursor.readU2(),
                .handler_pc = try cursor.readU2(),
                .catch_type = try cursor.readU2(),
            };
        }

        const attributes_count = try cursor.readU2();
        const attrs = try AttributesInfo.parseAll(
            allocator,
            cursor,
            @intCast(attributes_count),
            class,
        );

        return CodeAttribute{
            .max_stack = max_stack,
            .max_locals = max_locals,
            .code = code,
            .exception_table = exceptions,
            .attributes = attrs,
        };
    }

    pub fn parseCodeIfPresent(
        attr: AttributesInfo,
        class: *const p.ClassInfo,
        allocator: *const std.mem.Allocator,
    ) !?CodeAttribute {
        if (std.mem.eql(u8, attr.name, "Code")) {
            var cursor = Cursor.init(attr.info);
            return try CodeAttribute.parse(allocator, &cursor, class);
        }

        return null;
    }

    pub fn dump(self: *const CodeAttribute) void {
        const code_len: usize = @intCast(self.code.len);

        std.debug.print("    Code Attribute:\n", .{});
        std.debug.print("      Max Stack: {}\n", .{self.max_stack});
        std.debug.print("      Max Locals: {}\n", .{self.max_locals});
        std.debug.print("      Code Length: {}\n", .{code_len});
        std.debug.print("      Exception Table Length: {}\n", .{self.exception_table.len});
        std.debug.print("      Attributes Count: {}\n", .{self.attributes.len});
    }

    pub fn dumpOpcodes(self: *const CodeAttribute) !void {
        std.debug.print("    Raw Opcodes: {any}\n", .{self.code});
        std.debug.print("      Opcodes:\n", .{});

        var pc: usize = 0;
        while (pc < self.code.len) {
            const byte = self.code[pc];

            const result = std.meta.intToEnum(o.OpcodeEnum, byte);

            if (result == error.InvalidEnumTag) {
                std.debug.print("        {d}: <unknown 0x{x}>\n", .{ pc, byte });
                pc += 1;
                continue;
            }

            const maybe_opcode: ?o.OpcodeEnum = @enumFromInt(byte);

            if (maybe_opcode == null) {
                std.debug.print("        {d}: <unknown 0x{x}>\n", .{ pc, byte });
                pc += 1;
                continue;
            }

            const opcode = maybe_opcode.?;
            const operand_len = opcode.getOperandLength();
            const operand_fmt = opcode.getOperandFormat();

            // Stampa base
            std.debug.print("        {d}: {s}", .{ pc, opcode.toString() });

            // Stampa operandi se presenti
            switch (operand_fmt) {
                .Byte => {
                    const value = @as(i8, @bitCast(self.code[pc + 1]));
                    std.debug.print(" {d}", .{value});
                },
                .Short => {
                    const hi = self.code[pc + 1];
                    const lo = self.code[pc + 2];
                    const value = @as(i16, @bitCast((@as(u16, hi) << 8) | lo));
                    std.debug.print(" {d}", .{value});
                },
                .Int => {
                    const b0 = self.code[pc + 1];
                    const b1 = self.code[pc + 2];
                    const b2 = self.code[pc + 3];
                    const b3 = self.code[pc + 4];
                    const value = @as(i32, @bitCast((@as(u32, b0) << 24) | (@as(u32, b1) << 16) | (@as(u32, b2) << 8) | b3));
                    std.debug.print(" {d}", .{value});
                },
                .BranchOffset => {
                    // offset a 2 byte
                    const hi = self.code[pc + 1];
                    const lo = self.code[pc + 2];
                    const offset = @as(i16, @bitCast((@as(u16, hi) << 8) | lo));
                    std.debug.print(" {d}", .{offset});
                },
                .NoOperand => {},
            }

            std.debug.print("\n", .{});

            pc += operand_len;
        }
    }

    pub fn deinit(self: *CodeAttribute, allocator: *const std.mem.Allocator) void {
        allocator.free(self.exception_table);
        allocator.free(self.attributes);
    }
};
