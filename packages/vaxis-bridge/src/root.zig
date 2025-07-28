const std = @import("std");
const vaxis = @import("vaxis");
const shared = @import("shared.zig");
const napigen = @import("napigen");
const jsObj = @import("jsObjs.zig");

// Global TSFN for event callbacks
var g_tsfn: ?napigen.napi_threadsafe_function = null;
var v_tsfn: ?napigen.napi_value = null;
var jsCtx: ?napigen.JsContext = null;

// Callback function that will be passed to shared.zig
fn eventCallback(event: shared.AppEvent) void {
    std.debug.print("Event callback called with event: {}\n", .{event.etype});
    if (g_tsfn) |tsf| {
        _ = napigen.napi_call_threadsafe_function(
            tsf,
            @ptrCast(@constCast(&event)),
            napigen.napi_tsfn_blocking,
        );
    }
}

const testStruct = extern struct {
    x: tetStructNested,
};

const tetStructNested = extern struct {
    y: i32,
};

fn callJs(
    env: napigen.napi_env,
    val: napigen.napi_value,
    _: ?*anyopaque,
    data: ?*anyopaque,
) callconv(.c) void {
    const event_ptr: *shared.AppEvent = @alignCast(@ptrCast(data));

    // const evt_copy = event_ptr.*;

    var undefValue: napigen.napi_value = null;
    _ = napigen.napi_get_undefined(env, &undefValue);

    const js = napigen.JsContext.init(env) catch @panic("Failed to create JsContext");
    _ = js.callFunction(undefValue, val, event_ptr.*.data.key) catch unreachable;
    // switch (evt_copy.etype) {
    //     .key_press => {
    //         _ = js.callFunction(undefValue, val, event_ptr.*.data.key) catch unreachable;
    //     },
    //     .winsize => {
    //         _ = js.callFunction(undefValue, val, event_ptr.*.data.winsize) catch unreachable;
    //     },
    //     else => {
    //         std.debug.print("Unhandled event type: {}\n", .{event_ptr.*.etype});
    //     },
    // }

    // _ = napigen.napi_call_function(
    //     env,
    //     undefValue,
    //     val,
    //     1,
    //     &obj,
    //     null,
    // );
}

// Node.js wrapper for tuiInit that sets up TSFN
fn tuiInitWithCallback(js: *napigen.JsContext, callback: napigen.napi_value) !void {
    // Create TSFN for the callback
    var val: napigen.napi_value = undefined;
    _ = napigen.napi_create_string_utf8(js.env, "why", 3, &val);
    std.debug.print("Creating TSFN with callback: {}\n", .{1});

    var tsfn: napigen.napi_threadsafe_function = undefined;
    const status = napigen.napi_create_threadsafe_function(
        js.env,
        callback,
        null,
        val,
        0,
        1,
        null,
        null,
        null,
        callJs,
        &tsfn,
    );

    if (status != napigen.napi_ok) {
        std.debug.print("Failed to create TSFN, status: {}\n", .{status});
        return;
    }

    g_tsfn = tsfn;
    std.debug.print("TSFN created successfully\n", .{});
    // Initialize the TUI with our callback
    try shared.tuiInit(eventCallback);
}

