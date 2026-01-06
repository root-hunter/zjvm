const std = @import("std");
const types = @import("types.zig");

pub const Cursor = struct {
    buffer: []const u8,
    position: usize,

    pub fn init(buffer: []const u8) Cursor {
        return Cursor{
            .buffer = buffer,
            .position = 0,
        };
    }

    pub fn readU1(self: *Cursor) !types.U1 {
        if (self.position + 1 > self.buffer.len) {
            return error.UnableToRead;
        }
        const value = self.buffer[self.position];
        self.position += 1;
        return value;
    }

    pub fn readU2(self: *Cursor) !types.U2 {
        if (self.position + 2 > self.buffer.len) {
            return error.UnableToRead;
        }

        const slice = self.buffer[self.position .. self.position + 2];
        const arr_ptr: *const [2]u8 = @ptrCast(slice.ptr);

        const value = std.mem.readInt(types.U2, arr_ptr, .big);
        self.position += 2;
        return value;
    }

    pub fn readU4(self: *Cursor) !types.U4 {
        if (self.position + 4 > self.buffer.len) {
            return error.UnableToRead;
        }

        const slice = self.buffer[self.position .. self.position + 4];
        const arr_ptr: *const [4]u8 = @ptrCast(slice.ptr);

        const value = std.mem.readInt(types.U4, arr_ptr, .big);
        self.position += 4;
        return value;
    }

    pub fn readBytes(self: *Cursor, length: usize) ![]const u8 {
        if (self.position + length > self.buffer.len) {
            return error.UnableToRead;
        }
        const bytes = self.buffer[self.position .. self.position + length];
        self.position += length;
        return bytes;
    }
};