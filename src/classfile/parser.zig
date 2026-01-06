const std = @import("std");
const types = @import("types.zig");
const cp = @import("constant_pool.zig");

pub const ConstantPoolInfo = union(enum) {
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

        std.debug.print("Tag: {}\n", .{tag});
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
            .Fieldref => |fieldref| std.fmt.allocPrint(std.heap.page_allocator, "Fieldref: class_index={}, name_and_type_index={}", .{fieldref.class_index, fieldref.name_and_type_index}) catch "Fieldref: <error>",
            .Methodref => |methodref| std.fmt.allocPrint(std.heap.page_allocator, "Methodref: class_index={}, name_and_type_index={}", .{methodref.class_index, methodref.name_and_type_index}) catch "Methodref: <error>",
            .InterfaceMethodref => |imref| std.fmt.allocPrint(std.heap.page_allocator, "InterfaceMethodref: class_index={}, name_and_type_index={}", .{imref.class_index, imref.name_and_type_index}) catch "InterfaceMethodref: <error>",
            .NameAndType => |nat| std.fmt.allocPrint(std.heap.page_allocator, "NameAndType: name_index={}, descriptor_index={}", .{nat.name_index, nat.descriptor_index}) catch "NameAndType: <error>",
            .MethodHandle => |mh| std.fmt.allocPrint(std.heap.page_allocator, "MethodHandle: reference_kind={}, reference_index={}", .{mh.reference_kind, mh.reference_index}) catch "MethodHandle: <error>",
            .MethodType => |idx| std.fmt.allocPrint(std.heap.page_allocator, "MethodType: descriptor_index={}", .{idx}) catch "MethodType: <error>",
            .Dynamic => |dyn| std.fmt.allocPrint(std.heap.page_allocator, "Dynamic: bootstrap_method_attr_index={}, name_and_type_index={}", .{dyn.bootstrap_method_attr_index, dyn.name_and_type_index}) catch "Dynamic: <error>",
            .InvokeDynamic => |indy| std.fmt.allocPrint(std.heap.page_allocator, "InvokeDynamic: bootstrap_method_attr_index={}, name_and_type_index={}", .{indy.bootstrap_method_attr_index, indy.name_and_type_index}) catch "InvokeDynamic: <error>",
            .Module => |idx| std.fmt.allocPrint(std.heap.page_allocator, "Module: name_index={}", .{idx}) catch "Module: <error>",
            .Package => |idx| std.fmt.allocPrint(std.heap.page_allocator, "Package: name_index={}", .{idx}) catch "Package: <error>",
        };
    }
};

pub const ClassFile = struct {
    magic: types.U4,
    minor: types.U2,
    major: types.U2,
    constantPoolCount: types.U2,
    constantPool: ?[]ConstantPoolInfo,

    pub fn init() ClassFile {
        return ClassFile{
            .magic = 0,
            .minor = 0,
            .major = 0,
            .constantPoolCount = 0,
            .constantPool = null,
        };
    }

    pub fn parse(self: *ClassFile, cursor: *Cursor) !void {
        try self.parseHeaders(cursor);
        try self.parseConstantPool(cursor);
    }

    pub fn parseHeaders(self: *ClassFile, cursor: *Cursor) !void {
        self.magic = try cursor.readU4();
        self.minor = try cursor.readU2();
        self.major = try cursor.readU2();
        self.constantPoolCount = try cursor.readU2();
    }

    pub fn parseConstantPool(self: *ClassFile, cursor: *Cursor) !void {
        const pool_size: usize = @intCast(self.constantPoolCount - 1);
        self.constantPool = try std.heap.page_allocator.alloc(ConstantPoolInfo, pool_size);

        var i: usize = 0;
        while (i < pool_size) : (i += 1) {
            self.constantPool.?[i] = try ConstantPoolInfo.parse(cursor);
        }
    }

    pub fn isValidMagicNumber(self: *ClassFile) bool {
        return self.magic == 0xCAFEBABE;
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
