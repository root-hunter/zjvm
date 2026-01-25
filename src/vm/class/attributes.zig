const std = @import("std");
const types = @import("../types.zig");
const cp = @import("constant_pool.zig");
const utils = @import("../../utils.zig");
const CodeAttribute = @import("code.zig").CodeAttribute;
const p = @import("parser.zig");

pub const AttributesInfoJSON = struct {
    attribute_name_index: types.U2,
    attribute_length: types.U4,
    info: []const u8,

    name: []const u8,

    pub fn init(attr: AttributesInfo) AttributesInfoJSON {
        return AttributesInfoJSON{
            .attribute_name_index = attr.attribute_name_index,
            .attribute_length = attr.attribute_length,
            .info = attr.info,
            .name = attr.name,
        };
    }
};

pub const AttributesInfo = struct {
    attribute_name_index: types.U2,
    attribute_length: types.U4,
    info: []const u8,

    name: []const u8,

    pub fn parse(cursor: *utils.Cursor, class: *const p.ClassInfo) !AttributesInfo {
        const attributeNameIndex = try cursor.readU2();
        const attributeLength = try cursor.readU4();
        const info = try cursor.readBytes(@intCast(attributeLength));

        const name = try class.getConstantUtf8(attributeNameIndex);

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

    pub fn isBootstrapMethods(self: *const AttributesInfo) bool {
        return std.mem.eql(u8, self.name, "BootstrapMethods");
    }

    pub fn getBootstrapMethods(self: *const AttributesInfo, class: *const p.ClassInfo) ![]cp.InvokeDynamicRefInfo {
        if (!self.isBootstrapMethods()) {
            return error.NotABootstrapMethodsAttribute;
        }

        var cursor = utils.Cursor.init(self.info);

        const num_bootstrap_methods = try cursor.readU2();
        var bootstrap_methods = try class.allocator.alloc(cp.InvokeDynamicRefInfo, @intCast(num_bootstrap_methods));

        var i: usize = 0;
        const max: usize = @intCast(num_bootstrap_methods);
        while (i < max) : (i += 1) {
            const bootstrap_method_attr_index = try cursor.readU2();
            const num_args = try cursor.readU2();
            var args: ?[]u16 = null;
            if (num_args > 0) {
                args = try class.allocator.alloc(u16, @intCast(num_args));
                var j: usize = 0;
                const max_args: usize = @intCast(num_args);
                while (j < max_args) : (j += 1) {
                    args.?[j] = try cursor.readU2();
                }
            }

            bootstrap_methods[i] = cp.InvokeDynamicRefInfo{
                .bootstrap_method_attr_index = bootstrap_method_attr_index,
                .name_and_type_index = 0, // Questo poi lo imposti in base all'indice InvokeDynamic nella CP
                .bootstrap_args = args,
            };
        }

        return bootstrap_methods;
    }

    pub fn toJSON(self: *const AttributesInfo) AttributesInfoJSON {
        return AttributesInfoJSON.init(self.*);
    }
};
