const std = @import("std");
const cl = @import("zclay");
const vaxis = @import("vaxis");
const Component = @import("components.zig");
const bridge = @import("bridge");

const HashMap = std.HashMap;

const Cell = vaxis.Cell;

pub const StringHashMap = HashMap(
    []const u8,
    Component,
    StringContext,
    std.hash_map.default_max_load_percentage,
);

pub const IdHashMap = std.hash_map.AutoHashMap(u32, Component);

pub var componentMap: IdHashMap = undefined;

const StringContext = struct {
    pub fn hash(self: @This(), s: []const u8) u64 {
        _ = self;
        return std.hash_map.hashString(s);
    }

    pub fn eql(self: @This(), a: []const u8, b: []const u8) bool {
        _ = self;
        return std.mem.eql(u8, a, b);
    }
};

const BoundingBox = struct {
    x: u16,
    y: u16,
    width: u16,
    height: u16,
};

fn convBoundingBox(
    bounding_box: cl.BoundingBox,
) BoundingBox {
    return BoundingBox{
        .x = @as(u16, @intFromFloat(bounding_box.x)),
        .y = @as(u16, @intFromFloat(bounding_box.y)),
        .width = @as(u16, @intFromFloat(bounding_box.width)),
        .height = @as(u16, @intFromFloat(bounding_box.height)),
    };
}

fn clayToVaxisColor(
    clayColor: [4]f32,
) vaxis.Color {
    return vaxis.Color{
        .rgb = .{
            @as(u8, @intFromFloat(clayColor[0])),
            @as(u8, @intFromFloat(clayColor[1])),
            @as(u8, @intFromFloat(clayColor[2])),
        },
    };
}

fn consoleDrawText(
    win: *vaxis.Window,
    component: *const Component,
    bounding_box: BoundingBox,
    config: cl.TextRenderData,
    scissor_box: BoundingBox,
) void {
    const text = config.string_contents.chars[0..@intCast(config.string_contents.length)];

    for (text, 0..) |_, x| {
        if (bounding_box.x + @as(u16, @intCast(x)) > scissor_box.x + scissor_box.width) {
            break;
        }

        std.log.debug("Drawing character at position {d}, {d}, {s}", .{
            bounding_box.x + @as(u16, @intCast(x)),
            bounding_box.y,
            text[x .. x + 1],
        });

        win.writeCell(
            bounding_box.x + @as(u16, @intCast(x)),
            bounding_box.y,
            .{
                .char = .{ .grapheme = text[x .. x + 1] },
                .style = .{ .fg = component.fg_color, .bg = component.bg_color },
            },
        );
    }
}

