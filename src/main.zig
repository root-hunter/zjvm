const std = @import("std");
const parser = @import("classfile/parser.zig");
const ac = @import("classfile/access_flags.zig");
const utils = @import("classfile/utils.zig");

const fr = @import("runtime/frame.zig");

const JVMInterpreter = @import("engine/interpreter.zig").JVMInterpreter;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var file = try std.fs.cwd().openFile("samples/TestSuite1.class", .{ .mode = .read_only });
    defer file.close();

    const file_size = try file.getEndPos();
    const data = try file.readToEndAlloc(allocator, file_size);
    defer allocator.free(data);

    var cursor = utils.Cursor.init(data);
    var classInfo = parser.ClassInfo.init(&allocator);
    defer classInfo.deinit();

    try classInfo.parse(&cursor);

    const mMain = try classInfo.getMethod("main");

    std.debug.print("Method 'main' found: {any}\n", .{mMain});

    try classInfo.dump();

    if (mMain) |method| {
        if (method.code) |codeAttr| {
            std.debug.print("Starting execution of 'main'...\n", .{});

            var frame = try fr.Frame.init(&allocator, codeAttr);
            try JVMInterpreter.execute(&frame);

            std.debug.print("Execution of 'main' completed.\n", .{});
        } else {
            std.debug.print("No code attribute found for method 'main'\n", .{});
        }
    }
}
