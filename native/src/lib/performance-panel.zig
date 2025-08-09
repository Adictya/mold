const std = @import("std");
const vaxis = @import("vaxis");
const cl = @import("zclay");
const component = @import("./components.zig");

const log = std.log.scoped(.performance);

var performanceBuffer: [256]u8 = "                                                                                                                                                                                                                                                                ".*;
var frametimeBuffer: [25]u8 = "                         ".*;
pub var lastFrameStart: f64 = 0;

pub var lastFrameTime: f64 = 0;

var lockStartTime: i128 = 0;
var clayStartTime: i128 = 0;
var validateStartTime: i128 = 0;
var renderStartTime: i128 = 0;
var flushStartTime: i128 = 0;

var lockTime: f64 = 0;
var clayTime: f64 = 0;
var validateTime: f64 = 0;
var renderTime: f64 = 0;
var flushTime: f64 = 0;

var rerenderCalls: u64 = 0;
var droppedRerenders: u64 = 0;

pub fn startLockTiming() void {
    lockStartTime = std.time.nanoTimestamp();
}

pub fn endLockTiming() void {
    const endTime = std.time.nanoTimestamp();
    lockTime = @as(f64, @floatFromInt(endTime - lockStartTime)) / std.time.ns_per_ms;
}

pub fn startClayTiming() void {
    clayStartTime = std.time.nanoTimestamp();
}

pub fn endClayTiming() void {
    const endTime = std.time.nanoTimestamp();
    clayTime = @as(f64, @floatFromInt(endTime - clayStartTime)) / std.time.ns_per_ms;
}

pub fn startValidateTiming() void {
    validateStartTime = std.time.nanoTimestamp();
}

pub fn endValidateTiming() void {
    const endTime = std.time.nanoTimestamp();
    validateTime = @as(f64, @floatFromInt(endTime - validateStartTime)) / std.time.ns_per_ms;
}

pub fn startRenderTiming() void {
    renderStartTime = std.time.nanoTimestamp();
}

pub fn endRenderTiming() void {
    const endTime = std.time.nanoTimestamp();
    renderTime = @as(f64, @floatFromInt(endTime - renderStartTime)) / std.time.ns_per_ms;
}

pub fn startFlushTiming() void {
    flushStartTime = std.time.nanoTimestamp();
}

pub fn endFlushTiming() void {
    const endTime = std.time.nanoTimestamp();
    flushTime = @as(f64, @floatFromInt(endTime - flushStartTime)) / std.time.ns_per_ms;
    lastFrameTime = @as(f64, @floatFromInt(endTime - lockStartTime)) / std.time.ns_per_ms;
}

pub fn trackRerenderCall() void {
    if (rerenderCalls >= std.math.maxInt(u64)) {
        rerenderCalls = 0;
        droppedRerenders = 0;
    } else {
        rerenderCalls = rerenderCalls + 1;
    }
}

pub fn trackDroppedRerender() void {
    droppedRerenders = if (droppedRerenders >= std.math.maxInt(u64)) droppedRerenders else droppedRerenders + 1;
}

pub fn update() void {
    // _ = std.fmt.bufPrint(&performanceBuffer, "Clay:{d:>3.3}ms Validate:{d:>3.3}ms Render:{d:>3.3}ms Flush:{d:>3.3}ms Full:{d:>3.3}ms Calls:{d} Dropped:{d}", .{
    //     @min(clayTime, 99.0),
    //     @min(validateTime, 99.0),
    //     @min(renderTime, 99.0),
    //     @min(flushTime, 99.0),
    //     @min(lastFrameTime, 99.0),
    //     rerenderCalls,
    //     droppedRerenders,
    // }) catch unreachable;
    log.err("Clay:{d:>3.3}ms Validate:{d:>3.3}ms Render:{d:>3.3}ms Flush:{d:>3.3}ms Full:{d:>3.3}ms Calls:{d} Dropped:{d}", .{
        @min(clayTime, 99.0),
        @min(validateTime, 99.0),
        @min(renderTime, 99.0),
        @min(flushTime, 99.0),
        @min(lastFrameTime, 99.0),
        rerenderCalls,
        droppedRerenders,
    });
}

pub fn updateFPS(win: *vaxis.Window) !void {
    const currentTime = std.time.nanoTimestamp();
    const currentTimeF = @as(f64, @floatFromInt(currentTime)) / std.time.ns_per_s;

    // Initialize on first call
    if (lastFrameStart == 0) {
        lastFrameStart = currentTimeF;
        return;
    }

    // Calculate frame time delta
    const deltaTime = currentTimeF - lastFrameStart;
    lastFrameStart = currentTimeF;

    // Convert to milliseconds and display
    const frameTimeMs = deltaTime * 1000.0;
    const frameStr = try std.fmt.bufPrint(&frametimeBuffer, "Frame: {d:>3.3}ms", .{@min(frameTimeMs, 99.0)});

    _ = win.printSegment(.{
        .text = frameStr,
        .style = .{
            .fg = .{ .rgb = .{ 255, 255, 255 } },
            .bg = .{ .rgb = .{ 0, 0, 0 } },
        },
    }, .{
        .row_offset = 0,
        .col_offset = 0,
        .commit = true,
    });
}

// pub fn updateFPS() void {
//     const currentTime = std.time.nanoTimestamp();
//     const currentTimeF = @as(f64, @floatFromInt(currentTime)) / std.time.ns_per_s;
//
//     // Initialize on first call
//     if (lastFrameTime == 0) {
//         lastFrameTime = currentTimeF;
//         return;
//     }
//
//     // Calculate frame time delta
//     const deltaTime = currentTimeF - lastFrameTime;
//     lastFrameTime = currentTimeF;
//
//     // Convert to milliseconds and display
//     const frameTimeMs = deltaTime * 1000.0;
//     _ = std.fmt.bufPrint(&performanceBuffer, "Frame: {d:>3.3}ms", .{@min(frameTimeMs, 99.0)}) catch unreachable;
// }

pub fn render() void {
    // const segment = vaxis.Segment{
    //     .text = "  ",
    //     .style = .{
    //         .fg = .{ .rgb = .{ 255, 255, 255 } },
    //         .bg = .{ .rgb = .{ 0, 0, 0 } },
    //     },
    // };
    // // _ = segment;
    // if (win) |window| {
    //     _ = window.printSegment(segment, .{ .commit = true });
    // }
}
