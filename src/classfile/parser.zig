const std = @import("std");
const types = @import("types.zig");
const cp = @import("constant_pool.zig");
const ac = @import("access_flags.zig");

pub const ConstantPoolInfo = union(cp.CpTag) {
    Utf8: []const u8,
    Integer: i32,
    Float: f32,
    Long: i64,
    Double: f64,
    Class: u16,
    String: u16,
    Fieldref: struct {
        class_index: u16,
        name_and_type_index: u16,
    },
    Methodref: struct {
        class_index: u16,
        name_and_type_index: u16,
    },
    InterfaceMethodref: struct {
        class_index: u16,
        name_and_type_index: u16,
    },
    NameAndType: struct {
        name_index: u16,
        descriptor_index: u16,
    },
    MethodHandle: struct {
        reference_kind: u8,
        reference_index: u16,
    },
    MethodType: u16,
    Dynamic: struct {
        bootstrap_method_attr_index: u16,
        name_and_type_index: u16,
    },
    InvokeDynamic: struct {
        bootstrap_method_attr_index: u16,
        name_and_type_index: u16,
    },
    Module: u16,
    Package: u16,

    pub fn parse(cursor: *Cursor) !ConstantPoolInfo {
        const tag = try cursor.readU1();
        const tag_enum: cp.CpTag = @enumFromInt(tag);

        switch (tag_enum) {
            cp.CpTag.Utf8 => |_| {
                const length = try cursor.readU2();
                const bytes = try cursor.readBytes(@intCast(length));
                return ConstantPoolInfo{ .Utf8 = bytes };
            },
            cp.CpTag.Integer => |_| {
                const value = try cursor.readU4();
                return ConstantPoolInfo{ .Integer = @intCast(value) };
            },
            cp.CpTag.Float => |_| {
                const value = try cursor.readU4();
                return ConstantPoolInfo{ .Float = @bitCast(value) };
            },
            cp.CpTag.Long => |_| {
                const high_bytes = try cursor.readU4();
                const low_bytes = try cursor.readU4();
                const value = (@as(u64, high_bytes) << 32) | @as(u64, low_bytes);
                return ConstantPoolInfo{ .Long = @intCast(value) };
            },
            cp.CpTag.Double => |_| {
                const high_bytes = try cursor.readU4();
                const low_bytes = try cursor.readU4();
                const value = (@as(u64, high_bytes) << 32) | @as(u64, low_bytes);
                return ConstantPoolInfo{ .Double = @bitCast(value) };
            },
            cp.CpTag.Class => |_| {
                const name_index = try cursor.readU2();
                return ConstantPoolInfo{ .Class = name_index };
            },
            cp.CpTag.String => |_| {
                const string_index = try cursor.readU2();
                return ConstantPoolInfo{ .String = string_index };
            },
            cp.CpTag.Fieldref => |_| {
                const class_index = try cursor.readU2();
                const name_and_type_index = try cursor.readU2();
                return ConstantPoolInfo{ .Fieldref = .{ .class_index = class_index, .name_and_type_index = name_and_type_index } };
            },
            cp.CpTag.Methodref => |_| {
                const class_index = try cursor.readU2();
                const name_and_type_index = try cursor.readU2();
                return ConstantPoolInfo{ .Methodref = .{ .class_index = class_index, .name_and_type_index = name_and_type_index } };
            },
            cp.CpTag.InterfaceMethodref => |_| {
                const class_index = try cursor.readU2();
                const name_and_type_index = try cursor.readU2();
                return ConstantPoolInfo{ .InterfaceMethodref = .{ .class_index = class_index, .name_and_type_index = name_and_type_index } };
            },
            cp.CpTag.NameAndType => |_| {
                const name_index = try cursor.readU2();
                const descriptor_index = try cursor.readU2();
                return ConstantPoolInfo{ .NameAndType = .{ .name_index = name_index, .descriptor_index = descriptor_index } };
            },
            cp.CpTag.MethodHandle => |_| {
                const reference_kind = try cursor.readU1();
                const reference_index = try cursor.readU2();
                return ConstantPoolInfo{ .MethodHandle = .{ .reference_kind = reference_kind, .reference_index = reference_index } };
            },
            cp.CpTag.MethodType => |_| {
                const descriptor_index = try cursor.readU2();
                return ConstantPoolInfo{ .MethodType = descriptor_index };
            },
            cp.CpTag.Dynamic => |_| {
                const bootstrap_method_attr_index = try cursor.readU2();
                const name_and_type_index = try cursor.readU2();
                return ConstantPoolInfo{ .Dynamic = .{ .bootstrap_method_attr_index = bootstrap_method_attr_index, .name_and_type_index = name_and_type_index } };
            },
            cp.CpTag.InvokeDynamic => |_| {
                const bootstrap_method_attr_index = try cursor.readU2();
                const name_and_type_index = try cursor.readU2();
                return ConstantPoolInfo{ .InvokeDynamic = .{ .bootstrap_method_attr_index = bootstrap_method_attr_index, .name_and_type_index = name_and_type_index } };
            },
            cp.CpTag.Module => |_| {
                const name_index = try cursor.readU2();
                return ConstantPoolInfo{ .Module = name_index };
            },
            cp.CpTag.Package => |_| {
                const name_index = try cursor.readU2();
                return ConstantPoolInfo{ .Package = name_index };
            },
        }
    }

    pub fn toString(self: ConstantPoolInfo) []const u8 {
        return switch (self) {
            .Utf8 => |str| str,
            .Integer => |val| std.fmt.allocPrint(std.heap.page_allocator, "Integer: {}", .{val}) catch "Integer: <error>",
            .Float => |val| std.fmt.allocPrint(std.heap.page_allocator, "Float: {}", .{val}) catch "Float: <error>",
            .Long => |val| std.fmt.allocPrint(std.heap.page_allocator, "Long: {}", .{val}) catch "Long: <error>",
            .Double => |val| std.fmt.allocPrint(std.heap.page_allocator, "Double: {}", .{val}) catch "Double: <error>",
            .Class => |idx| std.fmt.allocPrint(std.heap.page_allocator, "Class Index: {}", .{idx}) catch "Class Index: <error>",
            .String => |idx| std.fmt.allocPrint(std.heap.page_allocator, "String Index: {}", .{idx}) catch "String Index: <error>",
            .Fieldref => |fieldref| std.fmt.allocPrint(std.heap.page_allocator, "Fieldref: class_index={}, name_and_type_index={}", .{ fieldref.class_index, fieldref.name_and_type_index }) catch "Fieldref: <error>",
            .Methodref => |methodref| std.fmt.allocPrint(std.heap.page_allocator, "Methodref: class_index={}, name_and_type_index={}", .{ methodref.class_index, methodref.name_and_type_index }) catch "Methodref: <error>",
            .InterfaceMethodref => |imref| std.fmt.allocPrint(std.heap.page_allocator, "InterfaceMethodref: class_index={}, name_and_type_index={}", .{ imref.class_index, imref.name_and_type_index }) catch "InterfaceMethodref: <error>",
            .NameAndType => |nat| std.fmt.allocPrint(std.heap.page_allocator, "NameAndType: name_index={}, descriptor_index={}", .{ nat.name_index, nat.descriptor_index }) catch "NameAndType: <error>",
            .MethodHandle => |mh| std.fmt.allocPrint(std.heap.page_allocator, "MethodHandle: reference_kind={}, reference_index={}", .{ mh.reference_kind, mh.reference_index }) catch "MethodHandle: <error>",
            .MethodType => |idx| std.fmt.allocPrint(std.heap.page_allocator, "MethodType: descriptor_index={}", .{idx}) catch "MethodType: <error>",
            .Dynamic => |dyn| std.fmt.allocPrint(std.heap.page_allocator, "Dynamic: bootstrap_method_attr_index={}, name_and_type_index={}", .{ dyn.bootstrap_method_attr_index, dyn.name_and_type_index }) catch "Dynamic: <error>",
            .InvokeDynamic => |indy| std.fmt.allocPrint(std.heap.page_allocator, "InvokeDynamic: bootstrap_method_attr_index={}, name_and_type_index={}", .{ indy.bootstrap_method_attr_index, indy.name_and_type_index }) catch "InvokeDynamic: <error>",
            .Module => |idx| std.fmt.allocPrint(std.heap.page_allocator, "Module: name_index={}", .{idx}) catch "Module: <error>",
            .Package => |idx| std.fmt.allocPrint(std.heap.page_allocator, "Package: name_index={}", .{idx}) catch "Package: <error>",
        };
    }
};

