const types = @import("types.zig");

pub const ClassAccessFlags = enum(types.U2) {
    Public = 0x0001,
    Final = 0x0010,
    Super = 0x0020,
    Interface = 0x0200,
    Abstract = 0x0400,
    Synthetic = 0x1000,
    Annotation = 0x2000,
    Enum = 0x4000,

    pub fn isPublic(flags: types.U2) bool {
        return (flags & @intFromEnum(ClassAccessFlags.Public)) != 0;
    }

    pub fn isFinal(flags: types.U2) bool {
        return (flags & @intFromEnum(ClassAccessFlags.Final)) != 0;
    }

    pub fn isSuper(flags: types.U2) bool {
        return (flags & @intFromEnum(ClassAccessFlags.Super)) != 0;
    }

    pub fn isInterface(flags: types.U2) bool {
        return (flags & @intFromEnum(ClassAccessFlags.Interface)) != 0;
    }

    pub fn isAbstract(flags: types.U2) bool {
        return (flags & @intFromEnum(ClassAccessFlags.Abstract)) != 0;
    }

    pub fn isSynthetic(flags: types.U2) bool {
        return (flags & @intFromEnum(ClassAccessFlags.Synthetic)) != 0;
    }

    pub fn isAnnotation(flags: types.U2) bool {
        return (flags & @intFromEnum(ClassAccessFlags.Annotation)) != 0;
    }

    pub fn isEnum(flags: types.U2) bool {
        return (flags & @intFromEnum(ClassAccessFlags.Enum)) != 0;
    }
};

pub const FieldAccessFlags = enum(types.U2) {
    Public = 0x0001,
    Private = 0x0002,
    Protected = 0x0004,
    Static = 0x0008,
    Final = 0x0010,
    Volatile = 0x0040,
    Transient = 0x0080,
    Synthetic = 0x1000,
    Enum = 0x4000,

    pub fn isPublic(flags: types.U2) bool {
        return (flags & @intFromEnum(FieldAccessFlags.Public)) != 0;
    }

    pub fn isPrivate(flags: types.U2) bool {
        return (flags & @intFromEnum(FieldAccessFlags.Private)) != 0;
    }

    pub fn isProtected(flags: types.U2) bool {
        return (flags & @intFromEnum(FieldAccessFlags.Protected)) != 0;
    }

    pub fn isStatic(flags: types.U2) bool {
        return (flags & @intFromEnum(FieldAccessFlags.Static)) != 0;
    }

    pub fn isFinal(flags: types.U2) bool {
        return (flags & @intFromEnum(FieldAccessFlags.Final)) != 0;
    }

    pub fn isVolatile(flags: types.U2) bool {
        return (flags & @intFromEnum(FieldAccessFlags.Volatile)) != 0;
    }

    pub fn isTransient(flags: types.U2) bool {
        return (flags & @intFromEnum(FieldAccessFlags.Transient)) != 0;
    }

    pub fn isSynthetic(flags: types.U2) bool {
        return (flags & @intFromEnum(FieldAccessFlags.Synthetic)) != 0;
    }

    pub fn isEnum(flags: types.U2) bool {
        return (flags & @intFromEnum(FieldAccessFlags.Enum)) != 0;
    }
};

pub const MethodAccessFlags = enum(types.U2) {
    Public = 0x0001,
    Private = 0x0002,
    Protected = 0x0004,
    Static = 0x0008,
    Final = 0x0010,
    Synchronized = 0x0020,
    Bridge = 0x0040,
    Varargs = 0x0080,
    Native = 0x0100,
    Abstract = 0x0400,
    Strict = 0x0800,
    Synthetic = 0x1000,

    pub fn isPublic(flags: types.U2) bool {
        return (flags & @intFromEnum(MethodAccessFlags.Public)) != 0;
    }

    pub fn isPrivate(flags: types.U2) bool {
        return (flags & @intFromEnum(MethodAccessFlags.Private)) != 0;
    }

    pub fn isProtected(flags: types.U2) bool {
        return (flags & @intFromEnum(MethodAccessFlags.Protected)) != 0;
    }

    pub fn isStatic(flags: types.U2) bool {
        return (flags & @intFromEnum(MethodAccessFlags.Static)) != 0;
    }

    pub fn isFinal(flags: types.U2) bool {
        return (flags & @intFromEnum(MethodAccessFlags.Final)) != 0;
    }

    pub fn isSynchronized(flags: types.U2) bool {
        return (flags & @intFromEnum(MethodAccessFlags.Synchronized)) != 0;
    }

    pub fn isBridge(flags: types.U2) bool {
        return (flags & @intFromEnum(MethodAccessFlags.Bridge)) != 0;
    }

    pub fn isVarargs(flags: types.U2) bool {
        return (flags & @intFromEnum(MethodAccessFlags.Varargs)) != 0;
    }

    pub fn isNative(flags: types.U2) bool {
        return (flags & @intFromEnum(MethodAccessFlags.Native)) != 0;
    }

    pub fn isAbstract(flags: types.U2) bool {
        return (flags & @intFromEnum(MethodAccessFlags.Abstract)) != 0;
    }

    pub fn isStrict(flags: types.U2) bool {
        return (flags & @intFromEnum(MethodAccessFlags.Strict)) != 0;
    }

    pub fn isSynthetic(flags: types.U2) bool {
        return (flags & @intFromEnum(MethodAccessFlags.Synthetic)) != 0;
    }
};