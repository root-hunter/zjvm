const std = @import("std");
const zjvm = @import("zjvm");
const types = @import("classfile/types.zig");
const parser = @import("classfile/parser.zig");

pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    std.debug.print("Hello my name is Tony\n", .{});

    var file = try std.fs.cwd().openFile("samples/Test.class", .{ .mode = std.fs.File.OpenMode.read_only });
    defer file.close();

    var buffer: [1024]u8 = undefined;
    _ = try file.readAll(buffer[0..]);

    const classFile = try parser.parseHeader(&buffer);

    std.debug.print("Class file magic: {x}\n", .{classFile.magic});
    std.debug.print("Class file minor version: {d}\n", .{classFile.minor});
    std.debug.print("Class file major version: {d}\n", .{classFile.major});

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
