const std = @import("std");

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8 = 255, // Alpha channel (optional)
};

const BG_BLACK = "\x1b[40m";
const BG_RED = "\x1b[41m";
const BG_GREEN = "\x1b[42m";
const BG_YELLOW = "\x1b[43m";
const BG_BLUE = "\x1b[44m";
const BG_MAGENTA = "\x1b[45m";
const BG_CYAN = "\x1b[46m";
const BG_WHITE = "\x1b[47m";

const AnsiColor = struct {
    r: u8,
    g: u8,
    b: u8,
    ansi: []const u8,
};

const ANSI_COLORS = [_]AnsiColor{
    .{ .r = 0, .g = 0, .b = 0, .ansi = BG_BLACK },       // Black
    .{ .r = 128, .g = 0, .b = 0, .ansi = BG_RED },       // Red
    .{ .r = 0, .g = 128, .b = 0, .ansi = BG_GREEN },     // Green
    .{ .r = 128, .g = 128, .b = 0, .ansi = BG_YELLOW },  // Yellow
    .{ .r = 0, .g = 0, .b = 128, .ansi = BG_BLUE },      // Blue
    .{ .r = 128, .g = 0, .b = 128, .ansi = BG_MAGENTA }, // Magenta
    .{ .r = 0, .g = 128, .b = 128, .ansi = BG_CYAN },    // Cyan
    .{ .r = 192, .g = 192, .b = 192, .ansi = BG_WHITE }, // White
};

fn colorDistance(c1: Color, c2: AnsiColor) f32 {
    const dr = @as(f32, @floatFromInt(c1.r)) - @as(f32, @floatFromInt(c2.r));
    const dg = @as(f32, @floatFromInt(c1.g)) - @as(f32, @floatFromInt(c2.g));
    const db = @as(f32, @floatFromInt(c1.b)) - @as(f32, @floatFromInt(c2.b));
    return dr * dr + dg * dg + db * db; // Squared Euclidean distance
}

pub fn getClosestAnsiBackground(color: Color) []const u8 {
    var closest_distance: f32 = std.math.floatMax(f32);
    var closest_ansi: []const u8 = BG_BLACK;

    for (ANSI_COLORS) |ansi_color| {
        const distance = colorDistance(color, ansi_color);
        if (distance < closest_distance) {
            closest_distance = distance;
            closest_ansi = ansi_color.ansi;
        }
    }

    return closest_ansi;
}

// Example usage
pub fn main() void {
    const red_color = Color{ .r = 255, .g = 0, .b = 0 };
    const bg_code = getClosestAnsiBackground(red_color);
    std.debug.print("Background code: {s}\n", .{bg_code});

    const dark_blue = Color{ .r = 0, .g = 0, .b = 100 };
    const bg_code2 = getClosestAnsiBackground(dark_blue);
    std.debug.print("Background code: {s}\n", .{bg_code2});
}
