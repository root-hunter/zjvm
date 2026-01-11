const std = @import("std");
const testing = std.testing;
const OpcodeEnum = @import("opcode.zig").OpcodeEnum;

test "Opcode - basic opcodes" {
    try testing.expectEqual(@as(u8, 0xB1), @intFromEnum(OpcodeEnum.Return));
}

test "Opcode - iconst opcodes" {
    try testing.expectEqual(@as(u8, 0x02), @intFromEnum(OpcodeEnum.IConstM1));
    try testing.expectEqual(@as(u8, 0x03), @intFromEnum(OpcodeEnum.IConst0));
    try testing.expectEqual(@as(u8, 0x04), @intFromEnum(OpcodeEnum.IConst1));
    try testing.expectEqual(@as(u8, 0x05), @intFromEnum(OpcodeEnum.IConst2));
    try testing.expectEqual(@as(u8, 0x06), @intFromEnum(OpcodeEnum.IConst3));
    try testing.expectEqual(@as(u8, 0x07), @intFromEnum(OpcodeEnum.IConst4));
    try testing.expectEqual(@as(u8, 0x08), @intFromEnum(OpcodeEnum.IConst5));
}

test "Opcode - iload opcodes" {
    try testing.expectEqual(@as(u8, 0x15), @intFromEnum(OpcodeEnum.ILoad));
    try testing.expectEqual(@as(u8, 0x1B), @intFromEnum(OpcodeEnum.ILoad1));
    try testing.expectEqual(@as(u8, 0x1C), @intFromEnum(OpcodeEnum.ILoad2));
    try testing.expectEqual(@as(u8, 0x1D), @intFromEnum(OpcodeEnum.ILoad3));
}

test "Opcode - istore opcodes" {
    try testing.expectEqual(@as(u8, 0x36), @intFromEnum(OpcodeEnum.IStore));
    try testing.expectEqual(@as(u8, 0x3C), @intFromEnum(OpcodeEnum.IStore1));
    try testing.expectEqual(@as(u8, 0x3D), @intFromEnum(OpcodeEnum.IStore2));
    try testing.expectEqual(@as(u8, 0x3E), @intFromEnum(OpcodeEnum.IStore3));
}

test "Opcode - arithmetic opcodes" {
    try testing.expectEqual(@as(u8, 0x60), @intFromEnum(OpcodeEnum.IAdd));
    try testing.expectEqual(@as(u8, 0x64), @intFromEnum(OpcodeEnum.ISub));
}

test "Opcode - bipush" {
    try testing.expectEqual(@as(u8, 0x10), @intFromEnum(OpcodeEnum.BiPush));
}

test "Opcode - from byte conversion" {
    const op: OpcodeEnum = @enumFromInt(0x10);
    try testing.expectEqual(OpcodeEnum.BiPush, op);

    const op2: OpcodeEnum = @enumFromInt(0x60);
    try testing.expectEqual(OpcodeEnum.IAdd, op2);

    const op3: OpcodeEnum = @enumFromInt(0xB1);
    try testing.expectEqual(OpcodeEnum.Return, op3);
}
