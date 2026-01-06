pub const CpTag = enum(u8) {
    Utf8 = 1,
    Integer = 3,
    Float = 4,
    Long = 5,
    Double = 6,
    Class = 7,
    String = 8,
    Fieldref = 9,
    Methodref = 10,
    InterfaceMethodref = 11,
    NameAndType = 12,
    MethodHandle = 15,
    MethodType = 16,
    Dynamic = 17,
    InvokeDynamic = 18,
    Module = 19,
    Package = 20,
};

pub const CpInfo = union(CpTag) {
    Utf8: []u8,
    Integer: i32,
    Float: f32,
    Long: i64,
    Double: f64,
    Class: u16,
    String: u16,
    Fieldref: struct {
        class_index: u16,
        name_and_type_index: u16,
    },
    Methodref: struct {
        class_index: u16,
        name_and_type_index: u16,
    },
    InterfaceMethodref: struct {
        class_index: u16,
        name_and_type_index: u16,
    },
    NameAndType: struct {
        name_index: u16,
        descriptor_index: u16,
    },
    MethodHandle: struct {
        reference_kind: u8,
        reference_index: u16,
    },
    MethodType: u16,
    Dynamic: struct {
        bootstrap_method_attr_index: u16,
        name_and_type_index: u16,
    },
    InvokeDynamic: struct {
        bootstrap_method_attr_index: u16,
        name_and_type_index: u16,
    },
    Module: u16,
    Package: u16,
};