const std = @import("std");
const Value = @import("../interpreter/value.zig").Value;

pub const NativeEnv = struct {
    // placeholder: heap, vm, thread, ecc
    heap: *anyopaque,
    stdout: *const std.fs.File,
};

pub const NativeFn = fn (
    env: *NativeEnv,
    args: ?[]Value,
) anyerror!Value;

pub const NativeMethod = struct {
    class: []const u8,
    name: []const u8,
    signature: []const u8,
    func: *const NativeFn,
};

pub const NativeRegistry = struct {
    allocator: std.mem.Allocator = undefined,
    methods: std.ArrayList(NativeMethod) = undefined,

    pub fn init(allocator: std.mem.Allocator) !NativeRegistry {
        return NativeRegistry{
            .allocator = allocator,
            .methods = try std.ArrayList(NativeMethod).initCapacity(allocator, 16),
        };
    }

    pub fn register(self: *NativeRegistry, method: NativeMethod) !void {
        try self.methods.append(self.allocator, method);
    }

    pub fn find(
        self: *const NativeRegistry,
        class: []const u8,
        name: []const u8,
        sig: []const u8,
    ) ?*const NativeFn {
        for (self.methods.items) |m| {
            if (std.mem.eql(u8, m.class, class) and
                std.mem.eql(u8, m.name, name) and
                std.mem.eql(u8, m.signature, sig))
            {
                return m.func;
            }
        }
        return null;
    }
};
