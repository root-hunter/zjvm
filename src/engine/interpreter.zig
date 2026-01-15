const std = @import("std");
const Frame = @import("../runtime/frame.zig").Frame;
const Value = @import("../runtime/value.zig").Value;
const OpcodeEnum = @import("opcode.zig").OpcodeEnum;
const ZJVM = @import("../engine/vm.zig").ZJVM;
const Code = @import("../classfile/code.zig").CodeAttribute;
const StdFunction = @import("../classfile/code.zig").StdFunction;
const AttributesInfo = @import("../classfile/attributes.zig").AttributesInfo;
const ExceptionTableEntry = @import("../classfile/code.zig").ExceptionTableEntry;

pub const JVMInterpreter = struct {
    pub fn execute(allocator: *const std.mem.Allocator, vm: *ZJVM) !void {
        while (true) {
            const frame = vm.currentFrame() orelse return error.NoFrame;

            if (frame.pc >= frame.getCodeLength()) {
                _ = try vm.popFrame();
                if (vm.stack.top == 0) break;
                continue;
            }

            const result = std.meta.intToEnum(OpcodeEnum, frame.getCodeByte(frame.pc));

            if (result == error.InvalidEnumTag) {
                std.debug.print("Invalid opcode 0x{x} at pc {d}\n", .{ frame.getCodeByte(frame.pc), frame.pc });
                return error.InvalidOpcode;
            }

            const opcode: OpcodeEnum = @enumFromInt(frame.getCodeByte(frame.pc));
            switch (opcode) {
                OpcodeEnum.Nop => {
                    // Do nothing
                },
                OpcodeEnum.FConts2 => { // fconst_2
                    try frame.operand_stack.push(Value{ .Float = 2.0 });
                },
                OpcodeEnum.DConst0 => { // dconst_0
                    try frame.operand_stack.pushDouble(0.0);
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
                    const byte = frame.getCodeByte(frame.pc + 1); // il byte seguente
                    const value: i32 = @intCast(byte); // bipush è signed 8-bit
                    try frame.operand_stack.push(Value{ .Int = value });
                },
                OpcodeEnum.SiPush => {
                    const high_byte = frame.getCodeByte(frame.pc + 1);
                    const low_byte = frame.getCodeByte(frame.pc + 2);

                    const high: i16 = @intCast(high_byte);
                    const low: i16 = @intCast(low_byte);

                    const combined: i16 = (high << 8) | low;
                    const value: i32 = @intCast(combined);

                    try frame.operand_stack.push(Value{ .Int = value });
                },
                OpcodeEnum.LDC => {
                    const index_byte = frame.getCodeByte(frame.pc + 1);
                    const index: u16 = @as(u16, index_byte);

                    const entry = try frame.class.getCpEntry(index);

                    switch (entry) {
                        .Integer => |int_value| {
                            try frame.operand_stack.push(Value{ .Int = int_value });
                        },
                        .Float => |float_value| {
                            try frame.operand_stack.push(Value{ .Float = float_value });
                        },
                        .String => |string_value| {
                            // For now, we will push the reference as a usize pointer
                            const str_ptr = @intFromPtr(&string_value);
                            try frame.operand_stack.push(Value{ .Reference = str_ptr });
                        },
                        else => {
                            return error.InvalidConstantType;
                        },
                    }
                },
                OpcodeEnum.LDC2_W => {
                    const index_high = @as(u16, frame.getCodeByte(frame.pc + 1));
                    const index_low = @as(u16, frame.getCodeByte(frame.pc + 2));

                    const index: u16 = (index_high << 8) | index_low;

                    const entry = try frame.class.getCpEntry(index);

                    switch (entry) {
                        .Long => |long_value| {
                            try frame.operand_stack.pushLong(long_value);
                        },
                        .Double => |double_value| {
                            try frame.operand_stack.pushDouble(double_value);
                        },
                        else => {
                            return error.InvalidConstantType;
                        },
                    }
                },
                OpcodeEnum.ILoad => { // iload
                    const index_byte = frame.getCodeByte(frame.pc + 1);
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
                OpcodeEnum.LLoad3 => { // lload_3
                    const value = frame.local_vars.vars[3];
                    try frame.operand_stack.push(value);
                },
                OpcodeEnum.DLoad => { // dload
                    const index: usize = @intCast(frame.getCodeByte(frame.pc + 1));
                    const v = frame.local_vars.vars[index];

                    switch (v) {
                        .Double => |d| {
                            // skip Top slot implicitly
                            try frame.operand_stack.pushDouble(d);
                        },
                        else => return error.TypeMismatch,
                    }
                },
                OpcodeEnum.DLoad1 => { // dload_1
                    const value = frame.local_vars.vars[1];
                    try frame.operand_stack.pushDouble(value.Double);
                },
                OpcodeEnum.DLoad3 => { // dload_3
                    const value = frame.local_vars.vars[3];
                    try frame.operand_stack.pushDouble(value.Double);
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
                    const index_byte = frame.getCodeByte(frame.pc + 1);
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
                OpcodeEnum.DStore => { // dstore
                    const index: usize = @intCast(frame.getCodeByte(frame.pc + 1));
                    const v = try frame.operand_stack.popDouble();

                    frame.local_vars.vars[index] = Value{ .Double = v };
                    frame.local_vars.vars[index + 1] = Value.Top;
                },
                OpcodeEnum.DStore1 => { // dstore_1
                    const value = try frame.operand_stack.popDouble();
                    frame.local_vars.vars[1] = Value{ .Double = value };
                },
                OpcodeEnum.DStore3 => { // dstore_3
                    const value = try frame.operand_stack.popDouble();
                    frame.local_vars.vars[3] = Value{ .Double = value };
                },
                OpcodeEnum.ISub => { // isub
                    const b = (try frame.operand_stack.pop()).Int;
                    const a = (try frame.operand_stack.pop()).Int;
                    try frame.operand_stack.push(Value{ .Int = a - b });
                },
                OpcodeEnum.DSub => { // dsub
                    const b = (try frame.operand_stack.popDouble());
                    const a = (try frame.operand_stack.popDouble());
                    try frame.operand_stack.pushDouble(a - b);
                },
                OpcodeEnum.IAdd => { // iadd
                    const b = (try frame.operand_stack.pop()).Int;
                    const a = (try frame.operand_stack.pop()).Int;
                    try frame.operand_stack.push(Value{ .Int = a + b });
                },
                OpcodeEnum.DAdd => { // dadd
                    const b = (try frame.operand_stack.popDouble());
                    const a = (try frame.operand_stack.popDouble());
                    try frame.operand_stack.pushDouble(a + b);
                },
                OpcodeEnum.IMul => { // imul
                    const b = (try frame.operand_stack.pop()).Int;
                    const a = (try frame.operand_stack.pop()).Int;
                    try frame.operand_stack.push(Value{ .Int = a * b });
                },
                OpcodeEnum.DMul => { // dmul
                    const b = (try frame.operand_stack.popDouble());
                    const a = (try frame.operand_stack.popDouble());
                    try frame.operand_stack.pushDouble(a * b);
                },
                OpcodeEnum.IDiv => { // idiv
                    const b = (try frame.operand_stack.pop()).Int;
                    const a = (try frame.operand_stack.pop()).Int;
                    if (b == 0) {
                        return error.ArithmeticException;
                    }
                    try frame.operand_stack.push(Value{ .Int = @divFloor(a, b) });
                },
                OpcodeEnum.DDiv => { // ddiv
                    const b = (try frame.operand_stack.popDouble());
                    const a = (try frame.operand_stack.popDouble());
                    if (b == 0.0) {
                        return error.ArithmeticException;
                    }
                    try frame.operand_stack.pushDouble(a / b);
                },
                OpcodeEnum.IRem => { // irem
                    const b = (try frame.operand_stack.pop()).Int;
                    const a = (try frame.operand_stack.pop()).Int;
                    if (b == 0) {
                        return error.ArithmeticException;
                    }
                    try frame.operand_stack.push(Value{ .Int = @rem(a, b) });
                },
                OpcodeEnum.LxOr => { // lxor
                    const value2 = try frame.operand_stack.pop();
                    const value1 = try frame.operand_stack.pop();

                    const r: i64 = value1.Long ^ value2.Long;

                    try frame.operand_stack.push(Value{ .Long = r });
                },
                OpcodeEnum.IInc => { // iinc
                    const index_byte = frame.getCodeByte(frame.pc + 1);
                    const const_byte = frame.getCodeByte(frame.pc + 2);

                    const index: usize = @intCast(index_byte);
                    const increment: i32 = @intCast(const_byte);

                    var current_value = frame.local_vars.vars[index].Int;
                    current_value += increment;
                    frame.local_vars.vars[index] = Value{ .Int = current_value };
                },
                OpcodeEnum.D2I => {
                    const d = try frame.operand_stack.popDouble();

                    const i: i32 =
                        if (std.math.isNan(d)) 0 else if (d > @as(f64, std.math.maxInt(i32)))
                            std.math.maxInt(i32)
                        else if (d < @as(f64, std.math.minInt(i32)))
                            std.math.minInt(i32)
                        else
                            @intFromFloat(d);

                    try frame.operand_stack.push(Value{ .Int = i });
                },
                OpcodeEnum.IfCmpGe => { // if_icmpge
                    const value2 = try frame.operand_stack.pop();
                    const value1 = try frame.operand_stack.pop();

                    const offset_high = frame.getCodeByte(frame.pc + 1);
                    const offset_low = frame.getCodeByte(frame.pc + 2);

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

                    const offset_high = frame.getCodeByte(frame.pc + 1);
                    const offset_low = frame.getCodeByte(frame.pc + 2);

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

                    const offset_high = frame.getCodeByte(frame.pc + 1);
                    const offset_low = frame.getCodeByte(frame.pc + 2);

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
                    const index_high = frame.getCodeByte(frame.pc + 1);
                    const index_low = frame.getCodeByte(frame.pc + 2);

                    const method_index: u16 =
                        (@as(u16, index_high) << 8) | @as(u16, index_low);

                    const method_name = try frame.class.getConstantUtf8(method_index);
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
                    const offset_high = frame.getCodeByte(frame.pc + 1);
                    const offset_low = frame.getCodeByte(frame.pc + 2);

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
                OpcodeEnum.GetStatic => { // getstatic
                    const indexbyte1 = frame.getCodeByte(frame.pc + 1);
                    const indexbyte2 = frame.getCodeByte(frame.pc + 2);

                    const index: u16 = (@as(u16, indexbyte1) << 8) | @as(u16, indexbyte2);

                    const fieldref = try frame.class.getFieldRef(index);

                    const name_and_type_cp = try frame.class.getConstant(fieldref.name_and_type_index);

                    std.debug.print("Field class index: {}\n", .{fieldref.class_index});

                    const class = try frame.class.getConstantUtf8(fieldref.class_index);

                    std.debug.print("Field class: {any}\n", .{class});

                    switch (name_and_type_cp) {
                        .NameAndType => |name_and_type| {
                            const name_cp = try frame.class.getConstant(name_and_type.name_index);
                            switch (name_cp) {
                                .Utf8 => |name_str| {
                                    std.debug.print("Getting static field name: {s}\n", .{name_str});

                                    // For now, we only support getting static fields from java/lang/System
                                    if (std.mem.eql(u8, class, "java/lang/System")) {
                                        if (std.mem.eql(u8, name_str, "out")) {
                                            // Push System.out onto the operand stack
                                            std.debug.print("Pushing System.out PrintStream reference onto operand stack\n", .{});
                                            try frame.operand_stack.push(Value{ .Reference = 0xDEADBEEF }); // Placeholder for System.out

                                        } else {
                                            std.debug.print("Error: Unsupported static field name {s} in class {any}\n", .{ name_str, class });
                                            return error.FieldNotFound;
                                        }
                                    } else {
                                        std.debug.print("Error: Unsupported class {any} for getstatic\n", .{class});
                                        return error.ClassNotFound;
                                    }
                                },
                                else => {
                                    std.debug.print("Error: NameAndType entry at index {d} does not point to a Utf8 entry for name. Found: {s}\n", .{ name_and_type.name_index, @tagName(name_cp) });
                                    return error.InvalidConstantPoolEntry;
                                },
                            }
                        },
                        else => {
                            std.debug.print("Error: FieldRef entry at index {d} does not point to a NameAndType entry. Found: {s}\n", .{ fieldref.name_and_type_index, @tagName(name_and_type_cp) });
                            return error.InvalidConstantPoolEntry;
                        },
                    }

                    std.debug.print("Getting static field:\n", .{});
                    std.debug.print("Class: {s}\n", .{class});

                    std.debug.print("FieldRef: {any}\n", .{fieldref});
                    std.debug.print("Index: {}\n", .{index});
                },
                OpcodeEnum.InvokeVirtual => { // invokevirtual
                    const indexbyte1 = frame.getCodeByte(frame.pc + 1);
                    const indexbyte2 = frame.getCodeByte(frame.pc + 2);

                    const method_index: u16 = (@as(u16, indexbyte1) << 8) | @as(u16, indexbyte2);

                    const method_name = try frame.class.getConstantUtf8(method_index);

                    std.debug.print("Invoking virtual method: {s}\n", .{method_name});

                    const method = try frame.class.getMethod(method_name) orelse return error.MethodNotFound;

                    const codeAttr = Code{
                        .std_function = StdFunction.Println,
                        .attributes = &[_]AttributesInfo{},
                        .exception_table = &[_]ExceptionTableEntry{},
                        .max_stack = 2,
                        .max_locals = 2,
                        .code = &[_]u8{},
                    };

                    frame.pc += opcode.getOperandLength();

                    var new_frame = try Frame.init(allocator, codeAttr, frame.class);

                    for (0..method.num_params) |i| {
                        const arg = try frame.operand_stack.pop();
                        new_frame.local_vars.vars[method.num_params - 1 - i] = arg;
                    }

                    // Pop the object reference
                    const obj_ref = try frame.operand_stack.pop();

                    _ = obj_ref;

                    // For now, we are not using obj_ref, but in a full implementation, we would need to handle it.

                    try vm.pushFrame(new_frame);
                    continue;
                },
            }

            frame.pc += opcode.getOperandLength();
        }
    }
};
