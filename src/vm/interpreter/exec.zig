const std = @import("std");
const Frame = @import("frame.zig").Frame;
const Value = @import("value.zig").Value;
const OpcodeEnum = @import("opcode.zig").OpcodeEnum;
const ZJVM = @import("../vm.zig").ZJVM;
const Code = @import("../class/code.zig").CodeAttribute;
const StdFunction = @import("../class/code.zig").StdFunction;
const AttributesInfo = @import("../class/attributes.zig").AttributesInfo;
const ExceptionTableEntry = @import("../class/code.zig").ExceptionTableEntry;
const MethodInfo = @import("../class/methods.zig").MethodInfo;
const utils = @import("../../utils.zig");
const types = @import("../types.zig");
const Heap = @import("../heap/heap.zig").Heap;
const registry = @import("../native/registry.zig");
const PrintStream = @import("../native/java_lang.zig").PrintStream;
const JavaString = @import("../native/java_lang.zig").JavaString;
const JavaLang = @import("../native/java_lang.zig");

pub const JVMInterpreter = struct {
    fn getStatic(vm: *ZJVM, allocator: std.mem.Allocator, frame: *Frame) !void {
        _ = vm;
        _ = allocator;

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
                                // const ps = try allocator.create(PrintStream);
                                // ps.* = PrintStream{
                                //     .stream = vm.stdout,
                                // };
                                try frame.pushOperand(Value{ .Reference = null });
                            } else {
                                std.debug.print("Error: Unsupported static field name {s} in class {s}\n", .{ name_str, class });
                                return error.FieldNotFound;
                            }
                        } else {
                            std.debug.print("Error: Unsupported class {s} for getstatic\n", .{class});
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
    }

    fn invokeVirtual(vm: *ZJVM, allocator: std.mem.Allocator, frame: *Frame) !void {
        const indexbyte1 = frame.getCodeByte(frame.pc + 1);
        const indexbyte2 = frame.getCodeByte(frame.pc + 2);

        const method_index: u16 = (@as(u16, indexbyte1) << 8) | @as(u16, indexbyte2);

        const methodref = try frame.class.getMethodRef(method_index);

        const method = try MethodInfo.fromRef(&allocator, frame.class, methodref);

        if (method == null) {
            std.debug.print("Error: MethodRef at index {d} could not be resolved.\n", .{method_index});
            return error.MethodNotFound;
        }

        const method_class = try frame.class.getConstantUtf8(methodref.class_index);
        const method_signature_entry = try frame.class.getConstant(methodref.name_and_type_index);
        const nat = method_signature_entry.NameAndType;
        const method_signature = try frame.class.getConstantUtf8(nat.descriptor_index);
        const method_name = method.?.name;

        // std.debug.print("Invoking {s} ({s}) from class {s}\n", .{ method.?.name, method_signature, method_class });

        const bootstrap_method = vm.nr.find(method_class, method_name, method_signature);

        if (bootstrap_method == null) {
            std.debug.print("Error: Method {s} with signature {s} not found in native registry.\n", .{ method_name, method_signature });
            return error.MethodNotFound;
        }

        const params = try method.?.getParameterTypes();

        if (params.len + 1 > frame.operand_stack.size) {
            std.debug.print("Error: Not enough operands on stack for method invocation. Needed {d}, but stack size is {d}\n", .{ params.len + 1, frame.operand_stack.size });
            return error.StackUnderflow;
        }

        const np = method.?.num_params + 1;

        var ne = vm.getNativeEnv(allocator);
        const args = allocator.alloc(Value, np) catch {
            std.debug.print("Error: Out of memory while allocating arguments for method invocation.\n", .{});
            return error.OutOfMemory;
        };
        defer allocator.free(args);

        var i: usize = 0;

        while (i < np - 1) : (i += 1) {
            var val: ?Value = null;

            if (utils.is2SlotType(params[i].bytes)) {
                val = try frame.pop2Operand();
            } else {
                val = try frame.popOperand();
            }

            args[np - 2 - i] = val.?;
        }

        const this = try frame.popOperand(); // pop this
        args[np - 1] = this;

        _ = bootstrap_method.?(
            &ne,
            args,
        ) catch {
            std.debug.print("Error: Could not invoke native method {s} with signature {s} from class {s}\n", .{ method_name, method_signature, method_class });
            return error.MethodInvocationFailed;
        };
    }

    fn invokeDynamic(allocator: std.mem.Allocator, frame: *Frame) !void {
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

        var res = try std.ArrayList(u8).initCapacity(allocator, 64);

        var param_idx: usize = 0;
        var params = try std.ArrayList([]const u8).initCapacity(allocator, param_count);
        defer params.deinit(allocator);
        // std.debug.print("  Concatenating {d} parameters:\n", .{param_count});

        var i: usize = 0;
        var temp_params = try std.ArrayList([]const u8).initCapacity(allocator, param_count);
        defer temp_params.deinit(allocator);

        while (i < param_count) : (i += 1) {
            var v = try frame.popOperand();

            while (v == .Top) {
                v = try frame.popOperand();
            }

            var s: ?[]const u8 = null;

            switch (v) {
                .Int => |x| s = try std.fmt.allocPrint(allocator, "{}", .{x}),
                .Float => |x| s = try std.fmt.allocPrint(allocator, "{}", .{x}),
                .Long => |x| s = try std.fmt.allocPrint(allocator, "{}", .{x}),
                .Double => |x| {
                    s = try std.fmt.allocPrint(allocator, "{}", .{x});
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

            try temp_params.append(allocator, s.?);
        }

        // --- Invertiamo l’array dei parametri per rispettare l’ordine JVM ---
        for (0..param_count) |j| {
            try params.append(allocator, temp_params.items[param_count - 1 - j]);
        }

        for (template_str) |c| {
            if (c == 0x01) {
                if (param_idx >= params.items.len) return error.InvalidParameterCount;
                try res.appendSlice(allocator, params.items[param_idx]);
                param_idx += 1;
            } else {
                try res.append(allocator, c);
            }
        }

        const js = try allocator.create(JavaString);
        js.* = JavaString{ .bytes = res.items };

        try frame.pushOperand(Value{
            .Reference = @ptrCast(@alignCast(js)),
        });
    }

    fn invokeStatic(vm: *ZJVM, allocator: std.mem.Allocator, frame: *Frame) !void {
        const index_high = frame.getCodeByte(frame.pc + 1);
        const index_low = frame.getCodeByte(frame.pc + 2);

        const method_index: u16 =
            (@as(u16, index_high) << 8) | @as(u16, index_low);

        const method_name = try frame.class.getConstantUtf8(method_index);
        const method = try frame.class.getMethod(method_name) orelse return error.MethodNotFound;

        const codeAttr = method.code orelse return error.NoCodeAttribute;

        //frame.pc += 1 + opcode.getOperandLength();

        var new_frame = try Frame.init(allocator, &codeAttr, frame.class);

        for (0..method.num_params) |i| {
            const arg = try frame.popOperand();
            new_frame.local_vars.vars[method.num_params - 1 - i] = arg;
        }

        try vm.pushFrame(new_frame);
    }

    pub fn execute(vm: *ZJVM) !void {
        const allocator = vm.allocator;

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
                .Nop => {
                    // Do nothing
                },
                .FConts2 => try frame.pushOperand(Value{ .Float = 2.0 }),
                .DConst0 => try frame.push2Operand(Value{ .Double = 0.0 }),
                .IConstM1 => try frame.pushOperand(Value{ .Int = -1 }),
                .IConst0 => try frame.pushOperand(Value{ .Int = 0 }),
                .IConst1 => try frame.pushOperand(Value{ .Int = 1 }),
                .IConst2 => try frame.pushOperand(Value{ .Int = 2 }),
                .IConst3 => try frame.pushOperand(Value{ .Int = 3 }),
                .IConst4 => try frame.pushOperand(Value{ .Int = 4 }),
                .IConst5 => try frame.pushOperand(Value{ .Int = 5 }),
                .BiPush => {
                    const byte = frame.getCodeByte(frame.pc + 1); // il byte seguente
                    const value: i32 = @intCast(byte); // bipush è signed 8-bit
                    try frame.pushOperand(Value{ .Int = value });
                },
                .SiPush => {
                    const high_byte = frame.getCodeByte(frame.pc + 1);
                    const low_byte = frame.getCodeByte(frame.pc + 2);

                    const high: i16 = @intCast(high_byte);
                    const low: i16 = @intCast(low_byte);

                    const combined: i16 = (high << 8) | low;
                    const value: i32 = @intCast(combined);

                    try frame.pushOperand(Value{ .Int = value });
                },
                .LDC => {
                    const index_byte = frame.getCodeByte(frame.pc + 1);
                    const index: u16 = @as(u16, index_byte);

                    const entry = try frame.class.getConstantPoolEntry(index);

                    switch (entry) {
                        .Integer => |int_value| {
                            try frame.pushOperand(Value{ .Int = int_value });
                        },
                        .Float => |float_value| {
                            try frame.pushOperand(Value{ .Float = float_value });
                        },
                        .String => |string_index| {
                            // For now, we will push the reference as a usize pointer

                            const java_string = try allocator.create(JavaString);
                            const str_bytes = try frame.class.getConstantUtf8(string_index);

                            java_string.* = JavaString{
                                .bytes = str_bytes,
                            };

                            try frame.pushOperand(Value{ .Reference = @ptrCast(@alignCast(java_string)) });
                        },
                        else => {
                            return error.InvalidConstantType;
                        },
                    }
                },
                .LDC2_W => {
                    const index_high = @as(u16, frame.getCodeByte(frame.pc + 1));
                    const index_low = @as(u16, frame.getCodeByte(frame.pc + 2));

                    const index: u16 = (index_high << 8) | index_low;

                    const entry = try frame.class.getConstantPoolEntry(index);

                    switch (entry) {
                        .Long => |long_value| {
                            try frame.push2Operand(Value{ .Long = long_value });
                        },
                        .Double => |double_value| {
                            try frame.push2Operand(Value{ .Double = double_value });
                        },
                        else => {
                            return error.InvalidConstantType;
                        },
                    }
                },
                .ILoad => { // iload
                    const index: usize = @intCast(frame.getCodeByte(frame.pc + 1));
                    try frame.pushLocalVarToStackVar(index);
                },
                .ILoad0 => try frame.pushLocalVarToStackVar(0),
                .ILoad1 => try frame.pushLocalVarToStackVar(1),
                .ILoad2 => try frame.pushLocalVarToStackVar(2),
                .ILoad3 => try frame.pushLocalVarToStackVar(3),
                .LLoad => { // lload
                    const index: usize = @intCast(frame.getCodeByte(frame.pc + 1));
                    try frame.pushLocalVarToStackVar(index);
                },
                .FLoad => { // fload
                    const index: usize = @intCast(frame.getCodeByte(frame.pc + 1));
                    try frame.pushLocalVarToStackVar(index);
                },
                .LLoad1 => try frame.pushLocalVarToStackVar(1),
                .LLoad3 => try frame.pushLocalVarToStackVar(3),
                .DLoad => { // dload
                    const index: usize = @intCast(frame.getCodeByte(frame.pc + 1));
                    try frame.pushLocalVarToStackVar(index);
                },
                .DLoad1 => try frame.pushLocalVarToStackVar(1),
                .DLoad3 => try frame.pushLocalVarToStackVar(3),
                .ALoad1 => try frame.pushLocalVarToStackVar(1),
                .AALoad => { // aaload
                    const index_value = try frame.popOperand();
                    const arrayref_value = try frame.popOperand();

                    const arrayref = arrayref_value.ArrayRef;

                    if (arrayref == null) {
                        return error.NullPointerException;
                    }

                    const index: usize = @intCast(index_value.Int);

                    const element = arrayref.?.*[index];
                    try frame.pushOperand(element);
                },
                .IStore => { // istore
                    const index: usize = @intCast(frame.getCodeByte(frame.pc + 1));
                    try frame.popStackVarToLocalVar(opcode, index);
                },
                .IStore0 => try frame.popStackVarToLocalVar(opcode, 0),
                .IStore1 => try frame.popStackVarToLocalVar(opcode, 1),
                .IStore2 => try frame.popStackVarToLocalVar(opcode, 2),
                .IStore3 => try frame.popStackVarToLocalVar(opcode, 3),
                .LStore => { // lstore
                    const index: usize = @intCast(frame.getCodeByte(frame.pc + 1));
                    try frame.popStackVarToLocalVar(opcode, index);
                },
                .FStore => { // fstore
                    const index: usize = @intCast(frame.getCodeByte(frame.pc + 1));
                    try frame.popStackVarToLocalVar(opcode, index);
                },
                .DStore => { // dstore
                    const index: usize = @intCast(frame.getCodeByte(frame.pc + 1));
                    try frame.popStackVarToLocalVar(opcode, index);
                },
                .DStore1 => try frame.popStackVarToLocalVar(opcode, 1),
                .DStore3 => try frame.popStackVarToLocalVar(opcode, 3),
                .LStore1 => try frame.popStackVarToLocalVar(opcode, 1),
                .LStore3 => try frame.popStackVarToLocalVar(opcode, 3),
                .AStore1 => try frame.popStackVarToLocalVar(opcode, 1),
                .ISub => { // isub
                    const b = (try frame.popOperand()).Int;
                    const a = (try frame.popOperand()).Int;
                    try frame.pushOperand(Value{ .Int = a - b });
                },
                .DSub => { // dsub
                    const b = (try frame.pop2Operand()).Double;
                    const a = (try frame.pop2Operand()).Double;
                    try frame.push2Operand(Value{ .Double = a - b });
                },
                .IAdd => { // iadd
                    const b = (try frame.popOperand()).Int;
                    const a = (try frame.popOperand()).Int;
                    try frame.pushOperand(Value{ .Int = a + b });
                },
                .LAdd => { // ladd
                    const b = (try frame.pop2Operand()).Long;
                    const a = (try frame.pop2Operand()).Long;
                    try frame.push2Operand(Value{ .Long = a + b });
                },
                .FAdd => { // fadd
                    const b = (try frame.popOperand()).Float;
                    const a = (try frame.popOperand()).Float;
                    try frame.pushOperand(Value{ .Float = a + b });
                },
                .DAdd => { // dadd
                    const b = (try frame.pop2Operand()).Double;
                    const a = (try frame.pop2Operand()).Double;
                    try frame.push2Operand(Value{ .Double = a + b });
                },
                .IMul => { // imul
                    const b = (try frame.popOperand()).Int;
                    const a = (try frame.popOperand()).Int;
                    try frame.pushOperand(Value{ .Int = a * b });
                },
                .LMul => { // lmul
                    const b = (try frame.pop2Operand()).Long;
                    const a = (try frame.pop2Operand()).Long;
                    try frame.push2Operand(Value{ .Long = a * b });
                },
                .DMul => { // dmul
                    const b = (try frame.pop2Operand()).Double;
                    const a = (try frame.pop2Operand()).Double;
                    try frame.push2Operand(Value{ .Double = a * b });
                },
                .IDiv => { // idiv
                    const b = (try frame.popOperand()).Int;
                    const a = (try frame.popOperand()).Int;
                    if (b == 0) {
                        return error.ArithmeticException;
                    }
                    try frame.pushOperand(Value{ .Int = @divFloor(a, b) });
                },
                .DDiv => { // ddiv
                    const b = (try frame.pop2Operand()).Double;
                    const a = (try frame.pop2Operand()).Double;
                    if (b == 0.0) {
                        return error.ArithmeticException;
                    }
                    try frame.push2Operand(Value{ .Double = a / b });
                },
                .IRem => { // irem
                    const b = (try frame.popOperand()).Int;
                    const a = (try frame.popOperand()).Int;
                    if (b == 0) {
                        return error.ArithmeticException;
                    }
                    try frame.pushOperand(Value{ .Int = @rem(a, b) });
                },
                .LxOr => { // lxor
                    const value2 = try frame.pop2Operand();
                    const value1 = try frame.pop2Operand();
                    const r: i64 = value1.Long ^ value2.Long;

                    try frame.push2Operand(Value{ .Long = r });
                },
                .IInc => { // iinc
                    const index_byte = frame.getCodeByte(frame.pc + 1);
                    const const_byte = frame.getCodeByte(frame.pc + 2);

                    const index: usize = @intCast(index_byte);
                    const increment: i32 = @intCast(const_byte);

                    var current_value = frame.local_vars.vars[index].Int;
                    current_value += increment;
                    frame.local_vars.vars[index] = Value{ .Int = current_value };
                },
                .I2L => { // i2l
                    const int_value = try frame.popOperand();
                    const long_value: i64 = @intCast(int_value.Int);
                    try frame.push2Operand(Value{ .Long = long_value });
                },
                .I2D => { // i2d
                    const int_value = try frame.popOperand();
                    const d_value: f64 = @floatFromInt(int_value.Int);
                    try frame.push2Operand(Value{ .Double = d_value });
                },
                .D2I => {
                    const d = (try frame.pop2Operand()).Double;

                    const i: i32 =
                        if (std.math.isNan(d)) 0 else if (d > @as(f64, std.math.maxInt(i32)))
                            std.math.maxInt(i32)
                        else if (d < @as(f64, std.math.minInt(i32)))
                            std.math.minInt(i32)
                        else
                            @intFromFloat(d);

                    try frame.pushOperand(Value{ .Int = i });
                },
                .IfNe => { // ifne
                    const value = try frame.popOperand();

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
                .IfICmpLt => { // if_icmplt
                    const value2 = try frame.popOperand();
                    const value1 = try frame.popOperand();

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
                .IfICmpGe => { // if_icmpge
                    const value2 = try frame.popOperand();
                    const value1 = try frame.popOperand();

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
                .IfICmpGt => { // if_icmpgt
                    const value2 = try frame.popOperand();
                    const value1 = try frame.popOperand();

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
                .IfICmpLe => { // if_icmple
                    const value2 = try frame.popOperand();
                    const value1 = try frame.popOperand();

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
                .GoTo => {
                    const offset_high = frame.getCodeByte(frame.pc + 1);
                    const offset_low = frame.getCodeByte(frame.pc + 2);

                    const branch_offset: i16 =
                        (@as(i16, offset_high) << 8) | @as(i16, offset_low);

                    const pc_i32: i32 = @intCast(frame.pc);
                    frame.pc = @intCast(pc_i32 + branch_offset);
                    continue;
                },
                .IReturn => {
                    const return_value = try frame.popOperand();

                    var popFrame = try vm.stack.pop();
                    popFrame.deinit();

                    if (vm.stack.top == 0) {
                        break;
                    }

                    var caller = vm.stack.current();
                    try caller.pushOperand(return_value);

                    continue;
                },
                .Return => { // return
                    var popFrame = try vm.stack.pop();
                    popFrame.deinit();
                    if (vm.stack.top == 0) break;
                    continue;
                },
                .GetStatic => try getStatic(vm, allocator, frame),
                .InvokeStatic => try invokeStatic(vm, allocator, frame),
                .InvokeVirtual => try invokeVirtual(vm, allocator, frame),
                .InvokeDynamic => try invokeDynamic(allocator, frame),
                .New => {
                    const index_high = frame.getCodeByte(frame.pc + 1);
                    const index_low = frame.getCodeByte(frame.pc + 2);

                    const index: u16 =
                        (@as(u16, index_high) << 8) | @as(u16, index_low);

                    const class_cp = try frame.class.getConstantPoolEntry(index);
                    const class_index = switch (class_cp) {
                        .Class => |c| c,
                        else => return error.InvalidConstantPoolEntry,
                    };
                    const class_name = try frame.class.getConstantUtf8(class_index);

                    std.debug.print("Creating new object of class {s} (not implemented yet)\n", .{class_name});

                    //const new_object = try self.heap.allocateObject(class_name);
                    //try frame.pushOperand(Value{ .Reference = @ptrCast(@alignCast(new_object)) });
                },
            }

            frame.pc += 1 + opcode.getOperandLength();
        }
        return;
    }
};