pub const AttributesInfo = struct {
    attributeNameIndex: types.U2,
    attributeLength: types.U4,
    info: []const u8,

    pub fn parse(cursor: *Cursor) !AttributesInfo {
        const attributeNameIndex = try cursor.readU2();
        const attributeLength = try cursor.readU4();
        const info = try cursor.readBytes(@intCast(attributeLength));

        return AttributesInfo{
            .attributeNameIndex = attributeNameIndex,
            .attributeLength = attributeLength,
            .info = info,
        };
    }
};

pub const FieldInfo = struct {
    allocator: *const std.mem.Allocator,

    access_flags: types.U2,
    name_index: types.U2,
    descriptor_index: types.U2,
    attributes_count: types.U2,
    attributes: ?[]AttributesInfo,

    pub fn parse(allocator: *const std.mem.Allocator, cursor: *Cursor) !FieldInfo {
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
        self.attributes = try self.allocator.alloc(AttributesInfo, count);

        var i: usize = 0;
        while (i < count) : (i += 1) {
            const attr = try AttributesInfo.parse(cursor);
            self.attributes.?[i] = attr;
        }

        return self;
    }
};

pub const ClassInfo = struct {
    allocator: *const std.mem.Allocator,

    magic: types.U4,
    minor: types.U2,
    major: types.U2,
    constant_pool_count: types.U2,
    constant_pool: ?[]ConstantPoolInfo,

    access_flags: types.U2,

    this_class: types.U2,
    super_class: types.U2,

    interfaces_count: types.U2,
    interfaces: ?[]types.U2,

    fields_count: types.U2,
    fields: ?[]FieldInfo,

    methods_count: types.U2,

    attributes_count: types.U2,

    pub fn init(allocator: *const std.mem.Allocator) ClassInfo {
        return ClassInfo{
            .allocator = allocator,

            .magic = 0,
            .minor = 0,
            .major = 0,
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
            .attributes_count = 0,
        };
    }

    pub fn parse(self: *ClassInfo, cursor: *Cursor) !void {
        try self.parseHeaders(cursor);
        try self.parseConstantPool(cursor);
        try self.parseAccessFlags(cursor);
        try self.parseClassMetadata(cursor);
        try self.parseInferfaces(cursor);
        try self.parseFields(cursor);
    }

    pub fn parseHeaders(self: *ClassInfo, cursor: *Cursor) !void {
        self.magic = try cursor.readU4();
        self.minor = try cursor.readU2();
        self.major = try cursor.readU2();
        self.constant_pool_count = try cursor.readU2();
    }

    pub fn parseConstantPool(self: *ClassInfo, cursor: *Cursor) !void {
        const pool_size: usize = @intCast(self.constant_pool_count - 1);
        self.constant_pool = try self.allocator.alloc(ConstantPoolInfo, pool_size);

        var i: usize = 0;
        while (i < pool_size) : (i += 1) {
            self.constant_pool.?[i] = try ConstantPoolInfo.parse(cursor);
        }
    }

    pub fn parseAccessFlags(self: *ClassInfo, cursor: *Cursor) !void {
        self.access_flags = try cursor.readU2();
    }

    pub fn parseClassMetadata(self: *ClassInfo, cursor: *Cursor) !void {
        self.this_class = try cursor.readU2();
        self.super_class = try cursor.readU2();
    }

    pub fn parseInferfaces(self: *ClassInfo, cursor: *Cursor) !void {
        self.interfaces_count = try cursor.readU2();
        const count: usize = @intCast(self.interfaces_count);
        self.interfaces = try self.allocator.alloc(types.U2, count);

        var i: usize = 0;
        while (i < count) : (i += 1) {
            self.interfaces.?[i] = try cursor.readU2();
        }
    }

    pub fn parseFields(self: *ClassInfo, cursor: *Cursor) !void {
        self.fields_count = try cursor.readU2();
        const count: usize = @intCast(self.fields_count);
        self.fields = try self.allocator.alloc(FieldInfo, count);

        var i: usize = 0;
        while (i < count) : (i += 1) {
            const field = try FieldInfo.parse(self.allocator, cursor);
            self.fields.?[i] = field;
        }
    }

    pub fn isValidMagicNumber(self: *ClassInfo) bool {
        return self.magic == 0xCAFEBABE;
    }

    pub fn getFieldName(self: *ClassInfo, field: FieldInfo) ![]const u8 {
        const name_index = field.name_index;
        return self.getFieldNameByIndex(name_index);
    }

    pub fn getFieldNameByIndex(self: *ClassInfo, name_index: types.U2) ![]const u8 {
        if (self.constant_pool) |constantPool| {
            const cp_entry = constantPool[@intCast(name_index - 1)];
            return switch (cp_entry) {
                .Utf8 => |str| str,
                else => return error.InvalidConstantPoolEntry,
            };
        } else {
            return error.ConstantPoolNotInitialized;
        }
    }
};

