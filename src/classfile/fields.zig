const std = @import("std");
const types = @import("types.zig");
const utils = @import("utils.zig");
const a = @import("attributes.zig");
const p = @import("parser.zig");

pub const FieldInfoJSON = struct {
    access_flags: types.U2,
    name_index: types.U2,
    descriptor_index: types.U2,
    attributes_count: types.U2,
    attributes: ?[]a.AttributesInfo,

    pub fn init(field: FieldInfo) FieldInfoJSON {
        return FieldInfoJSON{
            .access_flags = field.access_flags,
            .name_index = field.name_index,
            .descriptor_index = field.descriptor_index,
            .attributes_count = field.attributes_count,
            .attributes = field.attributes,
        };
    }
};

pub const FieldInfo = struct {
    allocator: *const std.mem.Allocator,

    access_flags: types.U2,
    name_index: types.U2,
    descriptor_index: types.U2,
    attributes_count: types.U2,
    attributes: ?[]a.AttributesInfo,

    // ZJVM additions
    name: []const u8,
    descriptor: []const u8,

    pub fn parse(allocator: *const std.mem.Allocator, cursor: *utils.Cursor, class: *const p.ClassInfo) !FieldInfo {
        var self = FieldInfo{
            .allocator = allocator,
            .access_flags = 0,
            .name_index = 0,
            .descriptor_index = 0,
            .attributes_count = 0,
            .attributes = null,
            .name = &[_]u8{},
            .descriptor = &[_]u8{},
        };

        self.access_flags = try cursor.readU2();
        self.name_index = try cursor.readU2();
        self.descriptor_index = try cursor.readU2();
        self.attributes_count = try cursor.readU2();

        self.name = try class.getConstantUtf8(self.name_index);
        self.descriptor = try class.getConstantUtf8(self.descriptor_index);

        const count: usize = @intCast(self.attributes_count);
        self.attributes = try a.AttributesInfo.parseAll(self.allocator, cursor, count, class);

        return self;
    }

    pub fn parseAll(cursor: *utils.Cursor, count: usize, allocator: *const std.mem.Allocator, class: *const p.ClassInfo) ![]FieldInfo {
        var fields = try allocator.alloc(FieldInfo, count);

        var i: usize = 0;
        while (i < count) : (i += 1) {
            const field = try FieldInfo.parse(allocator, cursor, class);
            fields[i] = field;
        }

        return fields;
    }

    pub fn toJSON(self: *const FieldInfo) FieldInfoJSON {
        return FieldInfoJSON.init(self.*);
    }

    pub fn deinit(self: *FieldInfo) void {
        if (self.attributes) |attrs| {
            self.allocator.free(attrs);
        }
    }
};
