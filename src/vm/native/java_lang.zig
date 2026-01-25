const std = @import("std");
const registry = @import("registry.zig");
const Value = @import("../interpreter/value.zig").Value;

pub const PrintStream = struct {
    stream: ?std.fs.File,
};

pub const JavaString = struct {
    bytes: []const u8,
};

pub fn registerAll(nr: *registry.NativeRegistry) !void {
    try nr.register(.{
        .class = "java/io/PrintStream",
        .name = "println",
        .signature = "(I)V",
        .func = println,
    });

    try nr.register(.{
        .class = "java/io/PrintStream",
        .name = "println",
        .signature = "(D)V",
        .func = println,
    });

    try nr.register(.{
        .class = "java/io/PrintStream",
        .name = "println",
        .signature = "(F)V",
        .func = println,
    });

    try nr.register(.{
        .class = "java/io/PrintStream",
        .name = "println",
        .signature = "(J)V",
        .func = println,
    });

    try nr.register(.{
        .class = "java/io/PrintStream",
        .name = "println",
        .signature = "(Z)V",
        .func = println,
    });

    try nr.register(.{
        .class = "java/io/PrintStream",
        .name = "println",
        .signature = "(C)V",
        .func = println,
    });

    try nr.register(.{
        .class = "java/io/PrintStream",
        .name = "println",
        .signature = "(Ljava/lang/String;)V",
        .func = println,
    });
}

fn println(env: *registry.NativeEnv, args: ?[]Value) !Value {
    const allocator = std.heap.page_allocator;

    if (args == null) {
        return error.InvalidArguments;
    }

    const value = args.?[0];

    var value_str: ?[]const u8 = null;

    switch (value) {
        .Int => |i| {
            value_str = std.fmt.allocPrint(allocator, "{}", .{i}) catch return error.OutOfMemory;
        },
        .Float => |f| {
            value_str = std.fmt.allocPrint(allocator, "{}", .{f}) catch return error.OutOfMemory;
        },
        .Double => |d| {
            value_str = std.fmt.allocPrint(allocator, "{}", .{d}) catch return error.OutOfMemory;
        },
        .Long => |l| {
            value_str = std.fmt.allocPrint(allocator, "{}", .{l}) catch return error.OutOfMemory;
        },
        .Reference => |r| {
            const js: *JavaString = @ptrCast(@alignCast(r));
            value_str = js.bytes;
        },
        else => {
            std.debug.print("Unsupported type for println: {any}\n", .{value});
        },
    }
    if (value_str) |vs| {
        _ = try env.stdout.write(vs);
        _ = try env.stdout.write("\n");
    } else {
        return error.UnsupportedStdFunction;
    }

    return Value._void();
}
