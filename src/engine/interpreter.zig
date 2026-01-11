const Frame = @import("../runtime/frame.zig").Frame;
const Value = @import("../runtime/value.zig").Value;

pub fn execute(frame: *Frame) !void {
    while (frame.pc < frame.code.len) {
        const opcode = frame.code[frame.pc];
        frame.pc += 1;

        switch (opcode) {
            0x02 => { // iconst_m1
                try frame.operand_stack.push(Value{ .Int = -1 });
            },
            0x03 => { // iconst_0
                try frame.operand_stack.push(Value{ .Int = 0 });
            },
            0x04 => { // iconst_1
                try frame.operand_stack.push(Value{ .Int = 1 });
            },
            0x05 => { // iconst_2
                try frame.operand_stack.push(Value{ .Int = 2 });
            },
            0x06 => { // iconst_3
                try frame.operand_stack.push(Value{ .Int = 3 });
            },
            0x07 => { // iconst_4
                try frame.operand_stack.push(Value{ .Int = 4 });
            },
            0x08 => { // iconst_5
                try frame.operand_stack.push(Value{ .Int = 5 });
            },
            0x10 => { // bipush
                const byte = frame.code[frame.pc];
                frame.pc += 1;
                try frame.operand_stack.push(Value{ .Int = @intCast(@as(i8, byte)) });
            },
            0x60 => { // iadd
                const b = (try frame.operand_stack.pop()).Int;
                const a = (try frame.operand_stack.pop()).Int;
                try frame.operand_stack.push(Value{ .Int = a + b });
            },
            0xac => { // ireturn
                return;
            },
            else => return error.UnsupportedOpcode,
        }
    }
}