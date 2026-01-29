const std = @import("std");
const s = @import("interpreter/jvm_stack.zig");
const f = @import("interpreter/frame.zig");
const registry = @import("native/registry.zig");
const Heap = @import("heap/heap.zig").Heap;
const JavaLang = @import("native/java_lang.zig");

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
    nr: registry.NativeRegistry,
    heap: Heap,

    stdout: std.fs.File,
    stdin: std.fs.File,

    pub fn setStdout(self: *ZJVM, file: std.fs.File) void {
        self.stdout = file;
    }

    pub fn setStdin(self: *ZJVM, file: std.fs.File) void {
        self.stdin = file;
    }

    pub fn getNativeEnv(self: *ZJVM) registry.NativeEnv {
        return registry.NativeEnv{
            .heap = &self.heap,
            .stdout = &self.stdout,
        };
    }

    pub fn init(allocator: *const std.mem.Allocator, maxFrames: usize) !ZJVM {
        const alloc = std.heap.page_allocator;
        var nr = try registry.NativeRegistry.init(alloc);
        try JavaLang.registerAll(&nr);

        return ZJVM{
            .stack = try s.JVMStack.init(allocator, maxFrames),
            .stdout = std.fs.File.stdout(),
            .stdin = std.fs.File.stdin(),
            .heap = Heap.init(alloc),
            .nr = nr,
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
