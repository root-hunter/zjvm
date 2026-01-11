const std = @import("std");
const testing = std.testing;
const Frame = @import("frame.zig").Frame;
const ca = @import("../classfile/code.zig");
const Value = @import("value.zig").Value;
const AttributesInfo = @import("../classfile/attributes.zig").AttributesInfo;

test "Frame - init with CodeAttribute" {
    const allocator = testing.allocator;

    const code = [_]u8{ 0x10, 0x21, 0x3C };
    const codeAttr = ca.CodeAttribute{
        .max_stack = 5,
        .max_locals = 10,
        .code = &code,
        .exception_table = &[_]ca.ExceptionTableEntry{},
        .attributes = &[_]AttributesInfo{},
    };

    const frame = try Frame.init(&allocator, codeAttr);
    defer allocator.free(frame.operand_stack.data);
    defer allocator.free(frame.local_vars.vars);

    try testing.expectEqual(@as(usize, 0), frame.pc);
    try testing.expectEqual(@as(usize, 3), frame.code.len);
    try testing.expectEqual(@as(usize, 5), frame.operand_stack.data.len);
    try testing.expectEqual(@as(usize, 10), frame.local_vars.vars.len);
}

test "Frame - PC starts at zero" {
    const allocator = testing.allocator;

    const code = [_]u8{ 0x01, 0x02 };
    const codeAttr = ca.CodeAttribute{
        .max_stack = 2,
        .max_locals = 2,
        .code = &code,
        .exception_table = &[_]ca.ExceptionTableEntry{},
        .attributes = &[_]AttributesInfo{},
    };

    const frame = try Frame.init(&allocator, codeAttr);
    defer allocator.free(frame.operand_stack.data);
    defer allocator.free(frame.local_vars.vars);

    try testing.expectEqual(@as(usize, 0), frame.pc);
}

test "Frame - local variables initialized to zero" {
    const allocator = testing.allocator;

    const code = [_]u8{0x00};
    const codeAttr = ca.CodeAttribute{
        .max_stack = 1,
        .max_locals = 5,
        .code = &code,
        .exception_table = &[_]ca.ExceptionTableEntry{},
        .attributes = &[_]AttributesInfo{},
    };

    const frame = try Frame.init(&allocator, codeAttr);
    defer allocator.free(frame.operand_stack.data);
    defer allocator.free(frame.local_vars.vars);

    for (frame.local_vars.vars) |v| {
        try testing.expectEqual(@as(i32, 0), v.Int);
    }
}

test "Frame - operand stack starts empty" {
    const allocator = testing.allocator;

    const code = [_]u8{0x00};
    const codeAttr = ca.CodeAttribute{
        .max_stack = 10,
        .max_locals = 1,
        .code = &code,
        .exception_table = &[_]ca.ExceptionTableEntry{},
        .attributes = &[_]AttributesInfo{},
    };

    const frame = try Frame.init(&allocator, codeAttr);
    defer allocator.free(frame.operand_stack.data);
    defer allocator.free(frame.local_vars.vars);

    try testing.expectEqual(@as(usize, 0), frame.operand_stack.top);
}

test "Frame - code reference is correct" {
    const allocator = testing.allocator;

    const code = [_]u8{ 0xAA, 0xBB, 0xCC, 0xDD };
    const codeAttr = ca.CodeAttribute{
        .max_stack = 2,
        .max_locals = 2,
        .code = &code,
        .exception_table = &[_]ca.ExceptionTableEntry{},
        .attributes = &[_]AttributesInfo{},
    };

    const frame = try Frame.init(&allocator, codeAttr);
    defer allocator.free(frame.operand_stack.data);
    defer allocator.free(frame.local_vars.vars);

    try testing.expectEqual(@as(usize, 4), frame.code.len);
    try testing.expectEqual(@as(u8, 0xAA), frame.code[0]);
    try testing.expectEqual(@as(u8, 0xBB), frame.code[1]);
    try testing.expectEqual(@as(u8, 0xCC), frame.code[2]);
    try testing.expectEqual(@as(u8, 0xDD), frame.code[3]);
}
