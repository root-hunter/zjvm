const std = @import("std");
const Frame = @import("frame.zig").Frame;
const FrameJSON = @import("frame.zig").FrameJSON;

pub const JVMStackJSON = struct {
    frames: []FrameJSON,
    top: usize,

    pub fn init(stack: JVMStack) !JVMStackJSON {
        const allocator = std.heap.page_allocator;
        var frames_json = try std.ArrayList(FrameJSON).initCapacity(allocator, stack.top);

        defer frames_json.deinit(allocator);

        for (stack.frames[0..stack.top]) |f| {
            try frames_json.append(allocator, try FrameJSON.init(f));
        }
        return JVMStackJSON{
            .frames = try frames_json.toOwnedSlice(allocator),
            .top = stack.top,
        };
    }
};

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

    pub fn toJSON(self: JVMStack) !JVMStackJSON {
        return try JVMStackJSON.init(self);
    }
};
