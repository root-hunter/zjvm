const std = @import("std");
const types = @import("types.zig");
const cp = @import("constant_pool.zig");
const ac = @import("access_flags.zig");
const utils = @import("utils.zig");

pub const AttributesInfo = struct {
    attribute_name_index: types.U2,
    attribute_length: types.U4,
    info: []const u8,

    pub fn parse(cursor: *utils.Cursor) !AttributesInfo {
        const attributeNameIndex = try cursor.readU2();
        const attributeLength = try cursor.readU4();
        const info = try cursor.readBytes(@intCast(attributeLength));

        return AttributesInfo{
            .attribute_name_index = attributeNameIndex,
            .attribute_length = attributeLength,
            .info = info,
        };
    }

    pub fn parseAll(cursor: *utils.Cursor, count: usize, allocator: *const std.mem.Allocator) ![]AttributesInfo {
        var attributes = try allocator.alloc(AttributesInfo, count);

        var i: usize = 0;
        while (i < count) : (i += 1) {
            const attr = try AttributesInfo.parse(cursor);
            attributes[i] = attr;
        }

        return attributes;
    }
};

pub const FieldInfo = struct {
    allocator: *const std.mem.Allocator,

    access_flags: types.U2,
    name_index: types.U2,
    descriptor_index: types.U2,
    attributes_count: types.U2,
    attributes: ?[]AttributesInfo,

    pub fn parse(allocator: *const std.mem.Allocator, cursor: *utils.Cursor) !FieldInfo {
        var self = FieldInfo{
            .allocator = allocator,
            .access_flags = 0,
            .name_index = 0,
            .descriptor_index = 0,
            .attributes_count = 0,
            .attributes = null,
        };

        self.access_flags = try cursor.readU2();
        self.name_index = try cursor.readU2();
        self.descriptor_index = try cursor.readU2();
        self.attributes_count = try cursor.readU2();

        const count: usize = @intCast(self.attributes_count);
        self.attributes = try AttributesInfo.parseAll(cursor, count, self.allocator);

        return self;
    }

    pub fn parseAll(cursor: *utils.Cursor, count: usize, allocator: *const std.mem.Allocator) ![]FieldInfo {
        var fields = try allocator.alloc(FieldInfo, count);

        var i: usize = 0;
        while (i < count) : (i += 1) {
            const field = try FieldInfo.parse(allocator, cursor);
            fields[i] = field;
        }

        return fields;
    }
};

pub const MethodInfo = struct {
    allocator: *const std.mem.Allocator,

    access_flags: types.U2,
    name_index: types.U2,
    descriptor_index: types.U2,
    attributes_count: types.U2,
    attributes: ?[]AttributesInfo,

    pub fn parse(allocator: *const std.mem.Allocator, cursor: *utils.Cursor) !MethodInfo {
        var self = MethodInfo{
            .allocator = allocator,
            .access_flags = 0,
            .name_index = 0,
            .descriptor_index = 0,
            .attributes_count = 0,
            .attributes = null,
        };

        self.access_flags = try cursor.readU2();
        self.name_index = try cursor.readU2();
        self.descriptor_index = try cursor.readU2();
        self.attributes_count = try cursor.readU2();

        const count: usize = @intCast(self.attributes_count);
        self.attributes = try AttributesInfo.parseAll(cursor, count, self.allocator);

        return self;
    }

    pub fn parseAll(cursor: *utils.Cursor, count: usize, allocator: *const std.mem.Allocator) ![]MethodInfo {
        var methods = try allocator.alloc(MethodInfo, count);

        var i: usize = 0;
        while (i < count) : (i += 1) {
            const method = try MethodInfo.parse(allocator, cursor);
            methods[i] = method;
        }

        return methods;
    }
};

