pub const ValueTag = enum(u8) {
    Int = 1,
    Float = 2,
    Long = 3,
    Double = 4,
    Reference = 5,
    ArrayRef = 6,
    Top = 0,
};

pub const Value = union(ValueTag) {
    Int: i32,
    Float: f32,
    Long: i64,
    Double: f64,
    Reference: usize,
    ArrayRef: ?*[]Value,
    Top: void,
};