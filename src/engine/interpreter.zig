const std = @import("std");
const Frame = @import("../runtime/frame.zig").Frame;
const Value = @import("../runtime/value.zig").Value;
const OpcodeEnum = @import("opcode.zig").OpcodeEnum;

pub const JVMInterpreter = struct {
    pub fn execute(frame: *Frame) !void {
        while (frame.pc < frame.code.len) {
            const result = std.meta.intToEnum(OpcodeEnum, frame.code[frame.pc]);

            if (result == error.InvalidEnumTag) {
                std.debug.print("Invalid opcode 0x{x} at pc {d}\n", .{ frame.code[frame.pc], frame.pc });
                return error.InvalidOpcode;
            }

            const opcode: OpcodeEnum = @enumFromInt(frame.code[frame.pc]);

            switch (opcode) {
                OpcodeEnum.IConstM1 => { // iconst_m1
                    try frame.operand_stack.push(Value{ .Int = -1 });
                    frame.pc += opcode.getOperandLength();
                },
                OpcodeEnum.IConst0 => { // iconst_0
                    try frame.operand_stack.push(Value{ .Int = 0 });
                    frame.pc += opcode.getOperandLength();
                },
                OpcodeEnum.IConst1 => { // iconst_1
                    try frame.operand_stack.push(Value{ .Int = 1 });
                    frame.pc += opcode.getOperandLength();
                },
                OpcodeEnum.IConst2 => { // iconst_2
                    try frame.operand_stack.push(Value{ .Int = 2 });
                    frame.pc += opcode.getOperandLength();
                },
                OpcodeEnum.IConst3 => { // iconst_3
                    try frame.operand_stack.push(Value{ .Int = 3 });
                    frame.pc += opcode.getOperandLength();
                },
                OpcodeEnum.IConst4 => { // iconst_4
                    try frame.operand_stack.push(Value{ .Int = 4 });
                    frame.pc += opcode.getOperandLength();
                },
                OpcodeEnum.IConst5 => { // iconst_5
                    try frame.operand_stack.push(Value{ .Int = 5 });
                    frame.pc += opcode.getOperandLength();
                },
                OpcodeEnum.BiPush => {
                    const byte = frame.code[frame.pc + 1]; // il byte seguente
                    const value: i32 = @intCast(byte); // bipush è signed 8-bit
                    try frame.operand_stack.push(Value{ .Int = value });
                    frame.pc += opcode.getOperandLength();
                },
                OpcodeEnum.ILoad1 => { // iload_1
                    const value = frame.local_vars.vars[1];
                    try frame.operand_stack.push(value);
                    frame.pc += opcode.getOperandLength();
                },
                OpcodeEnum.ILoad2 => { // iload_2
                    const value = frame.local_vars.vars[2];
                    try frame.operand_stack.push(value);
                    frame.pc += opcode.getOperandLength();
                },
                OpcodeEnum.ILoad3 => { // iload_3
                    const value = frame.local_vars.vars[3];
                    try frame.operand_stack.push(value);
                    frame.pc += opcode.getOperandLength();
                },
                OpcodeEnum.ISub => { // isub
                    const b = (try frame.operand_stack.pop()).Int;
                    const a = (try frame.operand_stack.pop()).Int;
                    try frame.operand_stack.push(Value{ .Int = a - b });
                    frame.pc += opcode.getOperandLength();
                },
                OpcodeEnum.LLoad3 => { // lload_3
                    const value = frame.local_vars.vars[3];
                    try frame.operand_stack.push(value);
                    frame.pc += opcode.getOperandLength();
                },
                OpcodeEnum.AALoad => { // aaload
                    const index_value = try frame.operand_stack.pop();
                    const arrayref_value = try frame.operand_stack.pop();

                    const arrayref = arrayref_value.ArrayRef;

                    if (arrayref == null) {
                        return error.NullPointerException;
                    }

                    const index: usize = @intCast(index_value.Int);

                    const element = arrayref.?.*[index];
                    try frame.operand_stack.push(element);
                    frame.pc += 1;
                },
                OpcodeEnum.IStore => { // istore
                    const index_byte = frame.code[frame.pc + 1];
                    const index: usize = @intCast(index_byte);
                    const value = try frame.operand_stack.pop();
                    frame.local_vars.vars[index] = value;
                    frame.pc += opcode.getOperandLength();
                },
                OpcodeEnum.IStore1 => { // istore_1
                    const value = try frame.operand_stack.pop();
                    frame.local_vars.vars[1] = value;
                    frame.pc += opcode.getOperandLength();
                },
                OpcodeEnum.IStore2 => { // istore_2
                    const value = try frame.operand_stack.pop();
                    frame.local_vars.vars[2] = value;
                    frame.pc += opcode.getOperandLength();
                },
                OpcodeEnum.IStore3 => { // istore_3
                    const value = try frame.operand_stack.pop();
                    frame.local_vars.vars[3] = value;
                    frame.pc += opcode.getOperandLength();
                },
                OpcodeEnum.IAdd => { // iadd
                    const b = (try frame.operand_stack.pop()).Int;
                    const a = (try frame.operand_stack.pop()).Int;
                    try frame.operand_stack.push(Value{ .Int = a + b });
                    frame.pc += opcode.getOperandLength();
                },
                OpcodeEnum.IReturn => {
                    _ = try frame.operand_stack.pop(); // consumi il valore da restituire
                    return;
                },
                OpcodeEnum.Return => { // return
                    return;
                },
            }

            frame.dump();
        }
    }
};
