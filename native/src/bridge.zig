const cl = @import("zclay");
const std = @import("std");
const vaxis = @import("vaxis");
const renderer = @import("lib/clay-renderer.zig");
const dom = @import("./lib/dom.zig");
const performance = @import("./lib/performance-panel.zig");
const breakLongWords = @import("./lib/break-text.zig").breakLongWords;
const Component = @import("lib/components.zig");

const log = std.log.scoped(.bridge);

pub const EventType = union(enum) {
    key_press: vaxis.Key,
    winsize: vaxis.Winsize,
    rerender: bool,
    mouse: vaxis.Mouse,
};

pub const KeyEvent = struct {
    text: []const u8 = "",
    key: u32,
    mods: vaxis.Key.Modifiers,
};

pub const MouseEvent = struct {
    id: u32,
    vaxis_mouse: vaxis.Mouse,
    clay_mouse: cl.PointerData,
    bounding_box: cl.BoundingBox,
};

pub const AppEvent = union(enum) {
    key: KeyEvent,
    mouse: MouseEvent,
};

pub var g_state: struct {
    // allocator: std.mem.Allocator,
    tty: ?*vaxis.Tty = null,
    vx: ?*vaxis.Vaxis = null,
    event_loop: ?*vaxis.Loop(EventType) = null,
    event_thread: ?std.Thread = null,
    event_callback: ?*const fn (AppEvent) void = null,
    running: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
    render_mutex: std.Thread.Mutex = .{},
    components: []const Component = &.{},
    clay_arena: cl.Arena = undefined,
    clay_memory: []u8 = undefined,
} = .{};

pub fn tuiInit(
    allocator: std.mem.Allocator,
    callback: *const fn (AppEvent) void,
) !void {
    if (g_state.tty) |tty| {
        _ = tty;
        std.log.debug("TTY already initialized", .{});
        return;
    }

    g_state.event_callback = callback;

    // Initialize TTY and Vaxis
    g_state.tty = try allocator.create(vaxis.Tty);
    g_state.tty.?.* = try vaxis.Tty.init();

    g_state.vx = allocator.create(vaxis.Vaxis) catch return;
    g_state.vx.?.* = vaxis.init(allocator, .{}) catch return;

    g_state.event_loop = allocator.create(vaxis.Loop(EventType)) catch return;
    g_state.event_loop.?.* = .{ .tty = g_state.tty.?, .vaxis = g_state.vx.? };
    g_state.event_loop.?.init() catch return;

    renderer.componentMap = renderer.IdHashMap.init(allocator);

    const min_memory_size: u32 = cl.minMemorySize();
    g_state.clay_memory = try allocator.alloc(u8, min_memory_size);
    g_state.clay_arena = cl.createArenaWithCapacityAndMemory(g_state.clay_memory);
    _ = cl.initialize(g_state.clay_arena, .{ .h = 100, .w = 100 }, .{});
    renderer.display_width = try vaxis.DisplayWidth.init(allocator);
    cl.setMeasureTextFunction(void, {}, renderer.consoleMeasureText);

    try g_state.vx.?.enterAltScreen(g_state.tty.?.anyWriter());

    try g_state.vx.?.setMouseMode(g_state.tty.?.anyWriter(), true);

    try g_state.vx.?.queryTerminal(
        g_state.tty.?.anyWriter(),
        1 * std.time.ns_per_s,
    );

	performance.init();

    g_state.event_loop.?.start() catch {};
    g_state.running.store(true, .monotonic);

    while (true) {
        const event = g_state.event_loop.?.nextEvent();

        switch (event) {
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
                cl.setLayoutDimensions(.{
                    .w = @floatFromInt(ws.cols),
                    .h = @floatFromInt(ws.rows),
                });
                break;
            },
            else => {},
        }
    }

    g_state.event_thread = std.Thread.spawn(
        .{},
        tuiEventLoop,
        .{allocator},
    ) catch return;
}

pub fn tuiShutdown(allocator: std.mem.Allocator) void {
    g_state.event_loop.?.stop();
    g_state.running.store(false, .monotonic);

    g_state.vx.?.exitAltScreen(g_state.tty.?.anyWriter()) catch {};

    g_state.vx.?.deinit(allocator, g_state.tty.?.anyWriter());
    g_state.tty.?.deinit();

    allocator.destroy(g_state.tty.?);
    allocator.destroy(g_state.vx.?);
    allocator.destroy(g_state.event_loop.?);

    // Now join the thread
    if (g_state.event_thread) |thread| {
        thread.join();
    }

    std.process.exit(0);
}

pub fn componentClickHandler(id: cl.ElementId, pd: cl.PointerData, user_data: *vaxis.Mouse) void {
    const vaxis_mouse_event: *const vaxis.Mouse = @ptrCast(@alignCast(user_data));
    const element_data = cl.getElementData(id);
    if (element_data.found) {
        const mouse_event = AppEvent{ .mouse = .{
            .id = id.id,
            .vaxis_mouse = vaxis_mouse_event.*,
            .clay_mouse = pd,
            .bounding_box = element_data.bounding_box,
        } };
        g_state.event_callback.?(mouse_event);
        // switch (pd.state) {
        //     .pressed_this_frame => {
        //     },
        //     .pressed => {
        //         // g_state.event_callback.?(mouse_event);
        //     },
        //     else => {},
        // }
    }
}

