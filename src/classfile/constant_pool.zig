const std = @import("std");
const types = @import("types.zig");
const utils = @import("utils.zig");

pub const CpTag = enum(types.U1) {
    Utf8 = 1,
    Integer = 3,
    Float = 4,
    Long = 5,
    Double = 6,
    Class = 7,
    String = 8,
    Fieldref = 9,
    Methodref = 10,
    InterfaceMethodref = 11,
    NameAndType = 12,
    MethodHandle = 15,
    MethodType = 16,
    Dynamic = 17,
    InvokeDynamic = 18,
    Module = 19,
    Package = 20,
};

pub const ConstantPoolEntry = union(CpTag) {
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

    pub fn parse(cursor: *utils.Cursor) !ConstantPoolEntry {
        const tag = try cursor.readU1();
        const tag_enum: CpTag = @enumFromInt(tag);

        switch (tag_enum) {
            CpTag.Utf8 => |_| {
                const length = try cursor.readU2();
                const bytes = try cursor.readBytes(@intCast(length));
                return ConstantPoolEntry{ .Utf8 = bytes };
            },
            CpTag.Integer => |_| {
                const value = try cursor.readU4();
                return ConstantPoolEntry{ .Integer = @intCast(value) };
            },
            CpTag.Float => |_| {
                const value = try cursor.readU4();
                return ConstantPoolEntry{ .Float = @bitCast(value) };
            },
            CpTag.Long => |_| {
                const high_bytes = try cursor.readU4();
                const low_bytes = try cursor.readU4();
                const value = (@as(u64, high_bytes) << 32) | @as(u64, low_bytes);
                return ConstantPoolEntry{ .Long = @intCast(value) };
            },
            CpTag.Double => |_| {
                const high_bytes = try cursor.readU4();
                const low_bytes = try cursor.readU4();
                const value = (@as(u64, high_bytes) << 32) | @as(u64, low_bytes);
                return ConstantPoolEntry{ .Double = @bitCast(value) };
            },
            CpTag.Class => |_| {
                const name_index = try cursor.readU2();
                return ConstantPoolEntry{ .Class = name_index };
            },
            CpTag.String => |_| {
                const string_index = try cursor.readU2();
                return ConstantPoolEntry{ .String = string_index };
            },
            CpTag.Fieldref => |_| {
                const class_index = try cursor.readU2();
                const name_and_type_index = try cursor.readU2();
                return ConstantPoolEntry{ .Fieldref = .{ .class_index = class_index, .name_and_type_index = name_and_type_index } };
            },
            CpTag.Methodref => |_| {
                const class_index = try cursor.readU2();
                const name_and_type_index = try cursor.readU2();
                return ConstantPoolEntry{ .Methodref = .{ .class_index = class_index, .name_and_type_index = name_and_type_index } };
            },
            CpTag.InterfaceMethodref => |_| {
                const class_index = try cursor.readU2();
                const name_and_type_index = try cursor.readU2();
                return ConstantPoolEntry{ .InterfaceMethodref = .{ .class_index = class_index, .name_and_type_index = name_and_type_index } };
            },
            CpTag.NameAndType => |_| {
                const name_index = try cursor.readU2();
                const descriptor_index = try cursor.readU2();
                return ConstantPoolEntry{ .NameAndType = .{ .name_index = name_index, .descriptor_index = descriptor_index } };
            },
            CpTag.MethodHandle => |_| {
                const reference_kind = try cursor.readU1();
                const reference_index = try cursor.readU2();
                return ConstantPoolEntry{ .MethodHandle = .{ .reference_kind = reference_kind, .reference_index = reference_index } };
            },
            CpTag.MethodType => |_| {
                const descriptor_index = try cursor.readU2();
                return ConstantPoolEntry{ .MethodType = descriptor_index };
            },
            CpTag.Dynamic => |_| {
                const bootstrap_method_attr_index = try cursor.readU2();
                const name_and_type_index = try cursor.readU2();
                return ConstantPoolEntry{ .Dynamic = .{ .bootstrap_method_attr_index = bootstrap_method_attr_index, .name_and_type_index = name_and_type_index } };
            },
            CpTag.InvokeDynamic => |_| {
                const bootstrap_method_attr_index = try cursor.readU2();
                const name_and_type_index = try cursor.readU2();
                return ConstantPoolEntry{ .InvokeDynamic = .{ .bootstrap_method_attr_index = bootstrap_method_attr_index, .name_and_type_index = name_and_type_index } };
            },
            CpTag.Module => |_| {
                const name_index = try cursor.readU2();
                return ConstantPoolEntry{ .Module = name_index };
            },
            CpTag.Package => |_| {
                const name_index = try cursor.readU2();
                return ConstantPoolEntry{ .Package = name_index };
            },
        }
    }

    pub fn toString(self: ConstantPoolEntry) []const u8 {
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
