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
    defer allocator.free(data);

    var cursor = utils.Cursor.init(data);
    var classInfo = parser.ClassInfo.init(&allocator);
    defer classInfo.deinit();

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

    try classInfo.dump();

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
