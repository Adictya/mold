const std = @import("std");
const napigen = @import("napigen");
const bridge = @import("bridge.zig");

const log = std.log.scoped(.node_main);

comptime {
    napigen.defineModule(initModule);
}

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

var g_tsfn: ?napigen.napi_threadsafe_function = null;

fn eventCallback(event: bridge.AppEvent) void {
    log.debug("Event callback called with event", .{});
    if (g_tsfn) |tsf| {
        _ = napigen.napi_call_threadsafe_function(
            tsf,
            @ptrCast(@constCast(&event)),
            napigen.napi_tsfn_blocking,
        );
    }
}

fn callJs(
    env: napigen.napi_env,
    val: napigen.napi_value,
    _: ?*anyopaque,
    data: ?*anyopaque,
) callconv(.c) void {
    const event_ptr: *bridge.AppEvent = @alignCast(@ptrCast(data));

    var undefValue: napigen.napi_value = undefined;
    _ = napigen.napi_get_undefined(env, &undefValue);

    const js = napigen.JsContext.init(env) catch @panic("Failed to create JsContext");

    switch (event_ptr.*) {
        .key => |key_evt| {
            _ = js.callFunction(undefValue, val, key_evt) catch unreachable;
        },
    }
}

fn init(js: *napigen.JsContext, callback: napigen.napi_value) !void {
    var resource_name: napigen.napi_value = undefined;
    _ = napigen.napi_create_string_utf8(js.env, "event_callback", 3, &resource_name);

    var tsfn: napigen.napi_threadsafe_function = undefined;
    const status = napigen.napi_create_threadsafe_function(
        js.env,
        callback,
        null,
        resource_name,
        0,
        1,
        null,
        null,
        null,
        callJs,
        &tsfn,
    );

    if (status != napigen.napi_ok) {
        log.err("Failed to create TSFN, status: {}", .{status});
        return;
    }

    g_tsfn = tsfn;

    log.info("TSFN created successfully", .{});

    try bridge.tuiInit(gpa.allocator(), eventCallback);
}

fn initModule(
    js: *napigen.JsContext,
    exports: napigen.napi_value,
) anyerror!napigen.napi_value {
    try js.setNamedProperty(
        exports,
        "init",
        try js.createFunction(init),
    );

    return exports;
}
