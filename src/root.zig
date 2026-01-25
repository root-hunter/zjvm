const std = @import("std");

const utils = @import("classfile/utils.zig");
const parser = @import("classfile/parser.zig");
const fr = @import("runtime/frame.zig");
const i = @import("engine/interpreter.zig");
const v = @import("runtime/value.zig");
const ZJVM = @import("engine/vm.zig").ZJVM;

const testing = std.testing;

fn makeTestSuite(filePath: []const u8, expectedValues: []const v.Value) !i.JVMInterpreter {
    var gpa = std.heap.DebugAllocator(.{}){};
    var allocator = gpa.allocator();

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
            return interpreter;
        } else {
            return error.NoCodeAttribute;
        }
    }

    return error.MethodMainNotFound;
}

fn makeTestPrints(filePath: []const u8, logFilePath: []const u8, expectedLines: []const []const u8) !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    var allocator = gpa.allocator();

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

    const res = std.fs.cwd().makeDir("samples/outputs");

    if (res != error.PathAlreadyExists) {
        try res;
    }

    const logFile = try std.fs.cwd().createFile(logFilePath, .{ .truncate = true });

    if (mMain) |method| {
        if (method.code) |codeAttr| {
            const frame = try fr.Frame.init(&allocator, codeAttr, &classInfo);
            try vm.pushFrame(frame);
            var interpreter = try i.JVMInterpreter.init(&vm);
            interpreter.setStdout(logFile);
            try interpreter.execute(&allocator);

            // Compare log file with expected output

            const logData = try std.fs.cwd().readFileAlloc(allocator, logFilePath, 1024 * 1024);
            defer allocator.free(logData);

            var logCursor = utils.Cursor.init(logData);
            var line_index: usize = 0;

            while (logCursor.position < logData.len and line_index < expectedLines.len) : (line_index += 1) {
                const line = try logCursor.readUntilDelimiterOrEof('\n');
                const expected_line = expectedLines[line_index];
                try testing.expectEqualSlices(u8, expected_line, line);
            }

            if (line_index != expectedLines.len) {
                return error.IncorrectNumberOfOutputLines;
            }
        } else {
            return error.NoCodeAttribute;
        }
    } else {
        return error.MethodMainNotFound;
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

    _ = try makeTestSuite(filePath, &expectedValues);
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
    _ = try makeTestSuite(filePath, &expectedValues);
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
    _ = try makeTestSuite(filePath, &expectedValues);
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
    _ = try makeTestSuite(filePath, &expectedValues);
}

test "ZJVM Test Suite 5" {
    const expectedValues = [_]v.Value{
        .{ .Top = {} },
        .{ .Int = 12 },
        .{ .Int = 4 },
        .{ .Int = 20736 },
    };
    const filePath = "samples/TestSuite5.class";
    _ = try makeTestSuite(filePath, &expectedValues);
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
    _ = try makeTestSuite(filePath, &expectedValues);
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
    _ = try makeTestSuite(filePath, &expectedValues);
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
    _ = try makeTestSuite(filePath, &expectedValues);
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
    _ = try makeTestSuite(filePath, &expectedValues);
}

test "ZJVM Test Suite 10 Stdout Tests" {
    const filePath = "samples/TestSuite10.class";
    const logFilePath = "samples/outputs/test_suite_10.log";
    const expectedLines = [_][]const u8{ "1024", "Hello, World! My name is ZJVM.", "This is Test Suite 10.", "12.12", "34.56", "7890123456", "1", "90" };

    try makeTestPrints(filePath, logFilePath, expectedLines[0..]);
}

test "ZJVM Test Suite 11 Stdout Tests" {
    const filePath = "samples/TestSuite11.class";
    const logFilePath = "samples/outputs/test_suite_11.log";
    const expectedLines = [_][]const u8{ "Hello, World! My name is ZJVM.", "1024", "1048576", "This is Test Suite 11.", "C = 1024", "D = 1048576 bytes( 1 MB )", "E = 3.14" };

    try makeTestPrints(filePath, logFilePath, expectedLines[0..]);
}

