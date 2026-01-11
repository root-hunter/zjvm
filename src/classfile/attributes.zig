const std = @import("std");
const types = @import("types.zig");
const cp = @import("constant_pool.zig");
const utils = @import("utils.zig");
const CodeAttribute = @import("code.zig").CodeAttribute;
const p = @import("parser.zig");

pub const AttributesInfo = struct {
    attribute_name_index: types.U2,
    attribute_length: types.U4,
    info: []const u8,

    name: []const u8,

    pub fn parse(cursor: *utils.Cursor, class: *const p.ClassInfo) !AttributesInfo {
        const attributeNameIndex = try cursor.readU2();
        const attributeLength = try cursor.readU4();
        const info = try cursor.readBytes(@intCast(attributeLength));

        const name = try class.getConstant(attributeNameIndex);

        return AttributesInfo{
            .attribute_name_index = attributeNameIndex,
            .attribute_length = attributeLength,
            .info = info,
            .name = name,
        };
    }

    pub fn parseAll(allocator: *const std.mem.Allocator, cursor: *utils.Cursor, count: usize, class: *const p.ClassInfo) ![]AttributesInfo {
        var attributes = try allocator.alloc(AttributesInfo, count);

        var i: usize = 0;
        while (i < count) : (i += 1) {
            const attr = try AttributesInfo.parse(cursor, class);
            attributes[i] = attr;
        }

        return attributes;
    }
};
