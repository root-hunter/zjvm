const std = @import("std");

pub const ValueJSON = struct {
    tag: []const u8,
    value: ?[]const u8,

    pub fn init(v: Value) !ValueJSON {
        const allocator = std.heap.page_allocator;

        return switch (v) {
            .Int => ValueJSON{
                .tag = "Int",
                .value = try std.fmt.allocPrint(allocator, "{}", .{v.Int}),
            },
            .Float => ValueJSON{
                .tag = "Float",
                .value = try std.fmt.allocPrint(allocator, "{}", .{v.Float}),
            },
            .Long => ValueJSON{
                .tag = "Long",
                .value = try std.fmt.allocPrint(allocator, "{}", .{v.Long}),
            },
            .Double => ValueJSON{
                .tag = "Double",
                .value = try std.fmt.allocPrint(allocator, "{}", .{v.Double}),
            },
            .Reference => ValueJSON{
                .tag = "Reference",
                .value = try std.fmt.allocPrint(allocator, "{}", .{&v.Reference.?}),
            },
            .ArrayRef => ValueJSON{
                .tag = "ArrayRef",
                .value = try std.fmt.allocPrint(allocator, "{}", .{&v.ArrayRef.?}),
            },
            .Top => ValueJSON{
                .tag = "Top",
                .value = try std.fmt.allocPrint(allocator, "null", .{}),
            },
        };
    }
};

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
    Reference: ?*anyopaque,
    ArrayRef: ?*[]Value,
    Top: void,

    pub fn toJSON(self: Value) !ValueJSON {
        return try ValueJSON.init(self);
    }
    
    pub fn _void() Value {
        return Value{ .Top = {} };
    }
};
