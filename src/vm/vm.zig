const std = @import("std");
const s = @import("interpreter/jvm_stack.zig");
const f = @import("interpreter/frame.zig");
const registry = @import("native/registry.zig");
const Heap = @import("heap/heap.zig").Heap;
const JavaLang = @import("native/java_lang.zig");
const JVMInterpreter = @import("interpreter/exec.zig").JVMInterpreter;
const ClassInfo = @import("class/parser.zig").ClassInfo;
const utils = @import("../utils.zig");
const MethodInfo = @import("class/methods.zig").MethodInfo;
const Frame = @import("interpreter/frame.zig").Frame;

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

    classes: std.StringHashMap(*ClassInfo),

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
            .classes = std.StringHashMap(*ClassInfo).init(allocator),
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

    pub fn execute(self: *ZJVM) !void {
        try JVMInterpreter.execute(self);
    }

    pub fn parseClassFile(self: *ZJVM, data: []const u8) !ClassInfo {
        var cursor = utils.Cursor.init(data);
        var classInfo = ClassInfo.init(&self.allocator);

        try classInfo.parse(&cursor);

        return classInfo;
    }

    pub fn loadClassFromFile(self: *ZJVM, path: []const u8) !void {
        // std.debug.print("Loading class file: {s}\n", .{path});

        var file = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
        defer file.close();

        const file_size = try file.getEndPos();
        const data = try file.readToEndAlloc(self.allocator, file_size);

        var classInfoPtr = try self.allocator.create(ClassInfo);
        errdefer self.allocator.destroy(classInfoPtr);

        classInfoPtr.* = try self.parseClassFile(data);

        const classNameLen = classInfoPtr.getClassName().len;
        const classNamePtr = try self.allocator.alloc(u8, classNameLen);

        std.mem.copyBackwards(u8, classNamePtr, classInfoPtr.getClassName());

        try self.classes.put(classNamePtr, classInfoPtr);

        // std.debug.print("Loaded class: {s}\n", .{classNamePtr});
    }

    pub fn getMethodFromClass(self: *ZJVM, className: []const u8, methodName: []const u8) !?MethodInfo {
        const ci = self.classes.get(className);
        if (ci) |classInfo| {
            return try classInfo.getMethod(methodName);
        }
        return null;
    }

    pub fn getClassInfo(self: *ZJVM, className: []const u8) ?*ClassInfo {
        return self.classes.get(className);
    }

    pub fn execClassMethod(self: *ZJVM, className: []const u8, methodName: []const u8) !void {
        _ = try self.execClassMethodReturnFrame(className, methodName);
    }

    pub fn execClassMethodReturnFrame(self: *ZJVM, className: []const u8, methodName: []const u8) !Frame {
        const method = try self.getMethodFromClass(className, methodName);
        if (method) |m| {
            if (m.code) |codeAttr| {
                // std.debug.print("Executing method: {s}.{s}\n", .{ className, methodName });

                const classInfo = self.getClassInfo(className).?;
                const frame = try f.Frame.init(self.allocator, &codeAttr, classInfo);

                try self.pushFrame(frame);
                try self.execute();

                return frame;
            } else {
                return error.MethodHasNoCode;
            }
        } else {
            return error.MethodNotFound;
        }
    }
};
