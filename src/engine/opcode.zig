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
    ILoad = 0x15,
    ILoad0 = 0x1a,
    ILoad1 = 0x1b,
    ILoad2 = 0x1c,
    ILoad3 = 0x1d,
    LLoad3 = 0x21,
    AALoad = 0x32,
    IStore = 0x36,
    IStore0 = 0x3b,
    IStore1 = 0x3c,
    IStore2 = 0x3d,
    IStore3 = 0x3e,
    ISub = 0x64,
    IAdd = 0x60,
    IMul = 0x68,
    IDiv = 0x6c,
    IRem = 0x70,
    IInc = 0x84,
    IfCmpGe = 0xa2,
    IfCmpLe = 0xa4,
    GoTo = 0xa7,
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
            OpcodeEnum.SiPush => 3, // 2 byte operand
            OpcodeEnum.IStore => 2, // istore <index>
            OpcodeEnum.ILoad => 2, // iload <index>
            OpcodeEnum.IInc => 3, // iinc <index> <const>
            OpcodeEnum.IfCmpGe => 3, // if_icmpge <branchbyte1> <branchbyte2>   
            OpcodeEnum.IfCmpLe => 3, // if_icmple <branchbyte1> <branchbyte2>
            OpcodeEnum.GoTo => 3, // goto <branchbyte1> <branchbyte2>
            OpcodeEnum.InvokeStatic => 3, // invokestatic <indexbyte1> <indexbyte2>
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
            OpcodeEnum.ILoad => "iload",
            OpcodeEnum.ILoad0 => "iload_0",
            OpcodeEnum.ILoad1 => "iload_1",
            OpcodeEnum.ILoad2 => "iload_2",
            OpcodeEnum.ILoad3 => "iload_3",
            OpcodeEnum.ISub => "isub",
            OpcodeEnum.LLoad3 => "lload_3",
            OpcodeEnum.AALoad => "aaload",
            OpcodeEnum.IStore => "istore",
            OpcodeEnum.IStore0 => "istore_0",
            OpcodeEnum.IStore1 => "istore_1",
            OpcodeEnum.IStore2 => "istore_2",
            OpcodeEnum.IStore3 => "istore_3",
            OpcodeEnum.IAdd => "iadd",
            OpcodeEnum.IMul => "imul",
            OpcodeEnum.IDiv => "idiv",
            OpcodeEnum.IRem => "irem",
            OpcodeEnum.IInc => "iinc",
            OpcodeEnum.IfCmpGe => "if_icmpge",
            OpcodeEnum.IfCmpLe => "if_icmple",
            OpcodeEnum.InvokeStatic => "invokestatic",
            OpcodeEnum.GoTo => "goto",
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
