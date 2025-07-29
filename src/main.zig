const std = @import("std");
const zigimg = @import("zigimg");
const AtlasBuilder = @import("atlas.zig").AtlasBuilder;

pub fn main() !void {
    return error.oopsy;
}

test "RefAllDeclsRecursive" {
    std.testing.refAllDeclsRecursive(AtlasBuilder);
}
