const std = @import("std");
const cl = @import("zclay");
const vaxis = @import("vaxis");
const Component = @import("components.zig");
const bridge = @import("bridge");
const dom = @import("dom.zig");
const breakLongWords = @import("./break-text.zig").breakLongWords;

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
        .x = @as(u16, if (bounding_box.x < 0) 0 else @intFromFloat(bounding_box.x)),
        .y = @as(u16, if (bounding_box.y < 0) 0 else @intFromFloat(bounding_box.y)),
        .width = @as(u16, if (bounding_box.width < 0) 0 else @intFromFloat(bounding_box.width)),
        .height = @as(u16, if (bounding_box.height < 0) 0 else @intFromFloat(bounding_box.height)),
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
    if (bounding_box.y + 1 > scissor_box.y + scissor_box.height or bounding_box.y < scissor_box.y) {
        return;
    }

	// TODO: Might cause issues with horizontal scrolling
    if (bounding_box.x + 1 > scissor_box.x + scissor_box.width or bounding_box.x < scissor_box.x) {
        return;
    }

    const text = config.string_contents.chars[0..@intCast(config.string_contents.length)];

    var col = bounding_box.x;

    var iter = win.screen.unicode.graphemeIterator(text);

    while (iter.next()) |grapheme| {
        if (@as(u16, @intCast(col)) > scissor_box.x + scissor_box.width) {
            break;
        }
        const s = grapheme.bytes(text);
        const w = win.gwidth(s);
        if (w == 0) continue;

        var style = component.text_props.toVaxis();

        const current_cell_opt = win.readCell(
            bounding_box.x + @as(u16, @intCast(col)),
            bounding_box.y,
        );

        if (current_cell_opt) |current_cell| {
            style.fg = if (component.text_props.fg_color.unset) current_cell.style.fg else style.fg;
            style.bg = if (component.text_props.bg_color.unset) current_cell.style.bg else style.bg;
        }

        win.writeCell(col, bounding_box.y, .{
            .char = .{
                .grapheme = s,
                .width = @intCast(w),
            },
            .style = style,
        });
        col += w;
    }

    // for (text, 0..) |_, x| {
    //     if (bounding_box.x + @as(u16, @intCast(x)) > scissor_box.x + scissor_box.width) {
    //         break;
    //     }
    //
    //     std.log.debug("Drawing character at position {d}, {d}, {s}", .{
    //         bounding_box.x + @as(u16, @intCast(x)),
    //         bounding_box.y,
    //         text[x .. x + 1],
    //     });
    //
    //     win.writeCell(
    //         bounding_box.x + @as(u16, @intCast(x)),
    //         bounding_box.y,
    //         .{
    //             .char = .{ .grapheme = text[x .. x + 1] },
    //             .style = style,
    //         },
    //     );
    // }
}

