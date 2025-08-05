const std = @import("std");
const napigen = @import("napigen");
const bridge = @import("bridge.zig");
const cl = @import("zclay");
const renderer = @import("./lib/clay-renderer.zig");
const jsoParser = @import("./lib/js_value_parser.zig");
const Component = @import("./lib/components.zig");
const dom = @import("./lib/dom.zig");

const log = std.log.scoped(.node_main);

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
    if (scope == .js_parser) return;
    const scope_prefix = "\n(" ++ switch (scope) {
        .main => "main",
        .bridge => "bridge",
        .js_value_parser => "js_parser",
        else => @tagName(scope),
    } ++ "): ";

    const prefix = "[" ++ comptime level.asText() ++ "] " ++ scope_prefix;
    log_file.writer().print(prefix ++ format ++ "\n", args) catch {};

    // std.debug.print(prefix ++ format ++ "\n", args);
}

comptime {
    napigen.defineModule(initModule);
}

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

var g_tsfn: ?napigen.napi_threadsafe_function = null;

fn eventCallback(event: bridge.AppEvent) void {
    const event_to_send = gpa.allocator().create(bridge.AppEvent) catch unreachable;
    event_to_send.* = event;
    std.log.debug("Calling mouse event {}", .{event_to_send});
    if (g_tsfn) |tsf| {
        _ = napigen.napi_call_threadsafe_function(
            tsf,
            @ptrCast(@constCast(event_to_send)),
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
            _ = js.callFunction(undefValue, val, .{ 0, key_evt }) catch |err| log.err("Failed to call function: {}", .{err});
        },
        .mouse => |mouse_evt| {
            _ = js.callFunction(undefValue, val, .{ 1, mouse_evt }) catch |err| log.err("Failed to call function: {}", .{err});
        },
    }
    gpa.allocator().destroy(event_ptr);
}

fn init(js: *napigen.JsContext, callback: napigen.napi_value) !void {
    log_file = try std.fs.cwd().createFile("debug.log", .{});
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

    try dom.init(gpa.allocator());

    try bridge.tuiInit(gpa.allocator(), eventCallback);
}

var div_count: u32 = 0;
var span_count: u32 = 0;

fn getNextElementId(allocator: std.mem.Allocator, element_type: []const u8) ![]u8 {
    if (std.mem.eql(u8, element_type, "div")) {
        div_count += 1;
        return try std.fmt.allocPrint(allocator, "div_{d}", .{div_count});
    } else if (std.mem.eql(u8, element_type, "span")) {
        span_count += 1;
        return try std.fmt.allocPrint(allocator, "span_{d}", .{span_count});
    }

    // Fallback for other types (shouldn't happen based on your requirements)
    return try std.fmt.allocPrint(allocator, "{s}_1", .{element_type});
}

const createElementParams = struct {
    element_id: []const u8,
    text: bool = false,
};

fn createElement(
    js: *napigen.JsContext,
    args: napigen.napi_value,
) anyerror!u32 {
    var params: createElementParams = undefined;
    _ = try jsoParser.jsObjectToStruct(
        createElementParams,
        js,
        args,
        &params,
        gpa.allocator(),
    );

    const component = try gpa.allocator().create(Component);

    const text_copy = try getNextElementId(gpa.allocator(), params.element_id);

    log.debug("[zig]: Creating element with tag: {s} => {s}\n", .{ params.element_id, text_copy });

    component.* = Component{
        .id = .ID(text_copy),
        .string_id = text_copy,
        .ctype = if (params.text) .text else .box,
        .text = if (params.text) params.element_id else "",
    };

    const node = try gpa.allocator().create(dom.DomNode);
    node.* = dom.DomNode{
        .component = component,
    };

    try dom.nodeMap.put(component.id.id, node);

    if (dom.root == null and std.mem.eql(u8, params.element_id, "root")) {
        dom.root = node;
    }

    return component.id.id;
}

const replaceTextParams = struct {
    element_id: u32,
    text: []const u8,
};

fn replaceText(js: *napigen.JsContext, val: napigen.napi_value) anyerror!void {
    var params: replaceTextParams = undefined;
    _ = try jsoParser.jsObjectToStruct(
        replaceTextParams,
        js,
        val,
        &params,
        gpa.allocator(),
    );

    const node = dom.nodeMap.get(params.element_id) orelse return;

    log.debug("[zig]: Replacing text with tag: {s} => {}\n", .{ node.component.string_id, params });

    node.component.id = .ID(params.text);
    node.component.text = params.text;

    _ = dom.nodeMap.remove(params.element_id);
    try dom.nodeMap.put(params.element_id, node);

    try bridge.rerender();
}

