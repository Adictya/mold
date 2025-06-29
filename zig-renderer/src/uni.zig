const std = @import("std");
const unicode = std.unicode;

pub fn codepointToUtf8Bytes(
    codepoint: u21,
    buffer: []u8,
) ![]u8 {
    // std.unicode.utf8Encode writes the UTF-8 bytes into the buffer
    // and returns the number of bytes written.
    const bytes_written = try std.unicode.utf8Encode(codepoint, buffer);
    return buffer[0..bytes_written];
}

test "Unicode normalization" {
    var buffer: [4]u8 = undefined;
    const input: u21 = '─';
    const normalized = codepointToUtf8Bytes(input, &buffer) catch |err| {
        std.debug.print("Error normalizing codepoint: {}\n", .{err});
        return;
    };

    std.debug.print("Normalized codepoint: {s}\n", .{normalized});
}

test "float convert" {
    const h: f32 = 1.0;

    const height: usize = @intFromFloat(h);

    std.debug.print("Height: {}\n", .{height});

    const iHeight: i8 = @intFromFloat(h);

    std.debug.print("iHeight: {}\n", .{iHeight});
}