pub const ClassInfo = struct {
    allocator: *const std.mem.Allocator,

    magic: types.U4,
    minor_version: types.U2,
    major_version: types.U2,
    constant_pool_count: types.U2,
    constant_pool: ?[]cp.ConstantPoolInfo,

    access_flags: types.U2,

    this_class: types.U2,
    super_class: types.U2,

    interfaces_count: types.U2,
    interfaces: ?[]types.U2,

    fields_count: types.U2,
    fields: ?[]FieldInfo,

    methods_count: types.U2,
    methods: ?[]MethodInfo,

    attributes_count: types.U2,
    attributes: ?[]AttributesInfo,

    pub fn init(allocator: *const std.mem.Allocator) ClassInfo {
        return ClassInfo{
            .allocator = allocator,

            .magic = 0,
            .minor_version = 0,
            .major_version = 0,
            .constant_pool_count = 0,
            .constant_pool = null,
            .access_flags = 0,
            .this_class = 0,
            .super_class = 0,
            .interfaces_count = 0,
            .interfaces = null,
            .fields_count = 0,
            .fields = null,
            .methods_count = 0,
            .methods = null,
            .attributes_count = 0,
            .attributes = null,
        };
    }

    pub fn parse(self: *ClassInfo, cursor: *utils.Cursor) !void {
        try self.parseHeaders(cursor);
        try self.parseConstantPool(cursor);
        try self.parseAccessFlags(cursor);
        try self.parseClassMetadata(cursor);
        try self.parseInferfaces(cursor);
        try self.parseFields(cursor);
        try self.parseMethods(cursor);
        try self.parseAttributes(cursor);
    }

    pub fn parseHeaders(self: *ClassInfo, cursor: *utils.Cursor) !void {
        self.magic = try cursor.readU4();
        self.minor_version = try cursor.readU2();
        self.major_version = try cursor.readU2();
        self.constant_pool_count = try cursor.readU2();
    }

    pub fn parseConstantPool(self: *ClassInfo, cursor: *utils.Cursor) !void {
        const pool_size: usize = @intCast(self.constant_pool_count - 1);
        self.constant_pool = try self.allocator.alloc(cp.ConstantPoolInfo, pool_size);

        var i: usize = 0;
        while (i < pool_size) : (i += 1) {
            self.constant_pool.?[i] = try cp.ConstantPoolInfo.parse(cursor);
        }
    }

    pub fn parseAccessFlags(self: *ClassInfo, cursor: *utils.Cursor) !void {
        self.access_flags = try cursor.readU2();
    }

    pub fn parseClassMetadata(self: *ClassInfo, cursor: *utils.Cursor) !void {
        self.this_class = try cursor.readU2();
        self.super_class = try cursor.readU2();
    }

    pub fn parseInferfaces(self: *ClassInfo, cursor: *utils.Cursor) !void {
        self.interfaces_count = try cursor.readU2();
        const count: usize = @intCast(self.interfaces_count);
        self.interfaces = try self.allocator.alloc(types.U2, count);

        var i: usize = 0;
        while (i < count) : (i += 1) {
            self.interfaces.?[i] = try cursor.readU2();
        }
    }

    pub fn parseFields(self: *ClassInfo, cursor: *utils.Cursor) !void {
        self.fields_count = try cursor.readU2();
        const count: usize = @intCast(self.fields_count);
        self.fields = try FieldInfo.parseAll(cursor, count, self.allocator);
    }

    pub fn parseMethods(self: *ClassInfo, cursor: *utils.Cursor) !void {
        self.methods_count = try cursor.readU2();

        const count: usize = @intCast(self.methods_count);
        self.methods = try MethodInfo.parseAll(cursor, count, self.allocator);
    }

    pub fn parseAttributes(self: *ClassInfo, cursor: *utils.Cursor) !void {
        self.attributes_count = try cursor.readU2();
        const count: usize = @intCast(self.attributes_count);
        self.attributes = try AttributesInfo.parseAll(cursor, count, self.allocator);
    }

    pub fn isValidMagicNumber(self: *ClassInfo) bool {
        return self.magic == 0xCAFEBABE;
    }

    pub fn getFieldName(self: *ClassInfo, field: FieldInfo) ![]const u8 {
        const name_index = field.name_index;
        return self.getConstant(name_index);
    }

    pub fn getConstant(self: *ClassInfo, index: types.U2) ![]const u8 {
        if (self.constant_pool) |constantPool| {
            const cp_entry = constantPool[@intCast(index - 1)];
            return switch (cp_entry) {
                .Utf8 => |str| str,
                else => return error.InvalidConstantPoolEntry,
            };
        } else {
            return error.ConstantPoolNotInitialized;
        }
    }

    pub fn getMethodName(self: *ClassInfo, method: MethodInfo) ![]const u8 {
        const name_index = method.name_index;
        return self.getConstant(name_index);
    }
};