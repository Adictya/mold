const std = @import("std");
const bridge = @import("bridge.zig");
const Component = @import("lib/components.zig");

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
    log_file.writer().print(prefix ++ format ++ "\n", args) catch {};

    // std.debug.print(prefix ++ format ++ "\n", args);
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

    const parent = try Component.Create(
        gpa.allocator(),
        "parent",
        .box,
        0,
        0,
        20,
        25,
        .{ .left = 1, .right = 1, .top = 1, .bottom = 1 },
        .{ .rgb = .{ 0, 255, 0 } },
        .{ .rgb = .{ 255, 0, 0 } },
        .{ .glyphs = .single_rounded, .where = .all },
        null,
    );

    const child1 = try Component.Create(
        gpa.allocator(),
        "child1",
        .text,
        0,
        0,
        16,
        1,
        .{},
        .default,
        .default,
        .{ .where = .none },
        "Hello from Zig! 😎",
    );

    parent.child(&[_]Component{child1.*});

    const test_components = [_]Component{parent.*};

    // const test_components = [_]Component{
    //     .{
    //         .ctype = .box,
    //         .x = 5,
    //         .y = 5,
    //         .width = 20,
    //         .height = 5,
    //         .fg_color = 2,
    //         .bg_color = 0,
    //         .border = true,
    //         .text = null,
    //         .children = null,
    //     },
    //     .{
    //         .ctype = .text,
    //         .x = 7,
    //         .y = 7,
    //         .width = 16,
    //         .height = 1,
    //         .fg_color = 3,
    //         .bg_color = 0,
    //         .border = false,
    //         .text = "Hello from Zig!",
    //         .children = null,
    //     },
    // };

    try bridge.render(&test_components);

    while (bridge.g_state.running.load(.monotonic)) {
        std.time.sleep(1000 * std.time.ns_per_ms);
    }

    bridge.tuiShutdown(gpa.allocator());
}
