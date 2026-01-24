const std = @import("std");
const types = @import("types.zig");

pub const BootstrapMethodInfo = struct {
    bootstrap_method_ref: types.U2,
    num_bootstrap_arguments: types.U2,
    bootstrap_arguments: []types.U2,
};
