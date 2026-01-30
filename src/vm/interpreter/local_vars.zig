const std = @import("std");
const Value = @import("value.zig").Value;
const ValueJSON = @import("value.zig").ValueJSON;

pub const LocalVarsJSON = struct {
    vars: []ValueJSON,

    pub fn init(local_vars: LocalVars) !LocalVarsJSON {
        const allocator = std.heap.page_allocator;
        var vars_json = try std.ArrayList(ValueJSON).initCapacity(allocator, local_vars.vars.len);
        defer vars_json.deinit(allocator);

        for (local_vars.vars) |v| {
            try vars_json.append(allocator, try v.toJSON());
        }

        return LocalVarsJSON{
            .vars = try vars_json.toOwnedSlice(allocator),
        };
    }
};

pub const LocalVars = struct {
    vars: []Value,

    pub fn init(allocator: std.mem.Allocator, count: usize) !LocalVars {
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

    pub fn toJSON(self: LocalVars) !LocalVarsJSON {
        return try LocalVarsJSON.init(self);
    }
};
