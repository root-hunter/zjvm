const std = @import("std");
const zjvm = @import("zjvm");
const parser = @import("classfile/parser.zig");
const ac = @import("classfile/access_flags.zig");
const utils = @import("classfile/utils.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var file = try std.fs.cwd().openFile("samples/Test.class", .{ .mode = .read_only });
    defer file.close();

    const file_size = try file.getEndPos();
    const data = try file.readToEndAlloc(allocator, file_size);

    var cursor = utils.Cursor.init(data);
    var classInfo = parser.ClassInfo.init(&allocator);
    try classInfo.parse(&cursor);

    std.debug.print("Class file magic: {x}\n", .{classInfo.magic});
    std.debug.print("Class file minor version: {d}\n", .{classInfo.minor_version});
    std.debug.print("Class file major version: {d}\n", .{classInfo.major_version});
    std.debug.print("Class file constant pool count: {d}\n", .{classInfo.constant_pool_count});
    std.debug.print("Class file access flags: {x}\n", .{classInfo.access_flags});
    std.debug.print("Class file this class index: {d}\n", .{classInfo.this_class});
    std.debug.print("Class file super class index: {d}\n", .{classInfo.super_class});
    std.debug.print("Class file interfaces count: {d}\n", .{classInfo.interfaces_count});
    std.debug.print("Class file interfaces: {any}\n", .{classInfo.interfaces});
    std.debug.print("Class file fields count: {d}\n", .{classInfo.fields_count});
    std.debug.print("Class file attributes count: {d}\n", .{classInfo.attributes_count});

    if (ac.ClassAccessFlags.isPublic(classInfo.access_flags)) {
        std.debug.print("The class is public.\n", .{});
    }

    if (ac.ClassAccessFlags.isFinal(classInfo.access_flags)) {
        std.debug.print("The class is final.\n", .{});
    }

    if (ac.ClassAccessFlags.isAbstract(classInfo.access_flags)) {
        std.debug.print("The class is abstract.\n", .{});
    }

    if (ac.ClassAccessFlags.isInterface(classInfo.access_flags)) {
        std.debug.print("The class is an interface.\n", .{});
    }

    // print all constant pool entries

    if (classInfo.constant_pool) |constantPool| {
        for (constantPool) |entry| {
            std.debug.print("Constant Pool Entry: {s}\n", .{entry.toString()});
        }
    }

    // print all fields

    if (classInfo.fields) |fields| {
        for (fields) |field| {
            std.debug.print("Field: name_index={d}, descriptor_index={d}, access_flags={x}\n", .{ field.name_index, field.descriptor_index, field.access_flags });
            std.debug.print("Field Name: {s}\n", .{try classInfo.getFieldName(field)});
        }
    }

    // print all methods

    if (classInfo.methods) |methods| {
        for (methods) |method| {
            std.debug.print("Method: name_index={d}, descriptor_index={d}, access_flags={x}\n", .{ method.name_index, method.descriptor_index, method.access_flags });
            std.debug.print("Method Name: {s}\n", .{try classInfo.getMethodName(method)});
        }
    }

    // print all attributes

    if (classInfo.attributes) |attributes| {
        for (attributes) |attribute| {
            std.debug.print("Attribute: name_index={d}, length={d}\n", .{ attribute.attribute_name_index, attribute.attribute_length });
        }
    }

    try zjvm.bufferedPrint();
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}
