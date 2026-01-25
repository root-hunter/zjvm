const std = @import("std");
const parser = @import("../class/parser.zig");
const Value = @import("../interpreter/value.zig").Value;

pub const Object = struct {
    classInfo: *parser.ClassInfo,
    // Add fields for instance variables, methods, etc.
    fields: std.AutoHashMap([]const u8, Value),

    pub fn init(allocator: std.mem.Allocator, classInfo: *parser.ClassInfo) !Object {
        return Object{
            .classInfo = classInfo,
            .fields = std.AutoHashMap([]const u8, Value).init(allocator),
        };
    }

    pub fn deinit(self: *Object) void {
        // Clean up resources if necessary
        _ = self;
    }
};
