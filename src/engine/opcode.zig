pub const OpcodeEnum = enum(u8) {
    IConstM1 = 0x02,
    IConst0 = 0x03,
    IConst1 = 0x04,
    IConst2 = 0x05,
    IConst3 = 0x06,
    IConst4 = 0x07,
    IConst5 = 0x08,
    BiPush = 0x10,
    IStore1 = 0x3c,
    IAdd = 0x60,
    IReturn = 0xac,
    Return = 0xb1,
};
