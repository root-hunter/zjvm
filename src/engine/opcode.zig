pub const OpcodeEnum = enum(u8) {
    IConstM1 = 0x02,
    IConst0 = 0x03,
    IConst1 = 0x04,
    IConst2 = 0x05,
    IConst3 = 0x06,
    IConst4 = 0x07,
    IConst5 = 0x08,
    BiPush = 0x10,
    LLoad3 = 0x21,
    IStore1 = 0x3c,
    IAdd = 0x60,
    IReturn = 0xac,
    Return = 0xb1,

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
            OpcodeEnum.LLoad3 => "lload_3",
            OpcodeEnum.IStore1 => "istore_1",
            OpcodeEnum.IAdd => "iadd",
            OpcodeEnum.IReturn => "ireturn",
            OpcodeEnum.Return => "return",
        };
    }
};
