const std = @import("std");
const Value = @import("value.zig").Value;

pub const LocalVars = struct {
    vars: []Value,

    pub fn init(allocator: *const std.mem.Allocator, count: usize) !LocalVars {
        const vars = try allocator.alloc(Value, count);
        // Inizializza tutte le variabili a Top
        for (vars) |*v| {
            v.* = Value{ .Top = {} };
        }
        return LocalVars{
            .vars = vars,
        };
    }

    pub fn set(self: *LocalVars, index: usize, v: Value) void {
        self.vars[index] = v;
    }

    pub fn get(self: *LocalVars, index: usize) Value {
        return self.vars[index];
    }
};