test "ZJVM Test Suite 12 Stdout Tests" {
    const filePath = "samples/TestSuite12.class";
    const logFilePath = "samples/outputs/test_suite_12.log";
    const expectedLines = [_][]const u8{
        "This is Test Suite 12.",
        "X = 42",
        "Y = 84",
        "Z = 28",
        "A is less than B",
        "P is greater than or equal to Q",
        "Value of Pi: 3.14159",
        "0 is divisible by 15",
        "3 is divisible by 3",
        "5 is divisible by 5",
        "6 is divisible by 3",
        "9 is divisible by 3",
        "10 is divisible by 5",
        "12 is divisible by 3",
        "15 is divisible by 15",
        "18 is divisible by 3",
        "20 is divisible by 5",
        "21 is divisible by 3",
        "24 is divisible by 3",
        "25 is divisible by 5",
        "27 is divisible by 3",
        "30 is divisible by 15",
    };
    try makeTestPrints(filePath, logFilePath, expectedLines[0..]);
}

fn makeTestDoubleArithmetic(filePath: []const u8, expectedValues: []const v.Value) !i.JVMInterpreter {
    var gpa = std.heap.DebugAllocator(.{}){};
    var allocator = gpa.allocator();
    const logFilePath = "samples/outputs/test_suite_13.log";
    const logFile = try std.fs.cwd().createFile(logFilePath, .{ .truncate = true });
    defer logFile.close();

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
            interpreter.setStdout(logFile);
            try interpreter.execute(&allocator);

            try testing.expectEqual(expectedValues.len, frame.local_vars.vars.len);

            var index: usize = 0;

            const deltaFloat = 0.00001;
            const deltaDouble = 0.00000001;
            while (index < frame.local_vars.vars.len and index < expectedValues.len) : (index += 1) {
                switch (expectedValues[index]) {
                    .Top => {
                        const expected = expectedValues[index].Top;
                        const actual = frame.local_vars.get(index).Top;

                        try testing.expectEqual(expected, actual);
                    },
                    .Int => {
                        const expected = expectedValues[index].Int;
                        const actual = frame.local_vars.get(index).Int;
                        try testing.expectEqual(expected, actual);
                    },
                    .Long => {
                        const expected = expectedValues[index].Long;
                        const actual = frame.local_vars.get(index).Long;
                        try testing.expectEqual(expected, actual);
                    },
                    .Float => {
                        const expected = expectedValues[index].Float;
                        const actual = frame.local_vars.get(index).Float;
                        try testing.expect(@abs(expected - actual) < deltaFloat);
                    },
                    .Double => {
                        const expected = expectedValues[index].Double;
                        const actual = frame.local_vars.get(index).Double;
                        try testing.expect(@abs(expected - actual) < deltaDouble);
                    },
                    else => {
                        return error.UnhandledValueTypeInTest;
                    },
                }
            }

            return interpreter;
        } else {
            return error.NoCodeAttribute;
        }
    } else {
        return error.MethodMainNotFound;
    }
}

test "ZJVM Test Suite 13 Long and Float Arithmetic" {
    const expectedValues = [_]v.Value{
        .{ .Top = {} },
        .{ .Long = 1234567890123456789 },
        .{ .Top = {} },
        .{ .Long = 2469135780246913578 },
        .{ .Top = {} },
        .{ .Float = 0.1 },
        .{ .Float = 0.3 },
        .{ .Double = 0.1 },
        .{ .Top = {} },
        .{ .Double = 0.3 },
        .{ .Top = {} },
    };
    const filePath = "samples/TestSuite13.class";

    _ = try makeTestDoubleArithmetic(filePath, &expectedValues);
}

// Import all test files to include them in the test suite
test {
    _ = @import("runtime/value_test.zig");
    _ = @import("runtime/operand_stack_test.zig");
    _ = @import("runtime/local_vars_test.zig");
    _ = @import("engine/opcode_test.zig");
}
