const std = @import("std");

fn readU1(r: []const u8) !u8 {
    return std.mem.readInt(u8, r[0..1], .big);
}

fn readU2(r: []const u8) !u16 {
    return std.mem.readInt(u16, r[0..2], .big);
}

fn readU4(r: []const u8) !u32 {
    return std.mem.readInt(u32, r[0..4], .big);
}

pub const ClassHeader = struct {
    magic: u32,
    minor: u16,
    major: u16,
    pool_count: u16,
};

pub fn parseHeader(r: anytype) !ClassHeader {
    const magic = try readU4(r);
    if (magic != 0xCAFEBABE)
        return error.InvalidClass;

    return .{
        .magic = magic,
        .minor = try readU2(r),
        .major = try readU2(r),
        .pool_count = try readU2(r),
    };
}

const CpTag = enum(u8) {
    Utf8 = 1,
    Integer = 3,
    Float = 4,
    Long = 5,
    Double = 6,
    Class = 7,
    String = 8,
};

const CpInfo = union(CpTag) {
    Utf8: []u8,
    Integer: i32,
    Float: f32,
    Long: i64,
    Double: f64,
    Class: u16,
    String: u16,
};
