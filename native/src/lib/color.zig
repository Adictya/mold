const std = @import("std");
const vaxis = @import("vaxis");

const Color = vaxis.Color;

pub fn parseHexColor(hex: []const u8) !Color {
    if (hex.len == 7) {
        return .{
            .rgb = .{
                @as(u8, try std.fmt.parseInt(u8, hex[1..3], 16)),
                @as(u8, try std.fmt.parseInt(u8, hex[3..5], 16)),
                @as(u8, try std.fmt.parseInt(u8, hex[5..7], 16)),
            },
        };
    } else if (hex.len == 4) {
        return .{
            .rgb = .{
                @as(u8, try std.fmt.parseInt(u8, hex[1..2], 16)) * 0x11,
                @as(u8, try std.fmt.parseInt(u8, hex[2..3], 16)) * 0x11,
                @as(u8, try std.fmt.parseInt(u8, hex[3..4], 16)) * 0x11,
            },
        };
    } else {
        std.log.debug("Invalid hex color: {s}", .{hex});
        return error.InvalidHexColor;
    }
}
