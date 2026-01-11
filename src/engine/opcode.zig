pub const OpcodeEnum = enum(u8) {
    IConstM1 = 0x02,
    IConst0 = 0x03,
    IConst1 = 0x04,
    IConst2 = 0x05,
    IConst3 = 0x06,
    IConst4 = 0x07,
    IConst5 = 0x08,
    BiPush = 0x10,
    ILoad = 0x15,
    ILoad0 = 0x1a,
    ILoad1 = 0x1b,
    ILoad2 = 0x1c,
    ILoad3 = 0x1d,
    LLoad3 = 0x21,
    AALoad = 0x32,
    IStore = 0x36,
    IStore1 = 0x3c,
    IStore2 = 0x3d,
    IStore3 = 0x3e,
    ISub = 0x64,
    IAdd = 0x60,
    IMul = 0x68,
    IReturn = 0xac,
    InvokeStatic = 0xb8,
    Return = 0xb1,

    pub fn getOperandFormat(self: OpcodeEnum) OperandFormat {
        return switch (self) {
            OpcodeEnum.BiPush => OperandFormat.Byte,
            else => OperandFormat.NoOperand,
        };
    }

    pub fn getOperandLength(self: OpcodeEnum) usize {
        return switch (self) {
            OpcodeEnum.BiPush => 2, // 1 byte operand
            OpcodeEnum.IStore => 2, // istore <index>
            OpcodeEnum.ILoad => 2, // iload <index>
            OpcodeEnum.InvokeStatic => 3, // invokestatic <indexbyte1> <indexbyte2>
            else => 1, // nessun operand
        };
    }

    pub fn toString(self: OpcodeEnum) []const u8 {
        return switch (self) {
            OpcodeEnum.IConstM1 => "iconst_m1",
            OpcodeEnum.IConst0 => "iconst_0",
            OpcodeEnum.IConst1 => "iconst_1",
            OpcodeEnum.IConst2 => "iconst_2",
            OpcodeEnum.IConst3 => "iconst_3",
            OpcodeEnum.IConst4 => "iconst_4",
            OpcodeEnum.IConst5 => "iconst_5",
            OpcodeEnum.BiPush => "bipush",
            OpcodeEnum.ILoad => "iload",
            OpcodeEnum.ILoad0 => "iload_0",
            OpcodeEnum.ILoad1 => "iload_1",
            OpcodeEnum.ILoad2 => "iload_2",
            OpcodeEnum.ILoad3 => "iload_3",
            OpcodeEnum.ISub => "isub",
            OpcodeEnum.LLoad3 => "lload_3",
            OpcodeEnum.AALoad => "aaload",
            OpcodeEnum.IStore => "istore",
            OpcodeEnum.IStore1 => "istore_1",
            OpcodeEnum.IStore2 => "istore_2",
            OpcodeEnum.IStore3 => "istore_3",
            OpcodeEnum.IAdd => "iadd",
            OpcodeEnum.IMul => "imul",
            OpcodeEnum.InvokeStatic => "invokestatic",
            OpcodeEnum.IReturn => "ireturn",
            OpcodeEnum.Return => "return",
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
