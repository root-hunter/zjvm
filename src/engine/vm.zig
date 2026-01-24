const std = @import("std");
const s = @import("../runtime/jvm_stack.zig");
const f = @import("../runtime/frame.zig");

pub const ZJVMJSON = struct {
    stack: s.JVMStackJSON,

    pub fn toJSON(zjvm: ZJVM) !ZJVMJSON {
        return ZJVMJSON{
            .stack = try zjvm.stack.toJSON(),
        };
    }
};

pub const ZJVM = struct {
    stack: s.JVMStack,

    pub fn init(allocator: *const std.mem.Allocator, maxFrames: usize) !ZJVM {
        return ZJVM{
            .stack = try s.JVMStack.init(allocator, maxFrames),
        };
    }

    pub fn pushFrame(self: *ZJVM, frame: f.Frame) !void {
        try self.stack.push(frame);
    }

    pub fn popFrame(self: *ZJVM) !f.Frame {
        return try self.stack.pop();
    }

    pub fn currentFrame(self: *ZJVM) ?*f.Frame {
        return self.stack.current();
    }

    pub fn toJSON(self: ZJVM) !ZJVMJSON {
        return try ZJVMJSON.toJSON(self);
    }
};
