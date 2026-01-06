const Frame = @import("../runtime/frame.zig").Frame;
const Value = @import("../runtime/value.zig").Value;

pub fn execute(frame: *Frame) !void {
    while (frame.pc < frame.code.len) {
        const opcode = frame.code[frame.pc];
        frame.pc += 1;

        switch (opcode) {
            0x03 => { // iconst_0
                try frame.operand_stack.push(Value{ .Int = 0 });
            },
            0x04 => { // iconst_1
                try frame.operand_stack.push(Value{ .Int = 1 });
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