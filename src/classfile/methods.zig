const std = @import("std");
const types = @import("types.zig");
const utils = @import("utils.zig");
const a = @import("attributes.zig");
const ca = @import("code.zig");
const p = @import("parser.zig");

pub const MethodInfo = struct {
    allocator: *const std.mem.Allocator,

    class: *const p.ClassInfo,

    access_flags: types.U2,
    name_index: types.U2,
    descriptor_index: types.U2,
    attributes_count: types.U2,
    attributes: ?[]a.AttributesInfo,

    code: ?ca.CodeAttribute,

    pub fn parse(allocator: *const std.mem.Allocator, class: *const p.ClassInfo, cursor: *utils.Cursor) !MethodInfo {
        var self = MethodInfo{
            .allocator = allocator,
            .access_flags = 0,
            .name_index = 0,
            .descriptor_index = 0,
            .attributes_count = 0,
            .class = class,
            .attributes = null,
            .code = null,
        };

        self.access_flags = try cursor.readU2();
        self.name_index = try cursor.readU2();
        self.descriptor_index = try cursor.readU2();
        self.attributes_count = try cursor.readU2();

        const count: usize = @intCast(self.attributes_count);
        self.attributes = try a.AttributesInfo.parseAll(cursor, count, self.allocator);

        self.code = try self.parseCodeAttribute(self.class);

        return self;
    }

    pub fn parseAll(class: *p.ClassInfo, cursor: *utils.Cursor, count: usize, allocator: *const std.mem.Allocator) ![]MethodInfo {
        var methods = try allocator.alloc(MethodInfo, count);

        var i: usize = 0;
        while (i < count) : (i += 1) {
            const method = try MethodInfo.parse(allocator, class, cursor);
            methods[i] = method;
        }

        return methods;
    }

    pub fn parseCodeAttribute(
        self: *MethodInfo,
        class: *const p.ClassInfo,
    ) !?ca.CodeAttribute {
        if (self.attributes) |attrs| {
            for (attrs) |attr| {
                const codeAttr = try ca.CodeAttribute.parseCodeIfPresent(attr, class, self.allocator);
                if (codeAttr) |code| {
                    return code;
                }
            }
        }
        return null;
    }

    pub fn dump(self: *const MethodInfo) !void {
        const name = try self.class.getConstant(self.name_index);
        const descriptor = try self.class.getConstant(self.descriptor_index);

        std.debug.print("Method: {s} {s}\n", .{name, descriptor});

        if (self.code) |code| {
            code.dump();
        } else {
            std.debug.print("  No code attribute\n", .{});
        }
    }
};