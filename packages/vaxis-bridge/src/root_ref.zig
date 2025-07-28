const std = @import("std");
const vaxis = @import("vaxis");
const napigen = @import("napigen");

// Define the component types we can render
const ComponentType = enum(u8) {
    box,
    text,
};

// Define the structure for a single component passed from Node.js
// `extern` ensures a C-compatible memory layout.
const Component = extern struct {
    ctype: ComponentType,
    x: i32,
    y: i32,
    width: u32,
    height: u32,
    fg_color: u8,
    bg_color: u8,
    border: bool,
    text: ?[*:0]const u8, // Null-terminated string for text content
};

// Define the structure for an event sent back to Node.js
const EventType = enum(u8) {
    key_press,
    winsize,
};

const KeyEvent = extern struct {
    key: [16]u8 = .{0} * 16, // A buffer for the key name
    ctrl: bool,
    alt: bool,
    shift: bool,
};

// A union for all possible event types
const AppEvent = extern struct {
    etype: EventType,
    data: extern union {
        key: KeyEvent,
        winsize: vaxis.Winsize,
    },
};
// Global state for our TUI application
var g_state: struct {
    allocator: std.mem.Allocator,
    tty: ?*vaxis.Tty = null,
    vx: ?*vaxis.Vaxis = null,
    event_loop: ?*vaxis.Loop(vaxis.Event) = null,
    event_thread: ?std.Thread = null,
    // The thread-safe function to call back into Node.js
    tsfn: ?napigen.napi_threadsafe_function(AppEvent) = null,
    // Atomic flag to signal the event loop to stop
    running: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
    // Mutex to protect access to Vaxis from multiple threads
    render_mutex: std.Thread.Mutex = .{},
} = .{ .allocator = undefined };

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

// The function that will run in a separate thread to handle Vaxis events
fn tuiEventLoop() void {
    const loop = g_state.event_loop.?;
    const tsfn = g_state.tsfn.?;

    while (g_state.running.load(.monotonic)) {
        // nextEvent blocks, which is fine since it's in its own thread
        const event = loop.nextEventTimeout(100 * std.time.ns_per_ms) orelse continue;

        switch (event) {
            .key_press => |key| {
                // Create a key event to send to Node.js
                var key_event = KeyEvent{
                    .ctrl = key.modifiers.ctrl,
                    .alt = key.modifiers.alt,
                    .shift = key.modifiers.shift,
                };
                // Simple way to copy key string
                const key_str = key.toString(g_state.allocator) catch "err";
                defer g_state.allocator.free(key_str);
                @memcpy(key_event.key[0..key_str.len], key_str);

                const app_event = AppEvent{
                    .etype = .key_press,
                    .data = .{ .key = key_event },
                };
                // Call the JavaScript callback from our thread
                _ = tsfn.call(.blocking, &app_event);
            },
            .winsize => |ws| {
                // Handle resize directly in Zig
                g_state.render_mutex.lock();
                defer g_state.render_mutex.unlock();
                g_state.vx.?.resize(g_state.allocator, g_state.tty.?.anyWriter(), ws) catch {};
            },
            else => {},
        }
    }
}

// Exported function: init(onEventCallback)
fn tuiInit(env: napigen.Env, info: napigen.CallbackInfo) napigen.Value {
    g_state.allocator = gpa.allocator();

    const argv = info.getArgs(1) catch return null;
    const js_callback = argv[0];

    // Initialize TTY and Vaxis
    g_state.tty = g_state.allocator.create(vaxis.Tty) catch return null;
    g_state.tty.* = vaxis.Tty.init() catch return null;

    g_state.vx = g_state.allocator.create(vaxis.Vaxis) catch return null;
    g_state.vx.* = vaxis.init(g_state.allocator, .{}) catch return null;

    g_state.event_loop = g_state.allocator.create(vaxis.Loop(vaxis.Event)) catch return null;
    g_state.event_loop.* = .{ .tty = g_state.tty.?, .vaxis = g_state.vx.? };
    g_state.event_loop.?.init() catch return null;

    // Create the thread-safe function for event callbacks
    g_state.tsfn = napigen.ThreadsafeFunction(AppEvent).new(env, js_callback, "tui_event_callback", 0, 1) catch return null;

    // Start everything up
    g_state.vx.?.enterAltScreen(g_state.tty.?.anyWriter()) catch {};
    g_state.event_loop.?.start() catch {};
    g_state.running.store(true, .monotonic);

    // Spawn the event loop thread
    g_state.event_thread = std.Thread.spawn(.{}, tuiEventLoop, .{}) catch return null;

    return null;
}