pub const Cursor = struct {
    buffer: []const u8,
    position: usize,

    pub fn init(buffer: []const u8) Cursor {
        return Cursor{
            .buffer = buffer,
            .position = 0,
        };
    }

    pub fn readU1(self: *Cursor) !types.U1 {
        if (self.position + 1 > self.buffer.len) {
            return error.UnableToRead;
        }
        const value = self.buffer[self.position];
        self.position += 1;
        return value;
    }

    pub fn readU2(self: *Cursor) !types.U2 {
        if (self.position + 2 > self.buffer.len) {
            return error.UnableToRead;
        }

        const slice = self.buffer[self.position .. self.position + 2];
        const arr_ptr: *const [2]u8 = @ptrCast(slice.ptr);

        const value = std.mem.readInt(types.U2, arr_ptr, .big);
        self.position += 2;
        return value;
    }

    pub fn readU4(self: *Cursor) !types.U4 {
        if (self.position + 4 > self.buffer.len) {
            return error.UnableToRead;
        }

        const slice = self.buffer[self.position .. self.position + 4];
        const arr_ptr: *const [4]u8 = @ptrCast(slice.ptr);

        const value = std.mem.readInt(types.U4, arr_ptr, .big);
        self.position += 4;
        return value;
    }

    pub fn readBytes(self: *Cursor, length: usize) ![]const u8 {
        if (self.position + length > self.buffer.len) {
            return error.UnableToRead;
        }
        const bytes = self.buffer[self.position .. self.position + length];
        self.position += length;
        return bytes;
    }
};
