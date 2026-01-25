const std = @import("std");
const types = @import("../types.zig");
const cp = @import("constant_pool.zig");
const ac = @import("access_flags.zig");
const utils = @import("../../utils.zig");

const AttributesInfo = @import("attributes.zig").AttributesInfo;
const AttributesInfoJSON = @import("attributes.zig").AttributesInfoJSON;

const FieldInfo = @import("fields.zig").FieldInfo;
const FieldInfoJSON = @import("fields.zig").FieldInfoJSON;
const MethodInfo = @import("methods.zig").MethodInfo;
const MethodInfoJSON = @import("methods.zig").MethodInfoJSON;

const FieldRefInfo = cp.FieldRefInfo;
const MethodRefInfo = cp.MethodRefInfo;

pub const ClassInfoJSON = struct {
    magic: types.U4,
    minor_version: types.U2,
    major_version: types.U2,
    constant_pool_count: types.U2,
    constant_pool: []cp.ConstantPoolEntry,

    access_flags: types.U2,

    this_class: types.U2,
    super_class: types.U2,

    fields_count: types.U2,
    fields: ?[]FieldInfoJSON,

    methods_count: types.U2,
    methods: ?[]MethodInfoJSON,

    attributes_count: types.U2,
    attributes: ?[]AttributesInfoJSON,

    pub fn init(class: ClassInfo) !ClassInfoJSON {
        var fields: ?[]FieldInfoJSON = null;

        const allocator = std.heap.page_allocator;

        var field_jsons = try std.ArrayList(FieldInfoJSON).initCapacity(allocator, class.fields_count);

        if (class.fields) |f| {
            defer field_jsons.deinit(allocator);

            for (f) |field| {
                try field_jsons.append(allocator, field.toJSON());
            }

            fields = try field_jsons.toOwnedSlice(allocator);
        }

        var methods: ?[]MethodInfoJSON = null;

        if (class.methods) |m| {
            var method_jsons = try std.ArrayList(MethodInfoJSON).initCapacity(allocator, class.methods_count);
            defer method_jsons.deinit(allocator);

            for (m) |method| {
                try method_jsons.append(allocator, method.toJSON());
            }

            methods = try method_jsons.toOwnedSlice(allocator);
        }

        var attrs: ?[]AttributesInfoJSON = null;

        if (class.attributes) |a| {
            var attr_jsons = try std.ArrayList(AttributesInfoJSON).initCapacity(allocator, class.attributes_count);
            defer attr_jsons.deinit(allocator);

            for (a) |attr| {
                try attr_jsons.append(allocator, attr.toJSON());
            }

            attrs = try attr_jsons.toOwnedSlice(allocator);
        }

        return ClassInfoJSON{
            .magic = class.magic,
            .minor_version = class.minor_version,
            .major_version = class.major_version,
            .constant_pool_count = class.constant_pool_count,
            .constant_pool = class.constant_pool.?,
            .access_flags = class.access_flags,
            .this_class = class.this_class,
            .super_class = class.super_class,
            .fields_count = class.fields_count,
            .fields = fields,
            .methods_count = class.methods_count,
            .methods = methods,
            .attributes_count = class.attributes_count,
            .attributes = attrs,
        };
    }
};

