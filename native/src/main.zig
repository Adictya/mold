const std = @import("std");
const bridge = @import("bridge.zig");

const log = std.log.scoped(.main);

var log_file: std.fs.File = undefined;

pub const std_options: std.Options = .{
    .logFn = logFn,
};

pub fn logFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const scope_prefix = "(" ++ switch (scope) {
        .main => "main",
        .bridge => "bridge",
        else => @tagName(scope),
    } ++ "): ";

    const prefix = "[" ++ comptime level.asText() ++ "] " ++ scope_prefix;
    // log_file.writer().print(prefix ++ format ++ "\n", args) catch {};

    std.debug.print(prefix ++ format ++ "\n", args);
}

fn callback(event: bridge.AppEvent) void {
    switch (event) {
        .key => |key_event| {
            log.info("Key pressed: {s} {}", .{ key_event.text, key_event.mods.ctrl });
        },
    }
}

pub fn main() !void {
    log_file = try std.fs.cwd().createFile("logs.txt", .{});
    defer log_file.close();

    log.info("Hello, world!", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    try bridge.tuiInit(gpa.allocator(), callback);

    while (bridge.g_state.running.load(.monotonic)) {
        std.time.sleep(1000 * std.time.ns_per_ms);
    }

    bridge.tuiShutdown(gpa.allocator());
}
