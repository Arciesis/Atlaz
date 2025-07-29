const std = @import("std");
const zigimg = @import("zigimg");

const NUM_CHAN: u32 = 4;

const AtlasMetadata = struct {
    total_width: usize,
    total_height: usize,
};

pub const AtlasBuilder = struct {
    imgs: std.StringArrayHashMap(zigimg.Image),
    metadata: AtlasMetadata,

    pub fn init(allocator: std.mem.Allocator) anyerror!AtlasBuilder {
        const cwd = std.fs.cwd();
        var assets_dir = try cwd.openDir("assets/", std.fs.Dir.OpenOptions{ .iterate = true });
        defer assets_dir.close();

        return AtlasBuilder{
            .imgs = try getAllImages(allocator, assets_dir),
            .metadata = AtlasMetadata{
                .total_width = 0,
                .total_height = 0,
            },
        };
    }

    pub fn deinit(self: *AtlasBuilder, allocator: std.mem.Allocator) void {
        self.imgs.clearAndFree();
        _ = allocator;
        // allocator.destroy(self);
    }

    fn getAllImages(allocator: std.mem.Allocator, basedir: std.fs.Dir) anyerror!std.StringArrayHashMap(zigimg.Image) {
        var path_to_image = std.StringArrayHashMap(zigimg.Image).init(allocator);
        const extension: []const u8 = ".png";

        var walker = try basedir.walk(allocator);
        defer walker.deinit();

        var entry = try walker.next();
        while (entry) |file_entry| : (entry = try walker.next()) {
            if (file_entry.kind == std.fs.Dir.Entry.Kind.directory) {
                continue;
            }

            if (file_entry.kind == std.fs.Dir.Entry.Kind.file) {
                const fp = try file_entry.dir.realpathAlloc(allocator, file_entry.basename);
                defer allocator.free(fp);

                // const fp_imutz = try allocator.dupeZ(u8, fp);
                // defer allocator.free(fp_imutz);

                if (!std.mem.endsWith(u8, fp, extension)) {
                    continue;
                }

                const key: []const u8 = try allocator.dupe(u8, fp);
                defer allocator.free(key);
                var value = try zigimg.Image.fromFilePath(allocator, fp);

                var value_ptr = &value;
                defer value_ptr.deinit();

                // forced num components = rgba => 4 channels
                try path_to_image.put(key, value);
            }
        }
        return path_to_image;
    }
};

test "if getAllImages works correctly" {
    var ab = try AtlasBuilder.init(std.testing.allocator);
    defer ab.deinit(std.testing.allocator);

    var idx: usize = 0;
    var img = ab.imgs.pop();
    while (img) |current_img| : (img = ab.imgs.pop()) {
        _ = current_img;

        idx = idx + 1;
    }

    try std.testing.expectEqual(54, idx);
}