const setPropertyParams = struct {
    element_id: u32,
    property: u8,
};

const propertiesEnum = enum(u8) {
    position = 0,
    sizing = 1,
    padding = 2,
    childLayout = 3,
    scroll = 4,
    style = 5,
    border = 6,
    textStyle = 9,
    text = 10,
    debug_id = 11,
    clickable = 12,
};

fn setProperty(
    js: *napigen.JsContext,
    prop: napigen.napi_value,
    simpleVal: []const u8,
    complexVal: napigen.napi_value,
) anyerror!void {
    bridge.g_state.render_mutex.lock();
    defer bridge.g_state.render_mutex.unlock();
    var params: setPropertyParams = undefined;
    _ = try jsoParser.jsObjectToStruct(
        setPropertyParams,
        js,
        prop,
        &params,
        gpa.allocator(),
    );

    const id = params.element_id;

    const property: propertiesEnum = @enumFromInt(params.property);

    const node = dom.nodeMap.get(id) orelse return;

    log.debug("[zig]: Setting property <{s}/> {s} \n", .{ node.component.string_id, @tagName(property) });

    switch (property) {
        .debug_id => {
            log.debug("comopnentId: {s} debug id: {s}", .{ node.component.string_id, simpleVal });
            // Store debug_id in string_id since there's no debug_id field
            const copied_id = gpa.allocator().dupe(u8, simpleVal) catch unreachable;
            // We'll use string_id instead since debug_id doesn't exist
            node.component.string_id = copied_id;
            return;
        },
        .position => {
            var value: Component.Position = .{};
            _ = try jsoParser.jsObjectToStruct(
                Component.Position,
                js,
                complexVal,
                &value,
                gpa.allocator(),
            );
            node.component.view_props.position = value;
        },
        .sizing => {
            var value: Component.Sizing = .{};
            _ = try jsoParser.jsObjectToStruct(
                Component.Sizing,
                js,
                complexVal,
                &value,
                gpa.allocator(),
            );
            node.component.view_props.sizing = value;
        },
        .padding => {
            var value: cl.Padding = .{};
            _ = try jsoParser.jsObjectToStruct(
                cl.Padding,
                js,
                complexVal,
                &value,
                gpa.allocator(),
            );
            node.component.view_props.padding = value;
        },
        .childLayout => {
            var value: Component.ChildLayout = .{};
            _ = try jsoParser.jsObjectToStruct(
                Component.ChildLayout,
                js,
                complexVal,
                &value,
                gpa.allocator(),
            );
            node.component.view_props.child_layout = value;
        },
        .scroll => {
            var value: Component.Scroll = .{};
            _ = try jsoParser.jsObjectToStruct(
                Component.Scroll,
                js,
                complexVal,
                &value,
                gpa.allocator(),
            );
            node.component.view_props.scroll = value;
        },
        .style => {
            var value: Component.Style = .{};
            _ = try jsoParser.jsObjectToStruct(
                Component.Style,
                js,
                complexVal,
                &value,
                gpa.allocator(),
            );
            node.component.view_props.style = value;
            node.component.view_props.style.bg_color.populateColor() catch {};
        },
        .border => {
            var value: Component.Border = .{};
            _ = try jsoParser.jsObjectToStruct(
                Component.Border,
                js,
                complexVal,
                &value,
                gpa.allocator(),
            );
            node.component.view_props.border = value;
            node.component.view_props.border.fg_color.populateColor() catch {};
            node.component.view_props.border.bg_color.populateColor() catch {};
        },
        .clickable => {
            // const clickableValue: bool = undefined;
            // _ = napigen.napi_get_value_bool(js.env, complexVal, @constCast(&clickableValue));
            // std.log.debug("Setting clickable: {}", .{clickableValue});
            node.component.view_props.clickable = true;
        },
        .text => {
            log.debug("Setting text: {s}", .{simpleVal});
            const text_copy = try gpa.allocator().allocSentinel(u8, simpleVal.len, 0);
            @memcpy(text_copy, simpleVal);
            node.component.text = text_copy;
        },
        .textStyle => {
            var value: Component.TextProps = .{};
            _ = try jsoParser.jsObjectToStruct(
                Component.TextProps,
                js,
                complexVal,
                &value,
                gpa.allocator(),
            );
            node.component.text_props = value;
            node.component.text_props.bg_color.populateColor() catch {};
            node.component.text_props.fg_color.populateColor() catch {};
            node.component.text_props.ul_color.populateColor() catch {};
        },
    }
    log.debug("Updated component {}", .{node.component});

    // if (std.mem.eql(u8, params.property, "textContent")) {
    //     node.component.text = params.value;
    // } else if (std.mem.eql(u8, params.property, "fgColor")) {
    //     node.component.fg_color = try color.parseHexColor(params.value);
    // } else if (std.mem.eql(u8, params.property, "bgColor")) {
    //     node.component.bg_color = try color.parseHexColor(params.value);
    // } else if (std.mem.eql(u8, params.property, "height")) {
    //     node.component.height = try std.fmt.parseInt(u32, params.value, 10);
    // } else if (std.mem.eql(u8, params.property, "width")) {
    //     node.component.width = try std.fmt.parseInt(u32, params.value, 10);
    // }

    try bridge.rerender();
}

