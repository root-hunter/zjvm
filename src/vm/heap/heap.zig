const std = @import("std");
const Object = @import("object.zig").Object;
const parser = @import("../class/parser.zig");

pub const Heap = struct {
    allocator: std.mem.Allocator,
    objects: std.AutoHashMap(usize, Object),

    pub fn init(allocator: std.mem.Allocator) Heap {
        return Heap{
            .allocator = allocator,
            .objects = std.AutoHashMap(usize, Object).init(allocator),
        };
    }
    pub fn allocateObject(self: *Heap, classInfo: *parser.ClassInfo) !usize {
        const obj = try Object.init(self.allocator, classInfo);
        const objPtr = @intFromPtr(&obj);
        try self.objects.put(objPtr, obj);
        return objPtr;
    }
    pub fn getObject(self: *Heap, ref: usize) ?*Object {
        return self.objects.get(ref);
    }
    pub fn deinit(self: *Heap) void {
        var it = self.objects.iterator();
        while (it.next()) |entry| {
            entry.value.deinit();
        }
        self.objects.deinit();
    }
};
