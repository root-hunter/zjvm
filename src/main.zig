const std = @import("std");
const parser = @import("classfile/parser.zig");
const ac = @import("classfile/access_flags.zig");
const utils = @import("classfile/utils.zig");

const fr = @import("runtime/frame.zig");

const JVMInterpreter = @import("engine/interpreter.zig").JVMInterpreter;
const ZJVM = @import("engine/vm.zig").ZJVM;

pub fn main() !void {
    const expectedLines = [_][]const u8{ "1024", "Hello, World! My name is ZJVM.", "This is Test Suite 10.", "12.12", "34.56", "7890123456", "1", "90", "" };

    var allocator = std.heap.page_allocator;
    const filePath = "samples/TestSuite10.class";

    var file = try std.fs.cwd().openFile(filePath, .{ .mode = .read_only });
    defer file.close();

    const file_size = try file.getEndPos();
    const data = try file.readToEndAlloc(allocator, file_size);
    defer allocator.free(data);

    var cursor = utils.Cursor.init(data);
    var classInfo = parser.ClassInfo.init(&allocator);
    defer classInfo.deinit();

    try classInfo.parse(&cursor);

    const mMain = try classInfo.getMethod("main");
    var vm = try ZJVM.init(&allocator, 1024);

    // Create outputs directory if it doesn't exist
    const res = std.fs.cwd().makeDir("samples/outputs");

    if (res != error.PathAlreadyExists) {
        try res;
    }

    const logFile = try std.fs.cwd().createFile("samples/outputs/test_suite_10.log", .{ .truncate = true, .read = true });

    if (mMain) |method| {
        if (method.code) |codeAttr| {
            const frame = try fr.Frame.init(&allocator, codeAttr, &classInfo);
            try vm.pushFrame(frame);
            var interpreter = try JVMInterpreter.init(&vm);
            interpreter.setStdout(logFile);
            try interpreter.execute(&allocator);


            const logData = try std.fs.cwd().readFileAlloc(allocator, "samples/outputs/test_suite_10.log", 1024 * 1024);
            defer allocator.free(logData);
            
            var logCursor = utils.Cursor.init(logData);
            var line_index: usize = 0;

            std.debug.print("LogData Len: {}\n", .{logData.len});

            while (logCursor.position < logData.len and line_index < expectedLines.len) : (line_index += 1) {
                const line = try logCursor.readUntilDelimiterOrEof('\n');
                const expected_line = expectedLines[line_index];
                std.debug.print("Expected: '{s}'\n", .{expected_line});
                std.debug.print("Got:      '{s}'\n", .{line});
            }

            std.debug.print("Line size: {}\n", .{line_index});
        }
    }
}
