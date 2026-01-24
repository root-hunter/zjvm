pub const OpcodeEnum = enum(u8) {
    Nop = 0x00,
    FConts2 = 0x0d,
    DConst0 = 0x0e,
    IConstM1 = 0x02,
    IConst0 = 0x03,
    IConst1 = 0x04,
    IConst2 = 0x05,
    IConst3 = 0x06,
    IConst4 = 0x07,
    IConst5 = 0x08,
    BiPush = 0x10,
    SiPush = 0x11,
    LDC = 0x12,
    LDC2_W = 0x14,
    ILoad = 0x15,
    DLoad = 0x18,
    ILoad0 = 0x1a,
    ILoad1 = 0x1b,
    ILoad2 = 0x1c,
    ILoad3 = 0x1d,
    LLoad3 = 0x21,
    DLoad1 = 0x27,
    DLoad3 = 0x29,
    ALoad1 = 0x2b,
    AALoad = 0x32,
    IStore = 0x36,
    IStore0 = 0x3b,
    IStore1 = 0x3c,
    IStore2 = 0x3d,
    IStore3 = 0x3e,
    DStore = 0x39,
    DStore1 = 0x48,
    DStore3 = 0x4a,
    AStore1 = 0x4c,
    ISub = 0x64,
    IAdd = 0x60,
    DAdd = 0x63,
    DSub = 0x67,
    IMul = 0x68,
    DMul = 0x6b,
    IDiv = 0x6c,
    DDiv = 0x6f,
    IRem = 0x70,
    LxOr = 0x83,
    IInc = 0x84,
    I2D = 0x87,
    D2I = 0x8e,
    IfNe = 0x9a,
    IfICmpLt = 0xa1,
    IfICmpGe = 0xa2,
    IfICmpGt = 0xa3,
    IfICmpLe = 0xa4,
    GoTo = 0xa7,
    IReturn = 0xac,
    InvokeStatic = 0xb8,
    Return = 0xb1,
    GetStatic = 0xb2,
    InvokeVirtual = 0xb6,
    InvokeDynamic = 0xba,

    pub fn getOperandFormat(self: OpcodeEnum) OperandFormat {
        return switch (self) {
            OpcodeEnum.BiPush => OperandFormat.Byte,
            else => OperandFormat.NoOperand,
        };
    }

    pub fn getOperandLength(self: OpcodeEnum) usize {
        return switch (self) {
            OpcodeEnum.BiPush => 2, // 1 byte operand
            OpcodeEnum.SiPush => 3, // 2 byte operand
            OpcodeEnum.LDC => 2, // 1 byte operand
            OpcodeEnum.LDC2_W => 3, // 2 byte operand
            OpcodeEnum.IStore => 2, // istore <index>
            OpcodeEnum.ILoad => 2, // iload <index>
            OpcodeEnum.DLoad => 2, // dload <index>
            OpcodeEnum.DStore => 2, // dstore <index>
            OpcodeEnum.LxOr => 3, // lxor <indexbyte1> <indexbyte2>
            OpcodeEnum.IInc => 3, // iinc <index> <const>
            OpcodeEnum.IfNe => 3, // ifne <branchbyte1> <branchbyte2>
            OpcodeEnum.IfICmpLt => 3, // if_icmplt <branchbyte1> <branchbyte2>
            OpcodeEnum.IfICmpGe => 3, // if_icmpge <branchbyte1> <branchbyte2>
            OpcodeEnum.IfICmpGt => 3, // if_icmpgt <branchbyte1> <branchbyte2>
            OpcodeEnum.IfICmpLe => 3, // if_icmple <branchbyte1> <branchbyte2>
            OpcodeEnum.GoTo => 3, // goto <branchbyte1> <branchbyte2>
            OpcodeEnum.InvokeStatic => 3, // invokestatic <indexbyte1> <indexbyte2>
            OpcodeEnum.GetStatic => 3, // getstatic <indexbyte1> <indexbyte2>
            OpcodeEnum.InvokeVirtual => 3, // invokevirtual <indexbyte1> <indexbyte2>
            OpcodeEnum.InvokeDynamic => 5, // invokedynamic <indexbyte1> <indexbyte2> 0 0
            else => 1, // nessun operand
        };
    }

    pub fn toString(self: OpcodeEnum) []const u8 {
        return switch (self) {
            OpcodeEnum.Nop => "nop",
            OpcodeEnum.FConts2 => "fconst_2",
            OpcodeEnum.DConst0 => "dconst_0",
            OpcodeEnum.IConstM1 => "iconst_m1",
            OpcodeEnum.IConst0 => "iconst_0",
            OpcodeEnum.IConst1 => "iconst_1",
            OpcodeEnum.IConst2 => "iconst_2",
            OpcodeEnum.IConst3 => "iconst_3",
            OpcodeEnum.IConst4 => "iconst_4",
            OpcodeEnum.IConst5 => "iconst_5",
            OpcodeEnum.BiPush => "bipush",
            OpcodeEnum.SiPush => "sipush",
            OpcodeEnum.LDC => "ldc",
            OpcodeEnum.LDC2_W => "ldc2_w",
            OpcodeEnum.ILoad => "iload",
            OpcodeEnum.ILoad0 => "iload_0",
            OpcodeEnum.ILoad1 => "iload_1",
            OpcodeEnum.ILoad2 => "iload_2",
            OpcodeEnum.ILoad3 => "iload_3",
            OpcodeEnum.LLoad3 => "lload_3",
            OpcodeEnum.DLoad => "dload",
            OpcodeEnum.DLoad1 => "dload_1",
            OpcodeEnum.DLoad3 => "dload_3",
            OpcodeEnum.AStore1 => "astore_1",
            OpcodeEnum.ALoad1 => "aload_1",
            OpcodeEnum.AALoad => "aaload",
            OpcodeEnum.IStore => "istore",
            OpcodeEnum.IStore0 => "istore_0",
            OpcodeEnum.IStore1 => "istore_1",
            OpcodeEnum.IStore2 => "istore_2",
            OpcodeEnum.IStore3 => "istore_3",
            OpcodeEnum.DStore => "dstore",
            OpcodeEnum.DStore1 => "dstore_1",
            OpcodeEnum.DStore3 => "dstore_3",
            OpcodeEnum.ISub => "isub",
            OpcodeEnum.DSub => "dsub",
            OpcodeEnum.IAdd => "iadd",
            OpcodeEnum.DAdd => "dadd",
            OpcodeEnum.IMul => "imul",
            OpcodeEnum.DMul => "dmul",
            OpcodeEnum.IDiv => "idiv",
            OpcodeEnum.DDiv => "ddiv",
            OpcodeEnum.IRem => "irem",
            OpcodeEnum.LxOr => "lxor",
            OpcodeEnum.IInc => "iinc",
            OpcodeEnum.I2D => "i2d",
            OpcodeEnum.D2I => "d2i",
            OpcodeEnum.IfNe => "ifne",
            OpcodeEnum.IfICmpLt => "if_icmplt",
            OpcodeEnum.IfICmpGe => "if_icmpge",
            OpcodeEnum.IfICmpGt => "if_icmpgt",
            OpcodeEnum.IfICmpLe => "if_icmple",
            OpcodeEnum.InvokeStatic => "invokestatic",
            OpcodeEnum.GoTo => "goto",
            OpcodeEnum.IReturn => "ireturn",
            OpcodeEnum.Return => "return",
            OpcodeEnum.GetStatic => "getstatic",
            OpcodeEnum.InvokeVirtual => "invokevirtual",
            OpcodeEnum.InvokeDynamic => "invokedynamic",
        };
    }
};

pub const OperandFormat = enum {
    NoOperand,
    Byte,
    Short,
    Int,
    BranchOffset,
};
