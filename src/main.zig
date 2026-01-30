const std = @import("std");
const parser = @import("vm/class//parser.zig");
const ac = @import("vm/class/access_flags.zig");
const utils = @import("utils.zig");

const fr = @import("vm/interpreter/frame.zig");
const JVMInterpreter = @import("vm/interpreter/exec.zig").JVMInterpreter;
const ZJVM = @import("vm/vm.zig").ZJVM;

pub fn main() !void {
    var allocator = std.heap.page_allocator;

    var argv = try std.process.argsWithAllocator(allocator);
    defer argv.deinit();

    _ = argv.next();

    const class_path = argv.next() orelse {
        std.debug.print("Usage: zjvm <ClassFilePath>\n", .{});
        return;
    };

    std.debug.print("Loading class file: {s}\n", .{class_path});

    var file = try std.fs.cwd().openFile(class_path, .{ .mode = .read_only });
    defer file.close();

    const file_size = try file.getEndPos();
    const data = try file.readToEndAlloc(allocator, file_size);
    defer allocator.free(data);

    var cursor = utils.Cursor.init(data);
    var classInfo = parser.ClassInfo.init(&allocator);
    defer classInfo.deinit();

    try classInfo.parse(&cursor);

    const json_file_path = "debug/export.json";

    var out = std.Io.Writer.Allocating.init(allocator);
    defer out.deinit();
    //const writer = &out.writer;

    //try std.json.Stringify.value(.{ .id = 1, .name = "test" }, .{}, writer);
    // const obj = try classInfo.toJSON();

    var json_file = try std.fs.cwd().createFile(json_file_path, .{ .truncate = true, .mode = 0o644 });
    defer json_file.close();

    const mMain = try classInfo.getMethod("main");
    try classInfo.dump();

    var vm = try ZJVM.bootstrap(&allocator, 1024);

    if (mMain) |method| {
        if (method.code) |codeAttr| {
            std.debug.print("Starting execution of 'main'...\n", .{});

            var frame = try fr.Frame.init(&allocator, codeAttr, &classInfo);
            try vm.pushFrame(frame);
            var interpreter = try JVMInterpreter.init();
            try interpreter.execute(&vm, &allocator);
            frame.dump();

            // try std.json.Stringify.value(try frame.toJSON(), .{ .whitespace = .indent_1 }, writer);
            // const json_str = out.written();
            // try json_file.writeAll(json_str);

            std.debug.print("Execution of 'main' completed.\n", .{});
        } else {
            std.debug.print("No code attribute found for method 'main'\n", .{});
        }
    }
}
