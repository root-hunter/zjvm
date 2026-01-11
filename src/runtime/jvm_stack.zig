const std = @import("std");
const Frame = @import("frame.zig").Frame;

pub const JVMStack = struct {
    frames: []Frame,
    top: usize,

    pub fn init(allocator: *const std.mem.Allocator, max: usize) !JVMStack {
        return JVMStack{
            .frames = try allocator.alloc(Frame, max),
            .top = 0,
        };
    }

    pub fn push(self: *JVMStack, frame: Frame) !void {
        self.frames[self.top] = frame;
        self.top += 1;
    }

    pub fn pop(self: *JVMStack) !Frame {
        self.top -= 1;
        return self.frames[self.top];
    }

    pub fn current(self: *JVMStack) *Frame {
        return &self.frames[self.top - 1];
    }
};
