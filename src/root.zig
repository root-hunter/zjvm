const std = @import("std");

const utils = @import("classfile/utils.zig");
const parser = @import("classfile/parser.zig");
const fr = @import("runtime/frame.zig");
const i = @import("engine/interpreter.zig");
const v = @import("runtime/value.zig");
const ZJVM = @import("engine/vm.zig").ZJVM;

const testing = std.testing;

fn makeTestSuite(filePath: []const u8, expectedValues: []const v.Value) !void {
    var allocator = std.heap.page_allocator;

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

    if (mMain) |method| {
        if (method.code) |codeAttr| {
            var frame = try fr.Frame.init(&allocator, codeAttr, &classInfo);
            try vm.pushFrame(frame);
            var interpreter = try i.JVMInterpreter.init(&vm);
            try interpreter.execute(&allocator);

            try testing.expectEqual(expectedValues.len, frame.local_vars.vars.len);

            var index: usize = 0;
            while (index < frame.local_vars.vars.len and index < expectedValues.len) : (index += 1) {
                try testing.expectEqual(expectedValues[index], frame.local_vars.get(index));
            }
        } else {
            // try testing.expect(false, "No code attribute found for method 'main'");
        }
    }
}

test "ZJVM Test Suite 1" {
    const expectedValues = [_]v.Value{
        .{ .Top = {} },
        .{ .Int = 33 },
        .{ .Int = 100 },
        .{ .Int = 83 },
        .{ .Int = 203 },
        .{ .Int = 403 },
        .{ .Int = 799 },
    };
    const filePath = "samples/TestSuite1.class";

    try makeTestSuite(filePath, &expectedValues);
}

test "ZJVM Test Suite 2" {
    const expectedValues = [_]v.Value{
        .{ .Top = {} },
        .{ .Int = 5 },
        .{ .Int = 10 },
        .{ .Int = 50 },
        .{ .Int = 80 },
    };
    const filePath = "samples/TestSuite2.class";
    try makeTestSuite(filePath, &expectedValues);
}

test "ZJVM Test Suite 3" {
    const expectedValues = [_]v.Value{
        .{ .Top = {} },
        .{ .Int = 10 },
        .{ .Int = 5 },
        .{ .Int = 2 },
        .{ .Int = 32 },
        .{ .Int = 0 },
    };
    const filePath = "samples/TestSuite3.class";
    try makeTestSuite(filePath, &expectedValues);
}

test "ZJVM Test Suite 4" {
    const expectedValues = [_]v.Value{
        .{ .Top = {} },
        .{ .Int = 3200 },
        .{ .Int = 8 },
        .{ .Int = 25600 },
        .{ .Int = 2000 },
        .{ .Int = 4 },
        .{ .Int = 500 },
        .{ .Int = 24100 },
    };
    const filePath = "samples/TestSuite4.class";
    try makeTestSuite(filePath, &expectedValues);
}

test "ZJVM Test Suite 5" {
    const expectedValues = [_]v.Value{
        .{ .Top = {} },
        .{ .Int = 12 },
        .{ .Int = 4 },
        .{ .Int = 20736 },
    };
    const filePath = "samples/TestSuite5.class";
    try makeTestSuite(filePath, &expectedValues);
}

test "ZJVM Test Suite 6" {
    const expectedValues = [_]v.Value{
        .{ .Top = {} },
        .{ .Int = 12 },
        .{ .Int = 10000 },
        .{ .Int = 50135000 },
        .{ .Int = 5013 },
    };
    const filePath = "samples/TestSuite6.class";
    try makeTestSuite(filePath, &expectedValues);
}

test "ZJVM Test Suite 7" {
    const expectedValues = [_]v.Value{
        .{ .Top = {} },
        .{ .Int = 5 },
        .{ .Int = 20 },
        .{ .Int = 830 },
        .{ .Int = 41 },
    };
    const filePath = "samples/TestSuite7.class";
    try makeTestSuite(filePath, &expectedValues);
}

test "ZJVM Test Suite 8 (Fibonacci - Recursion)" {
    const expectedValues = [_]v.Value{
        .{ .Top = {} },
        .{ .Int = 5 },
        .{ .Int = 5 },
        .{ .Int = 10 },
        .{ .Int = 55 },
        .{ .Int = 15 },
        .{ .Int = 610 },
        .{ .Int = 20 },
        .{ .Int = 6765 },
    };
    const filePath = "samples/TestSuite8.class";
    try makeTestSuite(filePath, &expectedValues);
}

test "ZJVM Test Suite 9 Double Arithmetic" {
    const expectedValues = [_]v.Value{
        .{ .Top = {} },
        .{ .Double = 5 },
        .{ .Top = {} },
        .{ .Double = 5.5 },
        .{ .Top = {} },
        .{ .Int = 10 },
        .{ .Double = 10.5 },
        .{ .Top = {} },
        .{ .Double = 10 },
        .{ .Top = {} },
        .{ .Double = 20 },
        .{ .Top = {} },
        .{ .Double = 5 },
        .{ .Top = {} },
    };
    const filePath = "samples/TestSuite9.class";
    try makeTestSuite(filePath, &expectedValues);
}

// Import all test files to include them in the test suite
test {
    _ = @import("runtime/value_test.zig");
    _ = @import("runtime/operand_stack_test.zig");
    _ = @import("runtime/local_vars_test.zig");
    _ = @import("engine/opcode_test.zig");
}
