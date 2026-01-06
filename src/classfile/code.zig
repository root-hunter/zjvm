const std = @import("std");
const types = @import("types.zig");
const Cursor = @import("utils.zig").Cursor;
const AttributesInfo = @import("attributes.zig").AttributesInfo;
const p = @import("parser.zig");

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
            cursor,
            @intCast(attributes_count),
            allocator,
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
        const name = try class.getConstant(attr.attribute_name_index);

        if (std.mem.eql(u8, name, "Code")) {
            var cursor = Cursor.init(attr.info);
            return try CodeAttribute.parse(allocator, &cursor);
        }

        return null;
    }

    pub fn dump(self: *const CodeAttribute) void {
        const code_len: usize = @intCast(self.code.len);

        std.debug.print("    Max Stack: {}\n", .{self.max_stack});
        std.debug.print("    Max Locals: {}\n", .{self.max_locals});
        std.debug.print("    Code Length: {}\n", .{code_len});
        std.debug.print("    Exception Table Length: {}\n", .{self.exception_table.len});
        std.debug.print("    Attributes Count: {}\n", .{self.attributes.len});
    }
};