fn consoleDrawRectangle(
    win: *vaxis.Window,
    component: *const Component,
    bounding_box: BoundingBox,
    config: cl.RectangleRenderData,
    scissor_box: BoundingBox,
) void {
    _ = config;
    // std.log.debug("Rendering rect: {}", .{bounding_box});
    const top_start = bounding_box.y;
    const top_end = bounding_box.y + bounding_box.height;
    const left_start = bounding_box.x;
    const left_end = bounding_box.x + bounding_box.width;

    const opts = component.view_props.border;

    const glyphs = switch (opts.type) {
        .single_rounded => Component.single_rounded,
        .single_squared => Component.single_rounded,
        .double_squared => Component.double_squared,
        .thick_squared => Component.thick_squared,
        .thin_squared => Component.thin_squared,
        .hug_vertical, .hug_vertical_flipped, .hug_horizontal, .hug_horizontal_flipped => Component.thick_hug,
    };

    // For hug borders, the order is: top bottom left right (different from others)
    const is_hug_border = switch (opts.type) {
        .hug_vertical, .hug_vertical_flipped, .hug_horizontal, .hug_horizontal_flipped => true,
        else => false,
    };

    // Check if we're using a flipped variant
    const is_flipped = switch (opts.type) {
        .hug_vertical_flipped, .hug_horizontal_flipped => true,
        else => false,
    };

    // For hug borders with flipped variants
    var top_glyph_idx: usize = 0;
    var bottom_glyph_idx: usize = 1;
    var left_glyph_idx: usize = 2;
    var right_glyph_idx: usize = 3;

    // Swap top/bottom or left/right for flipped variants
    if (is_flipped) {
        if (opts.type == .hug_vertical_flipped) {
            // Swap left and right
            left_glyph_idx = 3;
            right_glyph_idx = 2;
        } else if (opts.type == .hug_horizontal_flipped) {
            // Swap top and bottom
            top_glyph_idx = 1;
            bottom_glyph_idx = 0;
        }
    }

    // For regular borders
    const top_edge: Cell.Character = if (is_hug_border) .{ .grapheme = glyphs[top_glyph_idx], .width = 1 } else .{ .grapheme = glyphs[1], .width = 1 };
    const bottom_edge: Cell.Character = if (is_hug_border) .{ .grapheme = glyphs[bottom_glyph_idx], .width = 1 } else .{ .grapheme = glyphs[1], .width = 1 };
    const left_edge: Cell.Character = if (is_hug_border) .{ .grapheme = glyphs[left_glyph_idx], .width = 1 } else .{ .grapheme = glyphs[3], .width = 1 };
    const right_edge: Cell.Character = if (is_hug_border) .{ .grapheme = glyphs[right_glyph_idx], .width = 1 } else .{ .grapheme = glyphs[3], .width = 1 };

    // For non-hug borders, these are used directly
    const top_left: Cell.Character = .{ .grapheme = glyphs[0], .width = 1 };
    const horizontal: Cell.Character = .{ .grapheme = glyphs[1], .width = 1 };
    const top_right: Cell.Character = .{ .grapheme = glyphs[2], .width = 1 };
    const vertical: Cell.Character = .{ .grapheme = glyphs[3], .width = 1 };
    const bottom_right: Cell.Character = .{ .grapheme = glyphs[4], .width = 1 };
    const bottom_left: Cell.Character = .{ .grapheme = glyphs[5], .width = 1 };

    const loc: Component.BorderOptions.Locations = .{
        .bottom = opts.where.bottom,
        .left = opts.where.left,
        .right = opts.where.right,
        .top = opts.where.top,
    };

    var grapheme: Cell.Character = .{ .grapheme = " ", .width = 1 };
    const style: Cell.Style = .{
        .fg = opts.fg_color.color,
        .bg = if (opts.bg_color.unset) component.view_props.style.bg_color.color else opts.bg_color.color,
    };

    for (top_start..top_end) |y| {
        if (top_end > scissor_box.y + scissor_box.height) {
            break;
        }
        for (left_start..left_end) |x| {
            if (left_end > scissor_box.x + scissor_box.width) {
                break;
            }

            win.writeCell(
                @as(u16, @intCast(x)),
                @as(u16, @intCast(y)),
                .{
                    .char = .{ .grapheme = " ", .width = 1 },
                    .style = .{
                        .fg = .default,
                        .bg = component.view_props.style.bg_color.color,
                    },
                },
            );

            const is_top = if (bounding_box.height <= 1) true else y == top_start;
            const is_bottom = if (bounding_box.height <= 1) false else y == top_end - 1;
            const is_left = if (bounding_box.width <= 1) true else x == left_start;
            const is_right = if (bounding_box.width <= 1) false else x == left_end - 1;

            const on_border = is_top or is_bottom or is_left or is_right;
            const border_enabled = loc.top or loc.bottom or loc.left or loc.right;
            if (on_border and border_enabled) {
                // For hug borders, handle corners based on variant
                if (is_hug_border) {
                    const is_horizontal = switch (opts.type) {
                        .hug_horizontal, .hug_horizontal_flipped => true,
                        else => false,
                    };

                    // Handle corners for hug borders
                    if (is_top and is_left) {
                        grapheme = if (loc.top and loc.left)
                            (if (is_horizontal) top_edge else left_edge)
                        else if (loc.top) top_edge else if (loc.left) left_edge else grapheme;
                    } else if (is_top and is_right) {
                        grapheme = if (loc.top and loc.right)
                            (if (is_horizontal) top_edge else right_edge)
                        else if (loc.top) top_edge else if (loc.right) right_edge else grapheme;
                    } else if (is_bottom and is_left) {
                        grapheme = if (loc.bottom and loc.left)
                            (if (is_horizontal) bottom_edge else left_edge)
                        else if (loc.bottom) bottom_edge else if (loc.left) left_edge else grapheme;
                    } else if (is_bottom and is_right) {
                        grapheme = if (loc.bottom and loc.right)
                            (if (is_horizontal) bottom_edge else right_edge)
                        else if (loc.bottom) bottom_edge else if (loc.right) right_edge else grapheme;
                    }
                    // Handle edges for hug borders
                    else if (is_top and loc.top) {
                        grapheme = top_edge;
                    } else if (is_bottom and loc.bottom) {
                        grapheme = bottom_edge;
                    } else if (is_left and loc.left) {
                        grapheme = left_edge;
                    } else if (is_right and loc.right) {
                        grapheme = right_edge;
                    }
                } else {
                    // Handle corners for regular borders
                    if (is_top and is_left) {
                        grapheme = if (loc.top and loc.left) top_left else if (loc.top) horizontal else if (loc.left) vertical else grapheme;
                    } else if (is_top and is_right) {
                        grapheme = if (loc.top and loc.right) top_right else if (loc.top) horizontal else if (loc.right) vertical else grapheme;
                    } else if (is_bottom and is_left) {
                        grapheme = if (loc.bottom and loc.left) bottom_left else if (loc.bottom) horizontal else if (loc.left) vertical else grapheme;
                    } else if (is_bottom and is_right) {
                        grapheme = if (loc.bottom and loc.right) bottom_right else if (loc.bottom) horizontal else if (loc.right) vertical else grapheme;
                    }
                    // Handle edges for regular borders
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

                if ((is_top and loc.top) or (is_bottom and loc.bottom) or
                    (is_left and loc.left) or (is_right and loc.right))
                {
                    win.writeCell(
                        @as(u16, @intCast(x)),
                        @as(u16, @intCast(y)),
                        .{
                            .char = grapheme,
                            .style = style,
                        },
                    );
                }

                // std.log.debug("Border type: {s}", .{@tagName(component.view_props.border.type)});
                // std.log.debug("Border where: {any}", .{component.view_props.border.where});
                // std.log.debug("x: {}, y: {}, is_top: {}, is_bottom: {}, is_left: {}, is_right: {}", .{
                //     x,
                //     y,
                //     is_top,
                //     is_bottom,
                //     is_left,
                //     is_right,
                // });
                // std.log.debug("grapheme: {s}", .{grapheme.grapheme});
                // std.log.debug("style: {any} {any}", .{ style.fg.rgb, style.bg.rgb });
            }
        }
    }
}

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

pub fn clayTerminalRenderValidate(
    allocator: std.mem.Allocator,
    win: *vaxis.Window,
    renderCommands: []cl.RenderCommand,
) !bool {
    for (0..renderCommands.len) |j| {
        const render_command = renderCommands[j];

        switch (render_command.command_type) {
            .rectangle => {
                const comp: *Component = @ptrCast(@alignCast(render_command.user_data));
                comp.width = @intFromFloat(render_command.bounding_box.width);
                comp.height = @intFromFloat(render_command.bounding_box.height);
            },
            .text => {
                const config = render_command.render_data.text;
                const comp: *Component = @ptrCast(@alignCast(render_command.user_data));

                const node = dom.nodeMap.get(comp.id.id) orelse continue;
                const parent_node = node.parent orelse continue;
                const parent_comp: *Component = parent_node.component;
                if (parent_comp.width <= 0) continue;
                var max_w: u16 = parent_comp.width - 1;
                const padding = parent_comp.view_props.padding.applyBorder(parent_comp.view_props.border.where).toClay();
                max_w -= padding.left;
                max_w -= padding.right;

                const text = config.string_contents.chars[0..@intCast(config.string_contents.length)];
                const text_w = win.gwidth(text);

                // std.log.debug("=> {s} width: {} full text len{} Bounding box width: {}, breaks: {}", .{
                //     text,
                //     text_w,
                //     parent_comp.text.len,
                //     max_w,
                //     comp.breaks,
                // });

                std.log.debug("text: {s} text_w: {} max_w: {}", .{ comp.text, text_w, max_w });
                if (parent_comp.view_props.scroll.horizontal) {
                    // std.log.debug("Horizontal scroll", .{});
                    continue;
                }
                if (text_w > max_w + 1) {
                    comp.text = try breakLongWords(allocator, comp.text, max_w);
                    std.log.debug("Breaking text: {s}", .{comp.text});
                    return true;
                }
            },
            else => {},
        }
    }

    return false;
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

        // std.log.debug("Recieved render command: {s}", .{@tagName(render_command.command_type)});

        // const component = componentMap.get(render_command.id);

        // if (component) |comp| {
        switch (render_command.command_type) {
            .text => {
                const comp: *Component = @ptrCast(@alignCast(render_command.user_data));
                // std.log.debug("Recieved text:\n{s}\n</{s}>", .{ comp.text, comp.string_id });
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
                const comp: *Component = @ptrCast(@alignCast(render_command.user_data));
                // std.log.debug("Recieved component:\n{}\n</{s}>", .{ comp, comp.string_id });
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