fn consoleDrawRectangle(
    win: *vaxis.Window,
    component: *const Component,
    bounding_box: BoundingBox,
    config: cl.RectangleRenderData,
    scissor_box: BoundingBox,
) void {
    _ = config;
    const top_start = bounding_box.y;
    const top_end = bounding_box.y + bounding_box.height;
    const left_start = bounding_box.x;
    const left_end = bounding_box.x + bounding_box.width;

    for (top_start..top_end) |y| {
        if (top_end > scissor_box.y + scissor_box.height) {
            break;
        }
        for (left_start..left_end) |x| {
            if (left_end > scissor_box.x + scissor_box.width) {
                break;
            }

            const opts = component.border;

            const glyphs = Component.single_rounded;

            const top_left: Cell.Character = .{ .grapheme = glyphs[0], .width = 1 };
            const horizontal: Cell.Character = .{ .grapheme = glyphs[1], .width = 1 };
            const top_right: Cell.Character = .{ .grapheme = glyphs[2], .width = 1 };
            const vertical: Cell.Character = .{ .grapheme = glyphs[3], .width = 1 };
            const bottom_right: Cell.Character = .{ .grapheme = glyphs[4], .width = 1 };
            const bottom_left: Cell.Character = .{ .grapheme = glyphs[5], .width = 1 };

            const loc: Component.BorderOptions.Locations = switch (opts.where) {
                .none => .{},
                .all => .{ .top = true, .bottom = true, .right = true, .left = true },
                .bottom => .{ .bottom = true },
                .right => .{ .right = true },
                .left => .{ .left = true },
                .top => .{ .top = true },
                .other => |loc| loc,
            };

            var grapheme: Cell.Character = .{ .grapheme = " ", .width = 1 };
            var style: Cell.Style = .{
                .fg = component.fg_color,
                .bg = component.bg_color,
            };

            const is_top = y == top_start;
            const is_bottom = y == top_end - 1;
            const is_left = x == left_start;
            const is_right = x == left_end - 1;

            const on_border = is_top or is_bottom or is_left or is_right;
            if (on_border) {
                style = opts.style;

                // Handle corners first
                if (is_top and is_left) {
                    grapheme = if (loc.top and loc.left) top_left else if (loc.top) horizontal else if (loc.left) vertical else grapheme;
                } else if (is_top and is_right) {
                    grapheme = if (loc.top and loc.right) top_right else if (loc.top) horizontal else if (loc.right) vertical else grapheme;
                } else if (is_bottom and is_left) {
                    grapheme = if (loc.bottom and loc.left) bottom_left else if (loc.bottom) horizontal else if (loc.left) vertical else grapheme;
                } else if (is_bottom and is_right) {
                    grapheme = if (loc.bottom and loc.right) bottom_right else if (loc.bottom) horizontal else if (loc.right) vertical else grapheme;
                }
                // Handle edges
                else if (is_top and loc.top) {
                    grapheme = horizontal;
                } else if (is_bottom and loc.bottom) {
                    grapheme = horizontal;
                } else if (is_left and loc.left) {
                    grapheme = vertical;
                } else if (is_right and loc.right) {
                    grapheme = vertical;
                }
            }

            win.writeCell(
                @as(u16, @intCast(x)),
                @as(u16, @intCast(y)),
                .{
                    .char = grapheme,
                    .style = style,
                },
            );
        }
    }
}

pub var allocator: std.mem.Allocator = null;
pub var display_width: vaxis.DisplayWidth = undefined;

pub fn consoleMeasureText(
    text: []const u8,
    config: *cl.TextElementConfig,
    _: void,
) cl.Dimensions {
    _ = config; // Unused parameter

    const width = vaxis.gwidth.gwidth(text, .unicode, &display_width);

    return .{ .w = @floatFromInt(width), .h = 1 };
}

pub fn clayTerminalRender(
    win: *vaxis.Window,
    renderCommands: []cl.RenderCommand,
    width: i32,
    height: i32,
    // _: i32,
    // _: i32,
) !void {
    const fullWindow = cl.BoundingBox{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(width),
        .height = @floatFromInt(height),
    };

    var scissor_box = fullWindow;

    for (0..renderCommands.len) |j| {
        const render_command = renderCommands[j];
        const bounding_box = render_command.bounding_box;

        std.log.debug("Recieved render command: {s}", .{@tagName(render_command.command_type)});

        // const component = componentMap.get(render_command.id);

        const comp: *Component = @ptrCast(@alignCast(render_command.user_data));

        // if (component) |comp| {
        std.log.debug("Recieved component:\n{}\n</{s}>", .{ comp, comp.id });
        switch (render_command.command_type) {
            .text => {
                const config = render_command.render_data.text;
                consoleDrawText(
                    win,
                    comp,
                    convBoundingBox(bounding_box),
                    config,
                    convBoundingBox(scissor_box),
                );
            },
            .scissor_start => {
                scissor_box = bounding_box;
            },
            .scissor_end => {
                scissor_box = fullWindow;
            },
            .rectangle => {
                consoleDrawRectangle(
                    win,
                    comp,
                    convBoundingBox(bounding_box),
                    render_command.render_data.rectangle,
                    convBoundingBox(scissor_box),
                );
            },
            else => {},
        }
        // } else {
        //     var iter = componentMap.iterator();
        //     std.log.debug("Component not found in map for {}, iterating over map...", .{render_command.id});
        //     while (iter.next()) |entry| {
        //         const comp = entry.value_ptr.*;
        //         const key = entry.key_ptr.*;
        //         std.log.debug("Map component {}:\n{}\n</{s}>", .{ key, comp, comp.id });
        //     }
        // }
    }
}