pub fn renderDFS(
    node: *dom.DomNode,
    vaxis_mouse: *vaxis.Mouse,
) !void {
    const comp = node.component;
    const compPtr = comp;
    const compId = comp.id;
    // log.debug("Sending component:\n{}\n</{s}>", .{ comp, comp.string_id });
    switch (comp.ctype) {
        .box => {
            const ui = cl.UI();
            var config = comp.view_props.toClay();
            config.id = compId;
            config.user_data = @constCast(compPtr);
            config.background_color = .{ 255, 255, 255, 255 };
            ui(config)({
                if (comp.view_props.clickable) {
                    cl.onHover(*vaxis.Mouse, vaxis_mouse, componentClickHandler);
                }
                if (node.first_child) |children| {
                    try renderDFS(children, vaxis_mouse);
                }
            });
        },
        .text => {
            var config = comp.text_props.toClay();
            config.user_data = @constCast(compPtr);
            cl.text(comp.text, config);
        },
    }
    if (node.next_sibling) |sibling| {
        try renderDFS(sibling, vaxis_mouse);
    }
}

fn tuiEventLoop(allocator: std.mem.Allocator) void {
    const loop = g_state.event_loop.?;
    const callback = g_state.event_callback.?;

    var vaxis_mouse: vaxis.Mouse = .{
        .col = 0,
        .row = 0,
        .mods = .{},
        .button = .left,
        .type = .release,
    };

    while (g_state.running.load(.monotonic)) {
        const event = loop.nextEvent();

        var rerender_ui = true;

        switch (event) {
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
                cl.setLayoutDimensions(.{
                    .w = @floatFromInt(ws.cols),
                    .h = @floatFromInt(ws.rows),
                });
            },
            .key_press => |key| {
                var key_event = AppEvent{
                    .key = .{
                        .key = @intCast(key.codepoint),
                        .mods = key.mods,
                    },
                };
                if (key.text) |key_text| {
                    key_event.key.text = key_text;
                }
                callback(key_event);
                continue;
            },
            .mouse => |mouse| {
                vaxis_mouse = mouse;
                var pressed: bool = switch (mouse.button) {
                    .left, .right, .middle => true,
                    else => false,
                };
                pressed = mouse.type == .press and pressed;
                cl.setPointerState(.{ .x = @floatFromInt(mouse.col), .y = @floatFromInt(mouse.row) }, pressed);
                const scroll_delta: cl.Vector2 = switch (mouse.button) {
                    .wheel_up => .{ .x = 0, .y = 1 },
                    .wheel_down => .{ .x = 0, .y = -1 },
                    .wheel_left => .{ .x = -1, .y = 0 },
                    .wheel_right => .{ .x = 1, .y = 0 },
                    else => .{ .x = 0, .y = 0 },
                };
                if (scroll_delta.x != 0 or scroll_delta.y != 0) {
                    cl.updateScrollContainers(false, scroll_delta, 1);
                } else {
                    continue;
                }
            },
            else => {
                rerender_ui = false;
            },
        }

        if (dom.root) |root| {
            if (root.first_child) |first_child| {
                var iter_depth: u8 = 0;
                const window = g_state.vx.?.window();
                g_state.render_mutex.lock();
                defer g_state.render_mutex.unlock();

                performance.updateFPS();
                var commands: []cl.RenderCommand = &.{};
                while (iter_depth < 2) {
                    cl.beginLayout();
                    performance.render();
                    renderDFS(first_child, &vaxis_mouse) catch {};
                    commands = cl.endLayout();
                    const wrapNeeded = renderer.clayTerminalRenderValidate(
                        allocator,
                        @constCast(&window),
                        commands,
                    ) catch |err| {
                        log.err("Render error: {}", .{err});
                        iter_depth += 1;
                        continue;
                    };
                    if (wrapNeeded) {
                        log.debug("Wrapping needed, iter:{}", .{iter_depth});
                        iter_depth += 1;
                        continue;
                    }
                    break;
                }
                log.debug("Rendering {}", .{iter_depth});
                window.clear();

                renderer.clayTerminalRender(
                    @constCast(&window),
                    commands,
                    @intCast(window.width),
                    @intCast(window.height),
                ) catch |err| {
                    log.err("Render error: {}", .{err});
                };

                g_state.vx.?.render(g_state.tty.?.anyWriter()) catch |err| {
                    log.err("Render error: {}", .{err});
                };
            }
        }
    }
}

pub fn render(components: []const Component) !void {
    g_state.render_mutex.lock();
    defer g_state.render_mutex.unlock();
    g_state.components = components;
    g_state.event_loop.?.postEvent(.{ .rerender = true });
}

pub fn rerender() !void {
    g_state.event_loop.?.postEvent(.{ .rerender = true });
}
