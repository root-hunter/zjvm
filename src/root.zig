const std = @import("std");

const utils = @import("utils.zig");
const parser = @import("vm/class/parser.zig");
const fr = @import("vm/interpreter/frame.zig");
const i = @import("vm/interpreter/exec.zig");
const v = @import("vm/interpreter/value.zig");
const ZJVM = @import("vm/vm.zig").ZJVM;
const ZJVMGPA = @import("vm/vm.zig").ZJVMGPA;

const testing = std.testing;

fn makeTestSuite(className: []const u8, filePath: []const u8, expectedValues: []const v.Value) !void {
    var gpa = ZJVMGPA{};

    var vm = try ZJVM.bootstrap(&gpa, 1024);

    try vm.loadClassFromFile(filePath);
    var frame = try vm.execClassMethodReturnFrame(className, "main");
    try testing.expectEqual(expectedValues.len, frame.local_vars.vars.len);

    var index: usize = 0;
    while (index < frame.local_vars.vars.len and index < expectedValues.len) : (index += 1) {
        try testing.expectEqual(expectedValues[index], frame.local_vars.get(index));
    }
}

fn makeTestPrints(className: []const u8, filePath: []const u8, logFilePath: []const u8, expectedLines: []const []const u8) !void {
    var gpa = ZJVMGPA{};
    const allocator = gpa.allocator();

    const logFile = try std.fs.cwd().createFile(logFilePath, .{ .truncate = true });
    defer logFile.close();

    var vm = try ZJVM.bootstrap(&gpa, 1024);
    vm.setStdout(logFile);

    try vm.loadClassFromFile(filePath);
    try vm.execClassMethod(className, "main");

    const res = std.fs.cwd().makeDir("examples/outputs");

    if (res != error.PathAlreadyExists) {
        try res;
    }

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
    const filePath = "examples/tests/TestSuite1.class";

    try makeTestSuite("TestSuite1", filePath, &expectedValues);
}

test "ZJVM Test Suite 2" {
    const expectedValues = [_]v.Value{
        .{ .Top = {} },
        .{ .Int = 5 },
        .{ .Int = 10 },
        .{ .Int = 50 },
        .{ .Int = 80 },
    };
    const filePath = "examples/tests/TestSuite2.class";
    try makeTestSuite("TestSuite2", filePath, &expectedValues);
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
    const filePath = "examples/tests/TestSuite3.class";
    try makeTestSuite("TestSuite3", filePath, &expectedValues);
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
    const filePath = "examples/tests/TestSuite4.class";
    try makeTestSuite("TestSuite4", filePath, &expectedValues);
}

test "ZJVM Test Suite 5" {
    const expectedValues = [_]v.Value{
        .{ .Top = {} },
        .{ .Int = 12 },
        .{ .Int = 4 },
        .{ .Int = 20736 },
    };
    const filePath = "examples/tests/TestSuite5.class";
    try makeTestSuite("TestSuite5", filePath, &expectedValues);
}

test "ZJVM Test Suite 6" {
    const expectedValues = [_]v.Value{
        .{ .Top = {} },
        .{ .Int = 12 },
        .{ .Int = 10000 },
        .{ .Int = 50135000 },
        .{ .Int = 5013 },
    };
    const filePath = "examples/tests/TestSuite6.class";
    try makeTestSuite("TestSuite6", filePath, &expectedValues);
}

test "ZJVM Test Suite 7" {
    const expectedValues = [_]v.Value{
        .{ .Top = {} },
        .{ .Int = 5 },
        .{ .Int = 20 },
        .{ .Int = 830 },
        .{ .Int = 41 },
    };
    const filePath = "examples/tests/TestSuite7.class";
    try makeTestSuite("TestSuite7", filePath, &expectedValues);
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
    const filePath = "examples/tests/TestSuite8.class";
    try makeTestSuite("TestSuite8", filePath, &expectedValues);
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
    const filePath = "examples/tests/TestSuite9.class";
    try makeTestSuite("TestSuite9", filePath, &expectedValues);
}

test "ZJVM Test Suite 10 Stdout Tests" {
    const filePath = "examples/tests/TestSuite10.class";
    const logFilePath = "examples/outputs/test_suite_10.log";
    const expectedLines = [_][]const u8{ "1024", "Hello, World! My name is ZJVM.", "This is Test Suite 10.", "12.12", "34.56", "7890123456", "1", "90" };

    try makeTestPrints("TestSuite10", filePath, logFilePath, expectedLines[0..]);
}

test "ZJVM Test Suite 11 Stdout Tests" {
    const filePath = "examples/tests/TestSuite11.class";
    const logFilePath = "examples/outputs/test_suite_11.log";
    const expectedLines = [_][]const u8{ "Hello, World! My name is ZJVM.", "1024", "1048576", "This is Test Suite 11.", "C = 1024", "D = 1048576 bytes( 1 MB )", "E = 3.14" };

    try makeTestPrints("TestSuite11", filePath, logFilePath, expectedLines[0..]);
}

test "ZJVM Test Suite 12 Stdout Tests" {
    const filePath = "examples/tests/TestSuite12.class";
    const logFilePath = "examples/outputs/test_suite_12.log";
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
    try makeTestPrints("TestSuite12", filePath, logFilePath, expectedLines[0..]);
}

fn makeTestDoubleArithmetic(className: []const u8, filePath: []const u8, expectedValues: []const v.Value, logFilePath: []const u8) !void {
    var gpa = ZJVMGPA{};

    const logFile = try std.fs.cwd().createFile(logFilePath, .{ .truncate = true });
    defer logFile.close();

    var vm = try ZJVM.bootstrap(&gpa, 1024);
    vm.setStdout(logFile);

    try vm.loadClassFromFile(filePath);
    var frame = try vm.execClassMethodReturnFrame(className, "main");

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

    return;
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
    const logFilePath = "examples/outputs/test_suite_13.log";
    const filePath = "examples/tests/TestSuite13.class";

    try makeTestDoubleArithmetic("TestSuite13", filePath, &expectedValues, logFilePath);
}
