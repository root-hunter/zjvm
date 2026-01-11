const std = @import("std");
const types = @import("types.zig");
const utils = @import("utils.zig");
const a = @import("attributes.zig");
const ca = @import("code.zig");
const p = @import("parser.zig");

pub const MethodInfo = struct {
    allocator: *const std.mem.Allocator,

    access_flags: types.U2,
    name_index: types.U2,
    descriptor_index: types.U2,
    attributes_count: types.U2,
    attributes: ?[]a.AttributesInfo,

    code: ?ca.CodeAttribute,

    // ZJVM additions
    name: []const u8,
    descriptor: []const u8,
    num_params: usize,

    pub fn parse(allocator: *const std.mem.Allocator, class: *const p.ClassInfo, cursor: *utils.Cursor) !MethodInfo {
        var self = MethodInfo{
            .allocator = allocator,
            .access_flags = 0,
            .name_index = 0,
            .descriptor_index = 0,
            .attributes_count = 0,
            .attributes = null,
            .code = null,
            .name = &[_]u8{},
            .descriptor = &[_]u8{},
            .num_params = 0,
        };

        self.access_flags = try cursor.readU2();
        self.name_index = try cursor.readU2();
        self.descriptor_index = try cursor.readU2();
        self.attributes_count = try cursor.readU2();

        self.name = try class.getConstant(self.name_index);
        self.descriptor = try class.getConstant(self.descriptor_index);

        const count: usize = @intCast(self.attributes_count);
        self.attributes = try a.AttributesInfo.parseAll(self.allocator, cursor, count, class);

        self.num_params = try utils.countMethodParameters(self.descriptor);
        self.code = try self.parseCodeAttribute(class);

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
        std.debug.print("  Method: {s}\n", .{self.name});
        std.debug.print("    Descriptor: {s}\n", .{self.descriptor});
        std.debug.print("    Descriptor Index: {}\n", .{self.descriptor_index});
        std.debug.print("    Name Index: {}\n", .{self.name_index});
        std.debug.print("    Access Flags: 0x{X:0>4}\n", .{self.access_flags});

        if (self.code) |code| {
            code.dump();
        } else {
            std.debug.print("  No code attribute\n", .{});
        }
    }

    pub fn deinit(self: *MethodInfo) void {
        if (self.attributes) |attributes| {
            self.allocator.free(attributes);
            self.attributes = null;
        }

        if (self.code) |code| {
            code.deinit();
            self.code = null;
        }
    }
};
