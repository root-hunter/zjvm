const std = @import("std");
const Value = @import("value.zig").Value;

pub const LocalVars = struct {
    vars: []Value,

    pub fn init(allocator: *std.mem.Allocator, count: usize) !LocalVars {
        return LocalVars{
            .vars = try allocator.alloc(Value, count),
        };
    }

    pub fn set(self: *LocalVars, index: usize, v: Value) void {
        self.vars[index] = v;
    }

    pub fn get(self: *LocalVars, index: usize) Value {
        return self.vars[index];
    }
};