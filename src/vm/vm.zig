const std = @import("std");
const s = @import("interpreter/jvm_stack.zig");
const f = @import("interpreter/frame.zig");
const registry = @import("native/registry.zig");
const Heap = @import("heap/heap.zig").Heap;
const JavaLang = @import("native/java_lang.zig");

pub const ZJVMGPA = std.heap.GeneralPurposeAllocator(.{ .enable_memory_limit = false, .safety = false });

pub const ZJVMJSON = struct {
    stack: s.JVMStackJSON,

    pub fn toJSON(zjvm: ZJVM) !ZJVMJSON {
        return ZJVMJSON{
            .stack = try zjvm.stack.toJSON(),
        };
    }
};

pub const ZJVM = struct {
    gpa: *const ZJVMGPA,
    allocator: std.mem.Allocator,

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

    pub fn getNativeEnv(self: *ZJVM, allocator: std.mem.Allocator) registry.NativeEnv {
        return registry.NativeEnv{
            .heap = &self.heap,
            .stdout = &self.stdout,
            .allocator = allocator,
        };
    }

    pub fn bootstrap(gpa: *ZJVMGPA, maxFrames: usize) !ZJVM {
        const heap_allocator = std.heap.page_allocator;
        const allocator = gpa.allocator();

        var nr = try registry.NativeRegistry.init(allocator);
        try JavaLang.registerAll(&nr);

        return ZJVM{
            .gpa = gpa,
            .allocator = allocator,
            .stack = try s.JVMStack.init(&allocator, maxFrames),
            .stdout = std.fs.File.stdout(),
            .stdin = std.fs.File.stdin(),
            .heap = Heap.init(heap_allocator),
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
