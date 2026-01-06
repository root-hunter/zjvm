const std = @import("std");
const types = @import("types.zig");
const cp = @import("constant_pool.zig");
const ac = @import("access_flags.zig");
const utils = @import("utils.zig");

const AttributesInfo = @import("attributes.zig").AttributesInfo;
const FieldInfo = @import("fields.zig").FieldInfo;
const MethodInfo = @import("methods.zig").MethodInfo;
const CodeAttribute = @import("code.zig").CodeAttribute;

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
        while (i < pool_size) {
            const entry = try cp.ConstantPoolInfo.parse(cursor);
            self.constant_pool.?[i] = entry;

            switch (entry) {
                .Long, .Double => {
                    i += 2; // slot extra "vuoto"
                },
                else => {
                    i += 1;
                },
            }
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

    pub fn getClassName(self: *ClassInfo) ![]const u8 {
        const class_cp = self.constant_pool.?[@intCast(self.this_class - 1)];
        return switch (class_cp) {
            .Class => |name_index| self.getConstant(name_index),
            else => error.InvalidClassInfo,
        };
    }

    pub fn getSuperClassName(self: *ClassInfo) ![]const u8 {
        const super_cp = self.constant_pool.?[@intCast(self.super_class - 1)];
        return switch (super_cp) {
            .Class => |name_index| self.getConstant(name_index),
            else => error.InvalidClassInfo,
        };
    }

    pub fn dump(self: *ClassInfo) !void {
        std.debug.print("Class: {s}\n", .{try self.getClassName()});
        std.debug.print("Super: {s}\n", .{try self.getSuperClassName()});
        std.debug.print("Fields:\n", .{});

        if (self.fields) |fields| {
            for (fields) |field| {
                std.debug.print("  {s}\n", .{try self.getFieldName(field)});
            }
        }

        std.debug.print("Methods:\n", .{});
        if (self.methods) |methods| {
            for (methods) |method| {
                std.debug.print("  {s}\n", .{try self.getMethodName(method)});
            }
        }
    }

    pub fn deinit(self: *ClassInfo) void {
        if (self.constant_pool) |constantPool| {
            self.allocator.free(constantPool);
            self.constant_pool = null;
        }

        if (self.interfaces) |interfaces| {
            self.allocator.free(interfaces);
            self.interfaces = null;
        }

        if (self.fields) |fields| {
            self.allocator.free(fields);
            self.fields = null;
        }

        if (self.methods) |methods| {
            self.allocator.free(methods);
            self.methods = null;
        }

        if (self.attributes) |attributes| {
            self.allocator.free(attributes);
            self.attributes = null;
        }
    }
};
