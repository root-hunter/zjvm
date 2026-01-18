pub const U1 = u8;
pub const U2 = u16;
pub const U4 = u32;

pub const Utf8Info = struct {
    length: U2,
    bytes: []const u8,
};