pub const ClassInfo = struct {
    allocator: *const std.mem.Allocator,

    magic: types.U4,
    minor_version: types.U2,
    major_version: types.U2,
    constant_pool_count: types.U2,
    constant_pool: ?[]cp.ConstantPoolEntry,

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

    // ZJVM additions
    name: []const u8,
    super_class_name: []const u8,

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
            .name = &[_]u8{},
            .super_class_name = &[_]u8{},
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
        self.constant_pool = try self.allocator.alloc(cp.ConstantPoolEntry, pool_size);

        var i: usize = 0;
        while (i < pool_size) {
            const entry = try cp.ConstantPoolEntry.parse(cursor);
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

        // ZJVM additions
        self.name = try self.setClassName();
        self.super_class_name = try self.setSuperClassName();
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
        self.fields = try FieldInfo.parseAll(cursor, @intCast(self.fields_count), self.allocator, self);
    }

    pub fn parseMethods(self: *ClassInfo, cursor: *utils.Cursor) !void {
        self.methods_count = try cursor.readU2();
        self.methods = try MethodInfo.parseAll(self, cursor, @intCast(self.methods_count), self.allocator);
    }

    pub fn parseAttributes(self: *ClassInfo, cursor: *utils.Cursor) !void {
        self.attributes_count = try cursor.readU2();
        self.attributes = try AttributesInfo.parseAll(self.allocator, cursor, @intCast(self.attributes_count), self);
    }

    pub fn isValidMagicNumber(self: *ClassInfo) bool {
        return self.magic == 0xCAFEBABE;
    }

    pub fn getFieldName(self: *ClassInfo, field: FieldInfo) ![]const u8 {
        const name_index = field.name_index;
        return self.getConstantUtf8(name_index);
    }

    pub fn getFieldRef(self: *const ClassInfo, index: types.U2) !FieldRefInfo {
        if (self.constant_pool) |constantPool| {
            const cp_entry = constantPool[@intCast(index - 1)];

            return switch (cp_entry) {
                .Fieldref => |fieldref| {
                    return FieldRefInfo{
                        .class_index = fieldref.class_index,
                        .name_and_type_index = fieldref.name_and_type_index,
                    };
                },
                else => {
                    std.debug.print("Error: Constant pool entry at index {d} is not a FieldRef entry. Found: {s}\n", .{ index, @tagName(cp_entry) });
                    return error.InvalidConstantPoolEntry;
                },
            };
        } else {
            return error.ConstantPoolNotInitialized;
        }
    }

    pub fn getMethodRef(self: *const ClassInfo, index: types.U2) !MethodRefInfo {
        if (self.constant_pool) |constantPool| {
            if (index == 0 or index > constantPool.len) {
                std.debug.print("Error: Invalid constant pool index {d} for MethodRef.\n", .{index});
                return error.InvalidConstantPoolIndex;
            }

            const cp_entry = constantPool[@intCast(index - 1)];

            return switch (cp_entry) {
                .Methodref => |methodref| {
                    return MethodRefInfo{
                        .class_index = methodref.class_index,
                        .name_and_type_index = methodref.name_and_type_index,
                    };
                },
                else => {
                    std.debug.print("Error: Constant pool entry at index {d} is not a MethodRef entry. Found: {s}\n", .{ index, @tagName(cp_entry) });
                    return error.InvalidConstantPoolEntry;
                },
            };
        } else {
            return error.ConstantPoolNotInitialized;
        }
    }

    pub fn getConstant(self: *const ClassInfo, index: types.U2) !cp.ConstantPoolEntry {
        if (self.constant_pool) |constantPool| {
            const cp_entry = constantPool[@intCast(index - 1)];
            return cp_entry;
        } else {
            return error.ConstantPoolNotInitialized;
        }
    }

    pub fn getConstantUtf8(self: *const ClassInfo, index: types.U2) ![]const u8 {
        const cp_entry = try self.getConstant(index);
        return switch (cp_entry) {
            .Utf8 => |str| str,
            .Class => |name_index| {
                const name_cp = try self.getConstant(name_index);
                return switch (name_cp) {
                    .Utf8 => |name_str| name_str,
                    else => {
                        std.debug.print("Error: Class entry at index {d} does not point to a Utf8 entry for name. Found: {s}\n", .{ name_index, @tagName(name_cp) });
                        return error.InvalidConstantPoolEntry;
                    },
                };
            },
            .Methodref => |methodref| {
                const name_and_type_cp = try self.getConstant(methodref.name_and_type_index);
                return switch (name_and_type_cp) {
                    .NameAndType => |name_and_type| {
                        const name_cp = try self.getConstant(name_and_type.name_index);
                        return switch (name_cp) {
                            .Utf8 => |name_str| name_str,
                            else => {
                                std.debug.print("Error: NameAndType entry at index {d} does not point to a Utf8 entry for name. Found: {s}\n", .{ name_and_type.name_index, @tagName(name_cp) });
                                return error.InvalidConstantPoolEntry;
                            },
                        };
                    },
                    else => {
                        std.debug.print("Error: Methodref entry at index {d} does not point to a NameAndType entry. Found: {s}\n", .{ methodref.name_and_type_index, @tagName(name_and_type_cp) });
                        return error.InvalidConstantPoolEntry;
                    },
                };
            },
            else => {
                std.debug.print("Error: Constant pool entry at index {d} is not a Utf8 entry. Found: {s}\n", .{ index, @tagName(cp_entry) });
                return error.InvalidConstantPoolEntry;
            },
        };
    }

    pub fn getConstantString(self: *const ClassInfo, index: types.U2) ![]const u8 {
        const cp_entry = try self.getConstant(index);
        return switch (cp_entry) {
            .String => |string_index| {
                const string_cp = try self.getConstant(string_index);
                return switch (string_cp) {
                    .Utf8 => |str| str,
                    else => {
                        std.debug.print("Error: String entry at index {d} does not point to a Utf8 entry. Found: {s}\n", .{ string_index, @tagName(string_cp) });
                        return error.InvalidConstantPoolEntry;
                    },
                };
            },
            else => {
                std.debug.print("Error: Constant pool entry at index {d} is not a String entry. Found: {s}\n", .{ index, @tagName(cp_entry) });
                return error.InvalidConstantPoolEntry;
            },
        };
    }

    pub fn getConstantPoolEntry(
        self: *const ClassInfo,
        index: u16,
    ) !cp.ConstantPoolEntry {
        if (self.constant_pool == null)
            return error.ConstantPoolNotInitialized;

        if (index == 0 or index > self.constant_pool.?.len)
            return error.InvalidConstantPoolIndex;

        return self.constant_pool.?[@intCast(index - 1)];
    }

    pub fn getMethodName(self: *const ClassInfo, method: MethodInfo) ![]const u8 {
        const name_index = method.name_index;
        return self.getConstantUtf8(name_index);
    }

    fn setClassName(self: *const ClassInfo) ![]const u8 {
        const class_cp = self.constant_pool.?[@intCast(self.this_class - 1)];
        return switch (class_cp) {
            .Class => |name_index| self.getConstantUtf8(name_index),
            else => error.InvalidClassInfo,
        };
    }

    fn setSuperClassName(self: *ClassInfo) ![]const u8 {
        const super_cp = self.constant_pool.?[@intCast(self.super_class - 1)];
        return switch (super_cp) {
            .Class => |name_index| self.getConstantUtf8(name_index),
            else => error.InvalidClassInfo,
        };
    }

    pub fn getClassName(self: *ClassInfo) []const u8 {
        return self.name;
    }

    pub fn getSuperClassName(self: *ClassInfo) []const u8 {
        return self.super_class_name;
    }

    pub fn dump(self: *ClassInfo) !void {
        std.debug.print("Class: {s}\n", .{self.name});
        std.debug.print("Super: {s}\n", .{self.super_class_name});
        std.debug.print("Magic: 0x{X:0>8}\n", .{self.magic});
        std.debug.print("Version: {d}.{d}\n", .{ self.major_version, self.minor_version });
        std.debug.print("Constant Pool Count: {d}\n", .{self.constant_pool_count});
        std.debug.print("Access Flags: 0x{X:0>4}\n", .{self.access_flags});
        std.debug.print("Fields:\n", .{});

        if (self.fields) |fields| {
            for (fields) |field| {
                std.debug.print("  {s}\n", .{try self.getFieldName(field)});
            }
        }

        std.debug.print("Methods:\n", .{});
        if (self.methods) |methods| {
            for (methods) |tmethod| {
                try tmethod.dump();
            }
        }
    }

    pub fn getMethod(self: *const ClassInfo, name: []const u8) !?MethodInfo {
        if (self.methods) |methods| {
            for (methods) |method| {
                const method_name = try self.getConstantUtf8(method.name_index);
                if (std.mem.eql(u8, method_name, name)) {
                    return method;
                }
            }
        }
        return null;
    }

    pub fn getMethodFromIndex(self: *const ClassInfo, index: types.U2) !?MethodInfo {
        if (self.methods) |methods| {
            const method_idx: usize = @intCast(index);
            if (method_idx < methods.len) {
                return methods[method_idx];
            } else {
                return null;
            }
        } else {
            return null;
        }
    }

    pub fn getBootstrapMethod(self: *const ClassInfo, index: types.U2) !cp.InvokeDynamicRefInfo {
        const cp_entry = try self.getConstant(index);
        const invokedynamic = switch (cp_entry) {
            .InvokeDynamic => |id| id,
            else => return error.InvalidConstantPoolEntry,
        };

        // Cerca il BootstrapMethods attribute tra gli attributes
        if (self.attributes) |attrs| {
            for (attrs) |attr| {
                if (attr.isBootstrapMethods()) {
                    const bm_attr = try attr.getBootstrapMethods(self);
                    if (invokedynamic.bootstrap_method_attr_index < bm_attr.len) {
                        const attr_index: usize = @intCast(invokedynamic.bootstrap_method_attr_index);
                        return bm_attr[attr_index];
                    } else {
                        return error.InvalidBootstrapMethodIndex;
                    }
                }
            }
        }

        return error.BootstrapMethodsNotFound;
    }

    pub fn toJSON(self: *const ClassInfo) !ClassInfoJSON {
        return try ClassInfoJSON.init(self.*);
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