// Node.js wrapper for tuiShutdown that cleans up TSFN
fn tuiShutdownWithCleanup(js: *napigen.JsContext) !napigen.napi_value {
    // Shutdown the TUI
    shared.tuiShutdown();

    // Release the TSFN
    // if (g_tsfn) |tsfn| {
    //     var val: napigen.napi_value = null;
    //     _ = napigen.threadsafe
    //     napigen.napi_release_threadsafe_function(tsfn, );
    //     g_tsfn = null;
    // }

    return js.undefined();
}
fn tuiRender(js: *napigen.JsContext, val: napigen.napi_value) void {
    var len: u32 = 0;
    const env = js.env;
    _ = napigen.napi_get_array_length(env, val, &len);

    const components = shared.gpa.allocator().alloc(shared.Component, len) catch return;

    for (0..len) |i| {
        std.debug.print("Processing component {}\n", .{i});
        const obj = js.getElement(val, @intCast(i)) catch continue;

        jsObj.jsObjectToStruct(
            shared.Component,
            js,
            obj,
            &components[i],
            shared.gpa.allocator(),
        ) catch |err| {
            std.debug.print("Error converting JS object to struct: {}\n", .{err});
            continue;
        };

        // const named_prop = (js.getNamedProperty(obj, "ctype")) catch js.null() catch undefined;
        // var ctype_val: u32 = 0;
        // _ = napigen.napi_get_value_uint32(env, named_prop, &ctype_val);
        // components[i].ctype = @enumFromInt(ctype_val);
        //
        // const x = js.getNamedProperty(obj, "x") catch js.null() catch undefined;
        // _ = napigen.napi_get_value_int32(env, x, &components[i].x);
        //
        // const y = js.getNamedProperty(obj, "y") catch js.null() catch undefined;
        // _ = napigen.napi_get_value_int32(env, y, &components[i].y);
        //
        // const width = js.getNamedProperty(obj, "width") catch js.null() catch undefined;
        // _ = napigen.napi_get_value_uint32(env, width, &components[i].width);
        //
        // const height = js.getNamedProperty(obj, "height") catch js.null() catch undefined;
        // _ = napigen.napi_get_value_uint32(env, height, &components[i].height);
        //
        // const border = js.getNamedProperty(obj, "border") catch js.null() catch undefined;
        // _ = napigen.napi_get_value_bool(env, border, &components[i].border);
        //
        // const text = js.getNamedProperty(obj, "text") catch js.null() catch undefined;
        // var text_buffer: [256]u8 = undefined;
        // var text_length: usize = 0;
        // const status = napigen.napi_get_value_string_utf8(env, text, &text_buffer, text_buffer.len, &text_length);
        // if (status == napigen.napi_ok and text_length > 0) {
        //     const text_copy = shared.gpa.allocator().allocSentinel(u8, text_length, 0) catch {
        //         components[i].text = null;
        //         continue;
        //     };
        //     @memcpy(text_copy, text_buffer[0..text_length]);
        //     components[i].text = text_copy.ptr;
        // } else {
        //     components[i].text = null;
        // }
        //
        // const fgColor = js.getNamedProperty(obj, "fgColor") catch js.null() catch undefined;
        // var fgVal: i32 = 0;
        // _ = napigen.napi_get_value_int32(env, fgColor, &fgVal);
        // components[i].fg_color = @intCast(fgVal);
        //
        // const bgColor = js.getNamedProperty(obj, "bgColor") catch js.null() catch undefined;
        // var bgVal: i32 = 0;
        // _ = napigen.napi_get_value_int32(env, bgColor, &bgVal);
        // components[i].bg_color = @intCast(bgVal);

        // std.debug.print("Component {}: x = {}, y = {}, width = {}, height = {}, fg_color = {}\n", .{
        //     i,
        //     // components[i].ctype,
        //     components[i].x,
        //     components[i].y,
        //     components[i].width,
        //     components[i].height,
        //     components[i].fg_color,
        // });
    }

    if (shared.g_state.vx != null and shared.g_state.tty != null) {
        // shared.render(shared.g_state.vx.?, shared.g_state.tty.?, components) catch {};
        shared.render(components) catch {};
    }
}

comptime {
    napigen.defineModule(initModule);
}

fn initModule(
    js: *napigen.JsContext,
    exports: napigen.napi_value,
) anyerror!napigen.napi_value {
    try js.setNamedProperty(
        exports,
        "init",
        try js.createFunction(tuiInitWithCallback),
    );
    try js.setNamedProperty(
        exports,
        "render",
        try js.createFunction(tuiRender),
    );
    try js.setNamedProperty(
        exports,
        "shutdown",
        try js.createFunction(tuiShutdownWithCleanup),
    );

    return exports;
}