// Exported function: render(componentsArray)
fn tuiRender(env: napigen.Env, info: napigen.napi_callback_info) napigen.napi_value {
    const argv = info.getArgs(1) catch return null;
    const js_array = napigen.value.as(napigen.napi_int8_array, argv[0]) catch return null;
    const len = js_array.getLength() catch return null;

    // Get the component data from JavaScript
    const components = env.allocator().alloc(Component, len) catch return null;
    defer env.allocator().free(components);

    for (0..len) |i| {
        const obj = js_array.getElement(napigen.napi_value, i) catch continue;
        // This part is complex: you need to read properties from the JS object
        // and populate your `Component` struct. node-api-zig has helpers for this.
        // For simplicity, this is a sketch.
        const ctype_val = obj.getNamedProperty(u8, "ctype") catch 0;
        components[i].ctype = @enumFromInt(ctype_val);
        // ... get x, y, width, height, text, etc.
        components[i].x = obj.getNamedProperty(i32, "x") catch 0;
        components[i].y = obj.getNamedProperty(i32, "y") catch 0;
        components[i].width = obj.getNamedProperty(u32, "width") catch 0;
        components[i].height = obj.getNamedProperty(u32, "height") catch 0;
        components[i].fg_color = obj.getNamedProperty(u8, "fgColor") catch 0;
    }

    // Lock the mutex to prevent race conditions with resize events
    g_state.render_mutex.lock();
    defer g_state.render_mutex.unlock();

    const vx = g_state.vx.?;
    const win = vx.window();
    win.clear();

    // Iterate and draw components
    for (components) |comp| {
        const child = win.child(.{
            .x_off = @intCast(comp.x),
            .y_off = @intCast(comp.y),
            .width = @intCast(comp.width),
            .height = @intCast(comp.height),
        });
        const style: vaxis.Style = .{ .fg = .{ .index = comp.fg_color } };
        child.fill(vaxis.Cell.default, style);
        // ... add logic for different component types
    }

    vx.render(g_state.tty.?.anyWriter()) catch {};

    return null;
}

// Exported function: shutdown()
fn tuiShutdown(_: napigen.napi_env, _: napigen.napi_callback_info) napigen.napi_value {
    if (!g_state.running.load(.monotonic)) return null;

    // Signal thread to stop and wait for it
    g_state.running.store(false, .monotonic);
    g_state.event_thread.?.join();

    // Deinitialize everything
    g_state.event_loop.?.stop() catch {};
    g_state.vx.?.leaveAltScreen(g_state.tty.?.anyWriter()) catch {};
    g_state.vx.?.deinit(g_state.allocator, g_state.tty.?.anyWriter());
    g_state.tty.?.deinit();

    // Free memory
    g_state.allocator.destroy(g_state.tty.?);
    g_state.allocator.destroy(g_state.vx.?);
    g_state.allocator.destroy(g_state.event_loop.?);

    // Release the thread-safe function
    g_state.tsfn.?.release();

    if (gpa.deinit() == .leak) {
        std.log.err("memory leak detected", .{});
    }

    return null;
}

// The module definition that Node.js will load
pub export fn napi_init(env: napigen.napi_env, exports: napigen.napi_value) napigen.napi_value {
    napigen.napi_set_named_property(env, tuiInit, "init", exports);
    napigen.napi_set_named_property(env, tuiRender, "render", exports);
    napigen.napi_set_named_property(env, tuiShutdown, "shutdown", exports);
    return exports;
}
