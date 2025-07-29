const std = @import("std");
const vaxis = @import("vaxis");

const log = std.log.scoped(.bridge);

pub const EventType = enum(u8) {
    key_press,
    winsize,
    rerender,
};

pub const KeyEvent = struct {
    text: []const u8,
    mods: vaxis.Key.Modifiers,
};

pub const AppEvent = union(enum) {
    key: KeyEvent,
};

const ComponentType = enum(u8) {
    box,
    text,
};

pub const Component = extern struct {
    ctype: ComponentType,
    x: i32,
    y: i32,
    width: u32,
    height: u32,
    fg_color: u8,
    bg_color: u8,
    border: bool,
    text: ?[*:0]const u8, // Null-terminated string for text content

    pub fn fmt(
        self: *const Component,
        writer: anytype,
    ) []const u8 {
        try std.fmt.format(
            writer,
            "Component(ctype: {}, x: {}, y: {}, width: {}, height: {}, fg_color: {}, bg_color: {}, border: {}, text: {})",
            .{
                self.ctype,
                self.x,
                self.y,
                self.width,
                self.height,
                self.fg_color,
                self.bg_color,
                self.border,
                if (self.text) |t| t else "null",
            },
        );
    }
};

pub var g_state: struct {
    // allocator: std.mem.Allocator,
    tty: ?*vaxis.Tty = null,
    vx: ?*vaxis.Vaxis = null,
    event_loop: ?*vaxis.Loop(vaxis.Event) = null,
    event_thread: ?std.Thread = null,
    event_callback: ?*const fn (AppEvent) void = null,
    running: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
    render_mutex: std.Thread.Mutex = .{},
    components: []const Component = &.{},
} = .{};

pub fn tuiInit(
    allocator: std.mem.Allocator,
    callback: *const fn (AppEvent) void,
) !void {
    g_state.event_callback = callback;

    // Initialize TTY and Vaxis
    g_state.tty = try allocator.create(vaxis.Tty);
    g_state.tty.?.* = try vaxis.Tty.init();

    g_state.vx = allocator.create(vaxis.Vaxis) catch return;
    g_state.vx.?.* = vaxis.init(allocator, .{}) catch return;

    g_state.event_loop = allocator.create(vaxis.Loop(vaxis.Event)) catch return;
    g_state.event_loop.?.* = .{ .tty = g_state.tty.?, .vaxis = g_state.vx.? };
    g_state.event_loop.?.init() catch return;

    // try g_state.vx.?.enterAltScreen(g_state.tty.?.anyWriter());

    try g_state.vx.?.queryTerminal(
        g_state.tty.?.anyWriter(),
        1 * std.time.ns_per_s,
    );

    g_state.event_loop.?.start() catch {};
    g_state.running.store(true, .monotonic);

    g_state.event_thread = std.Thread.spawn(
        .{},
        tuiEventLoop,
        .{allocator},
    ) catch return;
}

pub fn tuiShutdown(allocator: std.mem.Allocator) void {
    g_state.event_loop.?.stop();
    g_state.running.store(false, .monotonic);

    // g_state.vx.?.exitAltScreen(g_state.tty.?.anyWriter()) catch {};

    g_state.vx.?.deinit(allocator, g_state.tty.?.anyWriter());
    g_state.tty.?.deinit();

    allocator.destroy(g_state.tty.?);
    allocator.destroy(g_state.vx.?);
    allocator.destroy(g_state.event_loop.?);

    // Now join the thread
    if (g_state.event_thread) |thread| {
        thread.join();
    }
}

fn tuiEventLoop(allocator: std.mem.Allocator) void {
    const loop = g_state.event_loop.?;
    const callback = g_state.event_callback.?;

    while (g_state.running.load(.monotonic)) {
        const event = loop.nextEvent();

        switch (event) {
            .key_press => |key| {
                if (key.text) |key_text| {
                    const key_event = AppEvent{ .key = .{
                        .text = allocator.dupe(u8, key_text) catch @panic("Out of memory"),
                        .mods = key.mods,
                    } };
                    defer allocator.free(key_event.key.text);
                    callback(key_event);
                }

                if (key.matches('c', .{ .ctrl = true })) {
                    g_state.running.store(false, .monotonic);
                    break;
                }
            },
            .winsize => |ws| {
                g_state.render_mutex.lock();
                defer g_state.render_mutex.unlock();
                g_state.vx.?.resize(
                    allocator,
                    g_state.tty.?.anyWriter(),
                    ws,
                ) catch |err| {
                    log.err("Resize error: {}", .{err});
                };
            },
            else => {},
        }

        const win = g_state.vx.?.window();

        g_state.render_mutex.lock();
        defer g_state.render_mutex.unlock();

        win.clear();

        for (g_state.components) |comp| {
            // TODO(adictya): use dfs instead of loop
            log.debug("Rendering {} component", .{comp});
        }

        g_state.vx.?.render(g_state.tty.?.anyWriter()) catch |err| {
            log.err("Render error: {}", .{err});
        };
    }
}