const insertNodeParams = struct {
    parent: u32,
    node: u32,
    anchor: ?u32,
};

fn insertNode(params: insertNodeParams) !void {
    bridge.g_state.render_mutex.lock();
    defer bridge.g_state.render_mutex.unlock();
    const parent = dom.nodeMap.get(params.parent) orelse return;
    const node = dom.nodeMap.get(params.node) orelse return;

    log.debug("[zig]: Inserting node with tag: {s} => {}\n", .{ node.component.string_id, params });
    const anchor = if (params.anchor) |a| dom.nodeMap.get(a) else null;

    dom.insertNode(parent, node, anchor);

    try bridge.rerender();
}

const isTextNodeParams = struct {
    node: u32,
};

fn isTextNode(params: isTextNodeParams) !bool {
    const node = dom.nodeMap.get(params.node) orelse return false;
    log.debug("isTextNode: {s}\n", .{node.component.string_id});

    return node.component.ctype == .text;
}

const removeNodeParams = struct {
    parent: u32,
    node: u32,
};

fn removeNode(params: removeNodeParams) !void {
    bridge.g_state.render_mutex.lock();
    defer bridge.g_state.render_mutex.unlock();
    const parent = dom.nodeMap.get(params.parent) orelse return;
    const node = dom.nodeMap.get(params.node) orelse return;
    log.debug("removeNode: {s}\n", .{node.component.string_id});

    dom.removeNode(parent, node);

    // var next_node = node.first_child;
    // while (next_node.next_sibling) |sibling| {
    //     next_node = sibling.next_sibling orelse break;
    // }

    try bridge.rerender();
}

const relationShip = enum(u8) {
    parent = 0,
    child,
    sibling,
    first_child,
};

const getRelatedNodesParams = struct {
    node: u32,
    relationship: u8,
};

fn getRelatedNodes(params: getRelatedNodesParams) !?u32 {
    const node = dom.nodeMap.get(params.node) orelse return null;
    log.debug("getRelatedNodes: {s} rel:{}\n", .{ node.component.string_id, params.relationship });

    if (params.relationship > @intFromEnum(relationShip.first_child)) {
        return null;
    }
    const rel: relationShip = @enumFromInt(params.relationship);
    const related_node = switch (rel) {
        .child => node.first_child,
        .sibling => node.next_sibling,
        .first_child => node.first_child,
        .parent => node.parent,
    };

    if (related_node) |related| {
        return related.component.id.id;
    }

    return null;
}

fn shutdown(_: *napigen.JsContext) void {
    log.debug("Shutting down\n", .{});

    bridge.tuiShutdown(gpa.allocator());

    log_file.close();
    _ = gpa.deinit();
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

    try js.setNamedProperty(
        exports,
        "createElement",
        try js.createFunction(createElement),
    );

    try js.setNamedProperty(
        exports,
        "replaceText",
        try js.createFunction(replaceText),
    );

    try js.setNamedProperty(
        exports,
        "setProperty",
        try js.createFunction(setProperty),
    );

    try js.setNamedProperty(
        exports,
        "insertNode",
        try js.createFunction(insertNode),
    );

    try js.setNamedProperty(
        exports,
        "isTextNode",
        try js.createFunction(isTextNode),
    );

    try js.setNamedProperty(
        exports,
        "removeNode",
        try js.createFunction(removeNode),
    );

    try js.setNamedProperty(
        exports,
        "getRelatedNodes",
        try js.createFunction(getRelatedNodes),
    );

    try js.setNamedProperty(
        exports,
        "shutdown",
        try js.createFunction(shutdown),
    );
    return exports;
}
