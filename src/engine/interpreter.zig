const std = @import("std");
const Frame = @import("../runtime/frame.zig").Frame;
const Value = @import("../runtime/value.zig").Value;
const OpcodeEnum = @import("opcode.zig").OpcodeEnum;
const ZJVM = @import("../engine/vm.zig").ZJVM;
const Code = @import("../classfile/code.zig").CodeAttribute;
const StdFunction = @import("../classfile/code.zig").StdFunction;
const AttributesInfo = @import("../classfile/attributes.zig").AttributesInfo;
const ExceptionTableEntry = @import("../classfile/code.zig").ExceptionTableEntry;
const MethodInfo = @import("../classfile/methods.zig").MethodInfo;
const utils = @import("../classfile/utils.zig");
const types = @import("../classfile/types.zig");

const PrintStream = struct {
    stream: ?std.fs.File,
};

pub const JavaString = struct {
    bytes: []const u8,
};

pub const JVMInterpreter = struct {
    vm: *ZJVM,
    print_alloc: std.mem.Allocator,
    stdout: std.fs.File,
    stdin: std.fs.File,

    pub fn init(vm: *ZJVM) !JVMInterpreter {
        return JVMInterpreter{
            .print_alloc = std.heap.page_allocator,
            .vm = vm,
            .stdout = std.fs.File.stdout(),
            .stdin = std.fs.File.stdin(),
        };
    }

    pub fn setStdout(self: *JVMInterpreter, file: std.fs.File) void {
        self.stdout = file;
    }

    pub fn setStdin(self: *JVMInterpreter, file: std.fs.File) void {
        self.stdin = file;
    }

    pub fn execute(self: *JVMInterpreter, allocator: *std.mem.Allocator) !void {
        while (true) {
            const frame = self.vm.currentFrame() orelse return error.NoFrame;

            if (frame.std_function != null) {
                const std_func = frame.std_function.?;
                const method = std_func.method;

                switch (std_func.func) {
                    .Println => {
                        const ref: Value = try frame.operand_stack.pop();
                        const value: Value = try frame.operand_stack.pop();

                        const params = method.getParameterTypes() catch return error.InvalidMethodDescriptor;

                        const is2Slots = utils.is2SlotType(params[0].bytes);

                        if (is2Slots) {
                            _ = try frame.operand_stack.pop(); // Top slot
                        }

                        const ps: *PrintStream = @ptrCast(@alignCast(ref.Reference));

                        if (ps.stream == null) {
                            return error.NullPointerException;
                        }

                        const stream = ps.stream.?;

                        var value_str: ?[]const u8 = null;

                        switch (value) {
                            .Int => |i| {
                                value_str = std.fmt.allocPrint(self.print_alloc, "{}", .{i}) catch return error.OutOfMemory;
                            },
                            .Float => |f| {
                                value_str = std.fmt.allocPrint(self.print_alloc, "{}", .{f}) catch return error.OutOfMemory;
                            },
                            .Double => |d| {
                                value_str = std.fmt.allocPrint(self.print_alloc, "{}", .{d}) catch return error.OutOfMemory;
                            },
                            .Long => |l| {
                                value_str = std.fmt.allocPrint(self.print_alloc, "{}", .{l}) catch return error.OutOfMemory;
                            },
                            .Reference => |r| {
                                const js: *JavaString = @ptrCast(@alignCast(r));
                                value_str = js.bytes;
                            },
                            else => {
                                std.debug.print("Unsupported type for println: {any}\n", .{value});
                            },
                        }
                        if (value_str) |vs| {
                            _ = try stream.write(vs);
                            _ = try stream.write("\n");
                        } else {
                            return error.UnsupportedStdFunction;
                        }
                    },
                    else => {
                        return error.UnsupportedStdFunction;
                    },
                }
                _ = try self.vm.popFrame();
                if (self.vm.stack.top == 0) break;
                continue;
            } else {
                if (frame.pc >= frame.getCodeLength()) {
                    _ = try self.vm.popFrame();
                    if (self.vm.stack.top == 0) break;
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

                        const entry = try frame.class.getConstantPoolEntry(index);

                        switch (entry) {
                            .Integer => |int_value| {
                                try frame.operand_stack.push(Value{ .Int = int_value });
                            },
                            .Float => |float_value| {
                                try frame.operand_stack.push(Value{ .Float = float_value });
                            },
                            .String => |string_index| {
                                // For now, we will push the reference as a usize pointer

                                const java_string = try allocator.create(JavaString);
                                const str_bytes = try frame.class.getConstantUtf8(string_index);

                                java_string.* = JavaString{
                                    .bytes = str_bytes,
                                };

                                try frame.operand_stack.push(Value{ .Reference = @ptrCast(@alignCast(java_string)) });
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

                        const entry = try frame.class.getConstantPoolEntry(index);

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
                    OpcodeEnum.ALoad1 => { // aload_1
                        const value = frame.local_vars.vars[1];
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
                    OpcodeEnum.AStore1 => { // astore_1
                        const value = try frame.operand_stack.pop();
                        frame.local_vars.vars[1] = value;
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
                    OpcodeEnum.I2D => { // i2d
                        const int_value = try frame.operand_stack.pop();
                        const d_value: f64 = @floatFromInt(int_value.Int);
                        try frame.operand_stack.pushDouble(d_value);
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
                    OpcodeEnum.IfNe => { // ifne
                        const value = try frame.operand_stack.pop();

                        const offset_high = frame.getCodeByte(frame.pc + 1);
                        const offset_low = frame.getCodeByte(frame.pc + 2);

                        const high: i16 = @intCast(offset_high);
                        const low: i16 = @intCast(offset_low);

                        const branch_offset: i16 = (high << 8) | low;

                        if (value.Int != 0) {
                            const b: i32 = @intCast(frame.pc);
                            frame.pc = @intCast(b + branch_offset);
                            continue;
                        }
                    },
                    OpcodeEnum.IfICmpLt => { // if_icmplt
                        const value2 = try frame.operand_stack.pop();
                        const value1 = try frame.operand_stack.pop();

                        const offset_high = frame.getCodeByte(frame.pc + 1);
                        const offset_low = frame.getCodeByte(frame.pc + 2);

                        const high: i16 = @intCast(offset_high);
                        const low: i16 = @intCast(offset_low);

                        const branch_offset: i16 = (high << 8) | low;

                        if (value1.Int < value2.Int) {
                            const b: i32 = @intCast(frame.pc);
                            frame.pc = @intCast(b + branch_offset);
                            continue;
                        }
                    },
                    OpcodeEnum.IfICmpGe => { // if_icmpge
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
                    OpcodeEnum.IfICmpGt => { // if_icmpgt
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
                    OpcodeEnum.IfICmpLe => { // if_icmple
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

                        try self.vm.pushFrame(new_frame);
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

                        _ = try self.vm.stack.pop();

                        if (self.vm.stack.top == 0) {
                            break;
                        }

                        var caller = self.vm.stack.current();
                        try caller.operand_stack.push(return_value);

                        continue;
                    },
                    OpcodeEnum.Return => { // return
                        _ = try self.vm.stack.pop();
                        return;
                    },
                    OpcodeEnum.GetStatic => { // getstatic
                        const indexbyte1 = frame.getCodeByte(frame.pc + 1);
                        const indexbyte2 = frame.getCodeByte(frame.pc + 2);

                        const index: u16 = (@as(u16, indexbyte1) << 8) | @as(u16, indexbyte2);

                        const fieldref = try frame.class.getFieldRef(index);

                        const name_and_type_cp = try frame.class.getConstant(fieldref.name_and_type_index);

                        switch (name_and_type_cp) {
                            .NameAndType => |name_and_type| {
                                const class = try frame.class.getConstantUtf8(fieldref.class_index);
                                const name_cp = try frame.class.getConstant(name_and_type.name_index);

                                switch (name_cp) {
                                    .Utf8 => |name_str| {
                                        // For now, we only support getting static fields from java/lang/System
                                        if (std.mem.eql(u8, class, "java/lang/System")) {
                                            if (std.mem.eql(u8, name_str, "out")) {
                                                const ps = try allocator.create(PrintStream);
                                                ps.* = PrintStream{
                                                    .stream = self.stdout,
                                                };
                                                try frame.operand_stack.push(Value{ .Reference = ps });
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
                    },
                    OpcodeEnum.InvokeVirtual => { // invokevirtual
                        const indexbyte1 = frame.getCodeByte(frame.pc + 1);
                        const indexbyte2 = frame.getCodeByte(frame.pc + 2);

                        const method_index: u16 = (@as(u16, indexbyte1) << 8) | @as(u16, indexbyte2);

                        const methodref = try frame.class.getMethodRef(method_index);

                        const method = try MethodInfo.fromRef(allocator, frame.class, methodref);

                        if (method == null) {
                            std.debug.print("Error: MethodRef at index {d} could not be resolved.\n", .{method_index});
                            return error.MethodNotFound;
                        }

                        const params = try method.?.getParameterTypes();

                        if (params.len + 1 > frame.operand_stack.size) {
                            std.debug.print("Error: Not enough operands on stack for method invocation. Needed {d}, but stack size is {d}\n", .{ params.len + 1, frame.operand_stack.size });
                            return error.StackUnderflow;
                        }

                        // const method_name = try frame.class.getConstantUtf8(method_index);

                        if (!std.mem.eql(u8, method.?.name, "println")) {
                            std.debug.print("Error: Unsupported virtual method {s}\n", .{method.?.name});
                            return error.MethodNotFound;
                        } else {
                            const std_function = StdFunction{
                                .func = .Println,
                                .method = method.?,
                            };

                            const is2Slots = utils.is2SlotType(params[0].bytes);

                            const num_params = method.?.num_params + 1;

                            frame.pc += opcode.getOperandLength();

                            var new_frame = try Frame.initStdFunctionFrame(allocator, std_function, num_params, frame.class);

                            if (is2Slots) {
                                // Double takes two slots
                                try new_frame.operand_stack.push(try frame.operand_stack.pop());
                                // Top slot for double
                                try new_frame.operand_stack.push(try frame.operand_stack.pop());
                            } else {
                                try new_frame.operand_stack.push(try frame.operand_stack.pop());
                            }

                            // Then the object reference
                            try new_frame.operand_stack.push(try frame.operand_stack.pop());
                            try self.vm.pushFrame(new_frame);
                            continue;
                        }
                    },
                    OpcodeEnum.InvokeDynamic => {
                        const index: u16 = (@as(u16, frame.getCodeByte(frame.pc + 1)) << 8) | @as(u16, frame.getCodeByte(frame.pc + 2));

                        // --- COSTANTE CP ---
                        const entry = try frame.class.getConstantPoolEntry(index);
                        const indy = switch (entry) {
                            .InvokeDynamic => |i| i,
                            else => return error.InvalidConstantPoolEntry,
                        };

                        // --- BOOTSTRAP METHOD ---
                        const bootstrap = try frame.class.getBootstrapMethod(index);
                        // std.debug.print("Invokedynamic bootstrap method: {any}\n", .{bootstrap});

                        // --- NAME AND TYPE ---
                        const nat_cp = try frame.class.getConstantPoolEntry(indy.name_and_type_index);
                        const nat = switch (nat_cp) {
                            .NameAndType => |nt| nt,
                            else => return error.InvalidConstantPoolEntry,
                        };

                        const name = try frame.class.getConstantUtf8(nat.name_index);
                        const descriptor = try frame.class.getConstantUtf8(nat.descriptor_index);
                        const param_count: usize = utils.getParameterCount(descriptor);

                        if (!std.mem.eql(u8, name, "makeConcatWithConstants")) {
                            std.debug.print("Unsupported invokedynamic: {s}\n", .{name});
                            return error.UnsupportedOpcode;
                        }

                        // std.debug.print("Invokedynamic makeConcatWithConstants called with descriptor: {s}\n", .{descriptor});

                        if (bootstrap.bootstrap_args == null or bootstrap.bootstrap_args.?.len == 0) {
                            return error.InvalidBootstrapArgs;
                        }

                        const template_idx = bootstrap.bootstrap_args.?[0];
                        const template_str = try frame.class.getConstantString(template_idx);

                        // std.debug.print("  Template string: {s}\n", .{template_str});

                        var res = try std.ArrayList(u8).initCapacity(self.print_alloc, 64);
                        var param_idx: usize = 0;
                        var params = try std.ArrayList([]const u8).initCapacity(self.print_alloc, param_count);

                        // std.debug.print("  Concatenating {d} parameters:\n", .{param_count});

                        var i: usize = 0;
                        var temp_params = try std.ArrayList([]const u8).initCapacity(self.print_alloc, param_count);
                        while (i < param_count) : (i += 1) {
                            var v = try frame.operand_stack.pop();

                            while (v == .Top) {
                                v = try frame.operand_stack.pop();
                            }

                            var s: ?[]const u8 = null;

                            switch (v) {
                                .Int => |x| s = try std.fmt.allocPrint(self.print_alloc, "{}", .{x}),
                                .Float => |x| s = try std.fmt.allocPrint(self.print_alloc, "{}", .{x}),
                                .Long => |x| s = try std.fmt.allocPrint(self.print_alloc, "{}", .{x}),
                                .Double => |x| {
                                    s = try std.fmt.allocPrint(self.print_alloc, "{}", .{x});
                                },
                                .Reference => |r| {
                                    const js: *JavaString = @ptrCast(@alignCast(r));
                                    s = js.bytes;
                                },
                                else => {
                                    std.debug.print("Unsupported parameter type for makeConcatWithConstants: {any}\n", .{v});
                                    return error.UnsupportedType;
                                },
                            }

                            if (s == null) return error.UnsupportedType;

                            try temp_params.append(self.print_alloc, s.?);
                        }

                        // --- Invertiamo l’array dei parametri per rispettare l’ordine JVM ---
                        for (0..param_count) |j| {
                            try params.append(self.print_alloc, temp_params.items[param_count - 1 - j]);
                        }

                        for (template_str) |c| {
                            if (c == 0x01) {
                                if (param_idx >= params.items.len) return error.InvalidParameterCount;
                                try res.appendSlice(self.print_alloc, params.items[param_idx]);
                                param_idx += 1;
                            } else {
                                try res.append(self.print_alloc, c);
                            }
                        }

                        const js = try allocator.create(JavaString);
                        js.* = JavaString{ .bytes = res.items };

                        try frame.operand_stack.push(Value{
                            .Reference = @ptrCast(@alignCast(js)),
                        });

                        frame.pc += opcode.getOperandLength();
                        continue;
                    },
                }

                frame.pc += opcode.getOperandLength();
            }
        }
    }
};
