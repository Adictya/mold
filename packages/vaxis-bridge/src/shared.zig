const std = @import("std");
const vaxis = @import("vaxis");
const TextInput = vaxis.widgets.TextInput;

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
        try writer.print(
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
    allocator: std.mem.Allocator,
    tty: ?*vaxis.Tty = null,
    vx: ?*vaxis.Vaxis = null,
    event_loop: ?*vaxis.Loop(vaxis.Event) = null,
    event_thread: ?std.Thread = null,
    event_callback: ?*const fn (AppEvent) void = null,
    running: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
    render_mutex: std.Thread.Mutex = .{},
    components: []const Component = &.{},
} = .{ .allocator = undefined };

pub const EventType = enum(u8) {
    key_press,
    winsize,
    rerender,
};

pub const KeyEvent = extern struct {
    key: [16]u8,
    ctrl: bool,
    alt: bool,
    shift: bool,
};

const WinsizeEvent = extern struct {
    rows: u16,
    cols: u16,
    x_pixel: u16,
    y_pixel: u16,
};

pub const AppEvent = extern struct {
    etype: EventType,
    data: extern union {
        key: KeyEvent,
        winsize: WinsizeEvent,
        foo: u8,
    },
};
pub var gpa = std.heap.GeneralPurposeAllocator(.{}){};

const Event = union(enum) {
    key_press: vaxis.Key,
    winsize: vaxis.Winsize,
    focus_in,
    foo: u8,
};

fn tuiEventLoop() void {
    const loop = g_state.event_loop.?;
    const callback = g_state.event_callback.?;

    while (g_state.running.load(.monotonic)) {
        const event = loop.nextEvent();

        switch (event) {
            .key_press => |key| {
                if (key.matches('c', .{ .ctrl = true })) {
                    g_state.running.store(false, .monotonic);
                    break; // Create a key event to send to Node.js
                }
                const key_event = KeyEvent{
                    .key = std.mem.zeroes([16]u8),
                    .ctrl = key.mods.ctrl,
                    .alt = key.mods.alt,
                    .shift = key.mods.shift,
                };
                // Simple way to copy key string
                // const key_str = if (key.codepoint > 0)
                //     std.fmt.allocPrint(g_state.allocator, "{u}", .{@as(u21, @intCast(key.codepoint))}) catch "err"
                // else
                //     "unknown";
                // defer g_state.allocator.free(key_str);
                // @memcpy(key_event.key[0..key_str.len], key_str);

                const app_event = AppEvent{
                    .etype = .key_press,
                    .data = .{ .key = key_event },
                };
                // Call the generic callback
                callback(app_event);
            },
            .winsize => |ws| {
                // Handle resize directly in Zig
                g_state.render_mutex.lock();
                defer g_state.render_mutex.unlock();
                g_state.vx.?.resize(g_state.allocator, g_state.tty.?.anyWriter(), ws) catch |err| {
                    std.debug.print("Resize error: {}\n", .{err});
                };

                // Also notify callback about resize
                // const winsize_event = WinsizeEvent{
                //     .rows = ws.rows,
                //     .cols = ws.cols,
                //     .x_pixel = ws.x_pixel,
                //     .y_pixel = ws.y_pixel,
                // };
                // const app_event = AppEvent{
                //     .etype = .winsize,
                //     .data = .{ .winsize = winsize_event },
                // };
                // callback(app_event);
            },
            else => {},
        }

        const win = g_state.vx.?.window();

        g_state.render_mutex.lock();
        defer g_state.render_mutex.unlock();

        win.clear();

        for (g_state.components) |comp| {
            // std.debug.print("Rendering {} component\n", .{comp});
            switch (comp.ctype) {
                .box => {
                    const child_opts = if (comp.border) vaxis.Window.ChildOptions{
                        .x_off = @intCast(comp.x),
                        .y_off = @intCast(comp.y),
                        .width = @intCast(comp.width),
                        .height = @intCast(comp.height),
                        .border = .{
                            .where = .all,
                            .style = .{
                                .fg = .{ .index = comp.fg_color },
                                .bg = .{ .index = comp.bg_color },
                            },
                        },
                    } else vaxis.Window.ChildOptions{
                        .x_off = @intCast(comp.x),
                        .y_off = @intCast(comp.y),
                        .width = @intCast(comp.width),
                        .height = @intCast(comp.height),
                    };
                    _ = win.child(child_opts);
                },
                .text => {
                    const child = win.child(.{
                        .x_off = @intCast(comp.x),
                        .y_off = @intCast(comp.y),
                        .width = @intCast(comp.width),
                        .height = @intCast(comp.height),
                    });

                    if (comp.text) |text| {
                        const text_slice = std.mem.span(text);
                        const style: vaxis.Style = .{
                            .fg = .{ .index = comp.fg_color },
                            .bg = .{ .index = comp.bg_color },
                        };
                        _ = child.printSegment(.{ .text = text_slice, .style = style }, .{});
                    }
                },
            }
        }
        g_state.vx.?.render(g_state.tty.?.anyWriter()) catch |err| {
            std.debug.print("Render error: {}\n", .{err});
        };
    }
}

pub fn tuiInit(callback: *const fn (AppEvent) void) !void {
    g_state.allocator = gpa.allocator();
    g_state.event_callback = callback;

    // Initialize TTY and Vaxis
    g_state.tty = g_state.allocator.create(vaxis.Tty) catch return;
    g_state.tty.?.* = vaxis.Tty.init() catch return;

    g_state.vx = g_state.allocator.create(vaxis.Vaxis) catch return;
    g_state.vx.?.* = vaxis.init(g_state.allocator, .{}) catch return;

    g_state.event_loop = g_state.allocator.create(vaxis.Loop(vaxis.Event)) catch return;
    g_state.event_loop.?.* = .{ .tty = g_state.tty.?, .vaxis = g_state.vx.? };
    g_state.event_loop.?.init() catch return;

    // try g_state.vx.?.enterAltScreen(g_state.tty.?.anyWriter());

    try g_state.vx.?.queryTerminal(
        g_state.tty.?.anyWriter(),
        1 * std.time.ns_per_s,
    );

    g_state.event_loop.?.start() catch {};
    g_state.running.store(true, .monotonic);

    g_state.event_thread = std.Thread.spawn(.{}, tuiEventLoop, .{}) catch return;
}

pub fn tuiShutdown() void {
    // g_state.shutdown_requested.store(true, .monotonic);
    g_state.event_loop.?.stop();
    g_state.vx.?.exitAltScreen(g_state.tty.?.anyWriter()) catch {};
    g_state.vx.?.deinit(g_state.allocator, g_state.tty.?.anyWriter());
    g_state.tty.?.deinit();

    g_state.allocator.destroy(g_state.tty.?);
    g_state.allocator.destroy(g_state.vx.?);
    g_state.allocator.destroy(g_state.event_loop.?);
    _ = gpa.deinit();
    g_state.running.store(false, .monotonic);

    // // Post a dummy event to wake up the event loop
    // const evt = vaxis.Event{ .key_press = vaxis.Key{ .codepoint = 0 } };
    // g_state.event_loop.?.postEvent(evt);

    // Now join the thread
    if (g_state.event_thread) |thread| {
        thread.join();
    }
}

pub fn render(components: []const Component) !void {
    g_state.render_mutex.lock();
    defer g_state.render_mutex.unlock();
    g_state.components = components;
    const evt = vaxis.Event{ .key_press = vaxis.Key{ .codepoint = 0 } };
    g_state.event_loop.?.postEvent(evt);
}
