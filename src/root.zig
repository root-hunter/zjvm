//! By convention, root.zig is the root source file when making a library.

test "ZJVM Test Suite 1" {
    const std = @import("std");

    const utils = @import("classfile/utils.zig");
    const parser = @import("classfile/parser.zig");
    const fr = @import("runtime/frame.zig");
    const i = @import("engine/interpreter.zig");
    const v = @import("runtime/value.zig");

    const testing = std.testing;

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

    if (mMain) |method| {
        if (method.code) |codeAttr| {
            var frame = try fr.Frame.init(&allocator, codeAttr);
            try i.JVMInterpreter.execute(&frame);

            const expectedValues = [_]v.Value{
                .{ .Int = 0 },
                .{ .Int = 33 },
                .{ .Int = 100 },
                .{ .Int = 83 },
                .{ .Int = 203 },
                .{ .Int = 403 },
                .{ .Int = 799 },
            };

            var index: usize = 0;
            while (index < frame.local_vars.vars.len and index < expectedValues.len) : (index += 1) {
                try testing.expectEqual(expectedValues[index], frame.local_vars.get(index));
            }
        } else {
            // try testing.expect(false, "No code attribute found for method 'main'");
        }
    }
}

// Import all test files to include them in the test suite
test {
    _ = @import("runtime/value_test.zig");
    _ = @import("runtime/operand_stack_test.zig");
    _ = @import("runtime/local_vars_test.zig");
    _ = @import("runtime/frame_test.zig");
    _ = @import("engine/opcode_test.zig");
}
