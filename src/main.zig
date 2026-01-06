const std = @import("std");
const zjvm = @import("zjvm");
const parser = @import("classfile/parser.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var file = try std.fs.cwd().openFile("samples/Test.class", .{ .mode = .read_only });
    defer file.close();

    const file_size = try file.getEndPos();
    const data = try file.readToEndAlloc(allocator, file_size);

    var cursor = parser.Cursor.init(data);
    var classHeader = parser.ClassFile.init();
    try classHeader.parse(&cursor);

    std.debug.print("Class file magic: {x}\n", .{classHeader.magic});
    std.debug.print("Class file minor version: {d}\n", .{classHeader.minor});
    std.debug.print("Class file major version: {d}\n", .{classHeader.major});
    std.debug.print("Class file constant pool count: {d}\n", .{classHeader.constantPoolCount});

    // print all constant pool entries

    if (classHeader.constantPool) |constantPool| {
        for (constantPool) |entry| {
            std.debug.print("Constant Pool Entry: {s}\n", .{entry.toString()});
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
