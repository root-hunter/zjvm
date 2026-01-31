const std = @import("std");
const parser = @import("vm/class//parser.zig");
const ac = @import("vm/class/access_flags.zig");
const utils = @import("utils.zig");

const fr = @import("vm/interpreter/frame.zig");
const JVMInterpreter = @import("vm/interpreter/exec.zig").JVMInterpreter;
const ZJVM = @import("vm/vm.zig").ZJVM;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .enable_memory_limit = false, .safety = false }){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var vm = try ZJVM.bootstrap(&gpa, 1024);

    var argv = try std.process.argsWithAllocator(allocator);
    defer argv.deinit();

    _ = argv.next();

    const class_path = argv.next() orelse {
        std.debug.print("Usage: zjvm <ClassFilePath>\n", .{});
        return;
    };

    try vm.loadClassFromFile(class_path);

    var keys = vm.classes.keyIterator();
    while (keys.next()) |key| {
        std.debug.print("Loaded class key: {s}\n", .{key.*});
    }

    _ = try vm.execClassMethodReturnFrame("BigIterationPrint", "main");
    // frame.dump();
}
