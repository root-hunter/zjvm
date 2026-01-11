const std = @import("std");
const Frame = @import("../runtime/frame.zig").Frame;
const Value = @import("../runtime/value.zig").Value;
const OpcodeEnum = @import("opcode.zig").OpcodeEnum;
const ZJVM = @import("../engine/vm.zig").ZJVM;

pub const JVMInterpreter = struct {
    pub fn execute(allocator: *const std.mem.Allocator, vm: *ZJVM) !void {
        while (true) {
            const frame = vm.currentFrame() orelse return error.NoFrame;

            if (frame.pc >= frame.code.len) {
                _ = try vm.popFrame();
                if (vm.stack.top == 0) break;
                continue;
            }

            const result = std.meta.intToEnum(OpcodeEnum, frame.code[frame.pc]);

            if (result == error.InvalidEnumTag) {
                std.debug.print("Invalid opcode 0x{x} at pc {d}\n", .{ frame.code[frame.pc], frame.pc });
                return error.InvalidOpcode;
            }

            const opcode: OpcodeEnum = @enumFromInt(frame.code[frame.pc]);

            switch (opcode) {
                OpcodeEnum.Nop => {
                    // Do nothing
                },
                OpcodeEnum.FConts2 => { // fconst_2
                    try frame.operand_stack.push(Value{ .Float = 2.0 });
                },
                OpcodeEnum.DConst0 => { // dconst_0
                    try frame.operand_stack.push(Value{ .Double = 0.0 });
                },
                OpcodeEnum.IConstM1 => { // iconst_m1
                    try frame.operand_stack.push(Value{ .Int = -1 });
                },
                OpcodeEnum.IConst0 => { // iconst_0
                    try frame.operand_stack.push(Value{ .Int = 0 });
                },
                OpcodeEnum.IConst1 => { // iconst_1
                    try frame.operand_stack.push(Value{ .Int = 1 });
                },
                OpcodeEnum.IConst2 => { // iconst_2
                    try frame.operand_stack.push(Value{ .Int = 2 });
                },
                OpcodeEnum.IConst3 => { // iconst_3
                    try frame.operand_stack.push(Value{ .Int = 3 });
                },
                OpcodeEnum.IConst4 => { // iconst_4
                    try frame.operand_stack.push(Value{ .Int = 4 });
                },
                OpcodeEnum.IConst5 => { // iconst_5
                    try frame.operand_stack.push(Value{ .Int = 5 });
                },
                OpcodeEnum.BiPush => {
                    const byte = frame.code[frame.pc + 1]; // il byte seguente
                    const value: i32 = @intCast(byte); // bipush è signed 8-bit
                    try frame.operand_stack.push(Value{ .Int = value });
                },
                OpcodeEnum.SiPush => {
                    const high_byte = frame.code[frame.pc + 1];
                    const low_byte = frame.code[frame.pc + 2];

                    const high: i16 = @intCast(high_byte);
                    const low: i16 = @intCast(low_byte);

                    const combined: i16 = (high << 8) | low;
                    const value: i32 = @intCast(combined);

                    try frame.operand_stack.push(Value{ .Int = value });
                },
                OpcodeEnum.ILoad => { // iload
                    const index_byte = frame.code[frame.pc + 1];
                    const index: usize = @intCast(index_byte);
                    const value = frame.local_vars.vars[index];
                    try frame.operand_stack.push(value);
                },
                OpcodeEnum.ILoad0 => { // iload_0
                    const value = frame.local_vars.vars[0];
                    try frame.operand_stack.push(value);
                },
                OpcodeEnum.ILoad1 => { // iload_1
                    const value = frame.local_vars.vars[1];
                    try frame.operand_stack.push(value);
                },
                OpcodeEnum.ILoad2 => { // iload_2
                    const value = frame.local_vars.vars[2];
                    try frame.operand_stack.push(value);
                },
                OpcodeEnum.ILoad3 => { // iload_3
                    const value = frame.local_vars.vars[3];
                    try frame.operand_stack.push(value);
                },
                OpcodeEnum.ISub => { // isub
                    const b = (try frame.operand_stack.pop()).Int;
                    const a = (try frame.operand_stack.pop()).Int;
                    try frame.operand_stack.push(Value{ .Int = a - b });
                },
                OpcodeEnum.LLoad3 => { // lload_3
                    const value = frame.local_vars.vars[3];
                    try frame.operand_stack.push(value);
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
                },
                OpcodeEnum.IStore => { // istore
                    const index_byte = frame.code[frame.pc + 1];
                    const index: usize = @intCast(index_byte);
                    const value = try frame.operand_stack.pop();
                    frame.local_vars.vars[index] = value;
                },
                OpcodeEnum.IStore0 => { // istore_0
                    const value = try frame.operand_stack.pop();
                    frame.local_vars.vars[0] = value;
                },
                OpcodeEnum.IStore1 => { // istore_1
                    const value = try frame.operand_stack.pop();
                    frame.local_vars.vars[1] = value;
                },
                OpcodeEnum.IStore2 => { // istore_2
                    const value = try frame.operand_stack.pop();
                    frame.local_vars.vars[2] = value;
                },
                OpcodeEnum.IStore3 => { // istore_3
                    const value = try frame.operand_stack.pop();
                    frame.local_vars.vars[3] = value;
                },
                OpcodeEnum.IAdd => { // iadd
                    const b = (try frame.operand_stack.pop()).Int;
                    const a = (try frame.operand_stack.pop()).Int;
                    try frame.operand_stack.push(Value{ .Int = a + b });
                },
                OpcodeEnum.IMul => { // imul
                    const b = (try frame.operand_stack.pop()).Int;
                    const a = (try frame.operand_stack.pop()).Int;
                    try frame.operand_stack.push(Value{ .Int = a * b });
                },
                OpcodeEnum.IDiv => { // idiv
                    const b = (try frame.operand_stack.pop()).Int;
                    const a = (try frame.operand_stack.pop()).Int;
                    if (b == 0) {
                        return error.ArithmeticException;
                    }
                    try frame.operand_stack.push(Value{ .Int = @divFloor(a, b) });
                },
                OpcodeEnum.IRem => { // irem
                    const b = (try frame.operand_stack.pop()).Int;
                    const a = (try frame.operand_stack.pop()).Int;
                    if (b == 0) {
                        return error.ArithmeticException;
                    }
                    try frame.operand_stack.push(Value{ .Int = @rem(a, b) });
                },
                OpcodeEnum.IInc => { // iinc
                    const index_byte = frame.code[frame.pc + 1];
                    const const_byte = frame.code[frame.pc + 2];

                    const index: usize = @intCast(index_byte);
                    const increment: i32 = @intCast(const_byte);

                    var current_value = frame.local_vars.vars[index].Int;
                    current_value += increment;
                    frame.local_vars.vars[index] = Value{ .Int = current_value };
                },
                OpcodeEnum.IfCmpGe => { // if_icmpge
                    const value2 = try frame.operand_stack.pop();
                    const value1 = try frame.operand_stack.pop();

                    const offset_high = frame.code[frame.pc + 1];
                    const offset_low = frame.code[frame.pc + 2];

                    const high: i16 = @intCast(offset_high);
                    const low: i16 = @intCast(offset_low);

                    const branch_offset: i16 = (high << 8) | low;

                    if (value1.Int >= value2.Int) {
                        const b: i32 = @intCast(frame.pc);
                        frame.pc = @intCast(b + branch_offset);
                        continue;
                    }
                },
                OpcodeEnum.IfCmpGt => { // if_icmpgt
                    const value2 = try frame.operand_stack.pop();
                    const value1 = try frame.operand_stack.pop();

                    const offset_high = frame.code[frame.pc + 1];
                    const offset_low = frame.code[frame.pc + 2];

                    const high: i16 = @intCast(offset_high);
                    const low: i16 = @intCast(offset_low);

                    const branch_offset: i16 = (high << 8) | low;

                    if (value1.Int > value2.Int) {
                        const b: i32 = @intCast(frame.pc);
                        frame.pc = @intCast(b + branch_offset);
                        continue;
                    }
                },
                OpcodeEnum.IfCmpLe => { // if_icmple
                    const value2 = try frame.operand_stack.pop();
                    const value1 = try frame.operand_stack.pop();

                    const offset_high = frame.code[frame.pc + 1];
                    const offset_low = frame.code[frame.pc + 2];

                    const high: i16 = @intCast(offset_high);
                    const low: i16 = @intCast(offset_low);

                    const branch_offset: i16 = (high << 8) | low;

                    if (value1.Int <= value2.Int) {
                        const b: i32 = @intCast(frame.pc);
                        frame.pc = @intCast(b + branch_offset);
                        continue;
                    }
                },
                OpcodeEnum.InvokeStatic => {
                    const index_high = frame.code[frame.pc + 1];
                    const index_low = frame.code[frame.pc + 2];

                    const method_index: u16 =
                        (@as(u16, index_high) << 8) | @as(u16, index_low);

                    const method_name = try frame.class.getConstant(method_index);
                    const method = try frame.class.getMethod(method_name) orelse return error.MethodNotFound;

                    const codeAttr = method.code orelse return error.NoCodeAttribute;

                    frame.pc += opcode.getOperandLength();

                    var new_frame = try Frame.init(allocator, codeAttr, frame.class);

                    for (0..method.num_params) |i| {
                        const arg = try frame.operand_stack.pop();
                        new_frame.local_vars.vars[method.num_params - 1 - i] = arg;
                    }

                    try vm.pushFrame(new_frame);
                    continue;
                },
                OpcodeEnum.GoTo => {
                    const offset_high = frame.code[frame.pc + 1];
                    const offset_low = frame.code[frame.pc + 2];

                    const branch_offset: i16 =
                        (@as(i16, offset_high) << 8) | @as(i16, offset_low);

                    const pc_i32: i32 = @intCast(frame.pc);
                    frame.pc = @intCast(pc_i32 + branch_offset);
                    continue;
                },
                OpcodeEnum.IReturn => {
                    const return_value = try frame.operand_stack.pop();

                    _ = try vm.stack.pop();

                    if (vm.stack.top == 0) {
                        break;
                    }

                    var caller = vm.stack.current();
                    try caller.operand_stack.push(return_value);

                    continue;
                },
                OpcodeEnum.Return => { // return
                    _ = try vm.stack.pop();
                    return;
                },
            }

            frame.pc += opcode.getOperandLength();
        }
    }
};
