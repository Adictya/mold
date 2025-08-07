const std = @import("std");
const cl = @import("zclay");
const component = @import("./components.zig");

var fpsBuffer: [9]u8 = "FPS: 0000".*;
var frameTimeHistory: [60]f64 = [_]f64{0} ** 60; // Store 60 frame times
var historyIndex: usize = 0;
var frameCount: u32 = 0;

var containerComponent: ?component = null;
var txtComponent: ?component = null;

pub fn init() void {
    containerComponent = component{
        .id = .ID("Performance-panel"),
        .string_id = "Performance-panel",
        .ctype = .box,
        .view_props = .{
            .position = .{
                .offset = .{ .x = 0, .y = 0 },
                .parent_id = null,
                .z_index = 0,
                .attach_points = .{
                    .parent = .left_top,
                    .element = .left_top,
                },
                .attach_to = .to_root,
            },
            .style = .{
                .bg_color = .{ .color = .{ .rgb = .{ 0, 0, 0 } } },
            },
        },
    };

    txtComponent = component{
        .id = .ID("Performance-panel-text"),
        .string_id = "Performance-panel-text",
        .ctype = .text,
        .text_props = .{
            .bold = true,
            .fg_color = .{ .color = .{ .rgb = .{ 255, 255, 255 } } },
            .bg_color = .{ .color = .{ .rgb = .{ 0, 0, 0 } } },
        },
        .text = &fpsBuffer,
    };
}

pub fn updateFPS() void {
    const currentTime = std.time.nanoTimestamp();
    const currentTimeF = @as(f64, @floatFromInt(currentTime)) / std.time.ns_per_s;

    // Store current time in circular buffer
    frameTimeHistory[historyIndex] = currentTimeF;
    historyIndex = (historyIndex + 1) % frameTimeHistory.len;
    frameCount = @min(frameCount + 1, frameTimeHistory.len);

    if (frameCount < 2) return;

    // Calculate average FPS over the stored frame times
    const oldestIndex = if (frameCount < frameTimeHistory.len) 0 else historyIndex;
    const timeSpan = currentTimeF - frameTimeHistory[oldestIndex];
    const avgFps = if (timeSpan > 0) @as(f64, @floatFromInt(frameCount - 1)) / timeSpan else 0;

    const fps: u32 = @intFromFloat(@max(@min(avgFps, 9999), 0));
    _ = std.fmt.bufPrint(&fpsBuffer, "FPS: {d:0>4}", .{fps}) catch unreachable;
}

pub fn render() void {
    var config = containerComponent.?.view_props.toClay();
    config.user_data = @constCast(&containerComponent);
    config.background_color = .{ 255, 255, 255, 255 };
    cl.UI()(config)({
        var txtConfig = txtComponent.?.text_props.toClay();
        txtConfig.user_data = @constCast(&txtComponent);

        cl.text(&fpsBuffer, txtConfig);
    });
}
