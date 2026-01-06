const types = @import("types.zig");

pub const AccessFlags = enum(types.U2) {
    Public = 0x0001,
    Final = 0x0010,
    Super = 0x0020,
    Interface = 0x0200,
    Abstract = 0x0400,
    Synthetic = 0x1000,
    Annotation = 0x2000,
    Enum = 0x4000,
};

pub fn isPublic(flags: types.U2) bool {
    return (flags & AccessFlags.Public) != 0;
}

pub fn isFinal(flags: types.U2) bool {
    return (flags & AccessFlags.Final) != 0;
}

pub fn isSuper(flags: types.U2) bool {
    return (flags & AccessFlags.Super) != 0;
}

pub fn isInterface(flags: types.U2) bool {
    return (flags & AccessFlags.Interface) != 0;
}

pub fn isAbstract(flags: types.U2) bool {
    return (flags & AccessFlags.Abstract) != 0;
}

pub fn isSynthetic(flags: types.U2) bool {
    return (flags & AccessFlags.Synthetic) != 0;
}

pub fn isAnnotation(flags: types.U2) bool {
    return (flags & AccessFlags.Annotation) != 0;
}

pub fn isEnum(flags: types.U2) bool {
    return (flags & AccessFlags.Enum) != 0;
}