const std = @import("std");
const cl = @import("zclay");
const colorUtil = @import("color.zig");
const print = std.debug.print;

// Assuming these types are defined elsewhere in your Zig codebase
// You'll need to import or define these types appropriately
const Clay_BoundingBox = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
};

const RESET = "\x1b[0m";
const BG_BLACK = "\x1b[40m";
const BG_RED = "\x1b[41m";
const BG_GREEN = "\x1b[42m";
const BG_YELLOW = "\x1b[43m";
const BG_BLUE = "\x1b[44m";
const BG_MAGENTA = "\x1b[45m";
const BG_CYAN = "\x1b[46m";
const BG_WHITE = "\x1b[47m";

const Color = struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32,
};

const Clay_Dimensions = struct {
    width: f32,
    height: f32,
};

const Clay_StringSlice = struct {
    chars: [*]const u8,
    length: usize,
};

const Clay_TextElementConfig = struct {
    // Define fields as needed
};

const Clay_RenderCommandArray = struct {
    // Define fields as needed
    length: usize,

    pub fn get() *Clay_RenderCommand {
        // Implementation needed
        unreachable;
    }
};

const Clay_RenderCommand = struct {
    commandType: Clay_RenderCommandType,
    boundingBox: Clay_BoundingBox,
    renderData: Clay_RenderData,
};

const Clay_RenderCommandType = enum {
    CLAY_RENDER_COMMAND_TYPE_TEXT,
    CLAY_RENDER_COMMAND_TYPE_SCISSOR_START,
    CLAY_RENDER_COMMAND_TYPE_SCISSOR_END,
    CLAY_RENDER_COMMAND_TYPE_RECTANGLE,
    CLAY_RENDER_COMMAND_TYPE_BORDER,
};

const Clay_RenderData = union(Clay_RenderCommandType) {
    CLAY_RENDER_COMMAND_TYPE_TEXT: Clay_TextRenderData,
    CLAY_RENDER_COMMAND_TYPE_SCISSOR_START: void,
    CLAY_RENDER_COMMAND_TYPE_SCISSOR_END: void,
    CLAY_RENDER_COMMAND_TYPE_RECTANGLE: Clay_RectangleRenderData,
    CLAY_RENDER_COMMAND_TYPE_BORDER: Clay_BorderRenderData,
};

const Clay_TextRenderData = struct {
    stringContents: Clay_StringSlice,
};

const Clay_RectangleRenderData = struct {
    backgroundColor: Color,
};

const Clay_BorderRenderData = struct {
    width: struct {
        left: f32,
        right: f32,
        top: f32,
        bottom: f32,
    },
    cornerRadius: struct {
        topLeft: f32,
        topRight: f32,
        bottomLeft: f32,
        bottomRight: f32,
    },
    color: Color,
};

pub fn clayColorToTerminallibColor(color: cl.Color) Color {
    return Color{
        .r = color[0],
        .g = color[1],
        .b = color[2],
        .a = color[3],
    };
}
// Configuration for overflow trapping
const CLAY_OVERFLOW_TRAP = false; // Set to true if you want overflow trapping

inline fn consoleMovesCursor(x: i32, y: i32) void {
    print("\x1b[{d};{d}H", .{ y + 1, x + 1 });
}

pub fn clayPointIsInsideRect(point: cl.Vector2, rect: cl.BoundingBox) bool {
    // TODO this function is a copy of Clay__PointIsInsideRect but that one is internal, I don't know if we want
    // TODO to expose Clay__PointIsInsideRect
    return point.x >= rect.x and
        point.x < rect.x + rect.width and
        point.y >= rect.y and
        point.y < rect.y + rect.height;
}

inline fn consoleDrawRectangle(
    x0: i32,
    y0: i32,
    width: i32,
    height: i32,
    clay_color: cl.Color,
    scissorBox: cl.BoundingBox,
) void {
    const color = clayColorToTerminallibColor(clay_color);
    // const termColor = colorUtil.getClosestAnsiBackgroundColor(colorUtil.Rgb{ .r = color.r, .g = color.g, .b = color.b });
    const termColor = colorUtil.getClosestAnsiBackground(colorUtil.Color{ .r = 0, .g = 0, .b = 0 });
    // const termColor = " ";
    // const average = (color.r + color.g + color.b + color.a) / 4.0 / 255.0;
    const average = color.a / 255.0;

    const debug = false;

    if (debug) {
        print("Rendering rect {d} {d} {d} {d}\n", .{
            x0,
            y0,
            width,
            height,
        });
    }

    var y: i32 = y0;
    while (y < height + y0) : (y += 1) {
        var x: i32 = x0;
        while (x < width + x0) : (x += 1) {
            if (!clayPointIsInsideRect(cl.Vector2{ .x = @floatFromInt(x), .y = @floatFromInt(y) }, scissorBox)) {
                continue;
            }

            if (debug) {
                print("===y: {d} x: {d} avg:{d} width: {d} height: {d}===", .{ y, x, average, width, height });
                continue;
            }

            consoleMovesCursor(x, y);
            print("{s} {s}", .{ termColor, RESET });
            if (average > 0.75) {
                // const char = "█";
                // print("{s}{s}{s}", .{ termColor, char, RESET });
            } else if (average > 0.5) {
                // const char = "▓";
                // print("{s}{s}{s}", .{ termColor, char, RESET });
                // print("▓", .{});
            } else if (average > 0.25) {
                // const char = "▒";
                // print("{s}{s}{s}", .{ termColor, char, RESET });
                // print("▒", .{});
            } else {
                // const char = "░";
                // print("{s}{s}{s}", .{ termColor, char, RESET });
                // print("░", .{});
            }
        }
    }
}

pub fn consoleMeasureText(
    text: []const u8,
    config: *cl.TextElementConfig,
    _: void,
) cl.Dimensions {
    _ = config; // Unused parameter
    var textSize = cl.Dimensions{ .w = 0, .h = 0 };

    // TODO this function is very wrong, it measures in characters, I have no idea what is the size in pixels

    const columnWidth: i32 = 1;
    var maxTextWidth: f32 = 0.0;
    var lineTextWidth: f32 = 0;
    var textHeight: f32 = 1;

    for (0..text.len) |i| {
        if (text[i] == '\n') {
            maxTextWidth = @max(maxTextWidth, lineTextWidth);
            lineTextWidth = 0;
            textHeight += 1;
            continue;
        }
        lineTextWidth += 1;
    }

    maxTextWidth = @max(maxTextWidth, lineTextWidth);

    textSize.w = maxTextWidth * @as(f32, @floatFromInt(columnWidth));
    textSize.h = textHeight * @as(f32, @floatFromInt(columnWidth));

    return textSize;
}

/// Renders text to the terminal
fn consoleDrawText(
    bounding_box: cl.BoundingBox,
    config: cl.TextRenderData,
    scissor_box: cl.BoundingBox,
) void {
    const text = config.string_contents.chars[0..@intCast(config.string_contents.length)];
    var y: i32 = 0;
    var lineX: i32 = 0;

    const debug = false;

    if (debug) {
        print("Rendering text {d} {d} {d} {d}\n", .{
            @as(i32, @intFromFloat(bounding_box.x)),
            @as(i32, @intFromFloat(bounding_box.y)),
            @as(i32, @intFromFloat(bounding_box.width)),
            @as(i32, @intFromFloat(bounding_box.height)),
        });
    }

    for (text, 0..) |_, x| {
        if (text[x] == '\n') {
            y += 1;
            lineX = 0;
            continue;
        }

        const cursorX = @as(i32, @intFromFloat(bounding_box.x)) + lineX;
        const cursorY = @as(i32, @intFromFloat(bounding_box.y)) + y;

        if (@as(f32, @floatFromInt(cursorY)) > scissor_box.y + scissor_box.height) {
            break;
        }

        if (!clayPointIsInsideRect(cl.Vector2{ .x = @floatFromInt(cursorX), .y = @floatFromInt(cursorY) }, scissor_box)) {
            lineX += 1;
            continue;
        }

        lineX += 1;

        if (debug) {
            continue;
        }
        consoleMovesCursor(cursorX, 0);
        print("{c}", .{text[x]});
    }
}

pub fn clayTerminalRender(
    renderCommands: []cl.RenderCommand,
    width: i32,
    height: i32,
    // _: i32,
    // _: i32,
) !void {
    print("\x1b[H\x1b[J", .{}); // Clear
    // print("start", .{}); // Clear

    const fullWindow = cl.BoundingBox{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(width),
        .height = @floatFromInt(height),
    };

    var scissor_box = fullWindow;

    // print("Rendering {s} commands\n", .{scissor_box});

    for (0..renderCommands.len) |j| {
        const render_command = renderCommands[j];
        const bounding_box = render_command.bounding_box;

        // switch (render_command.command_type) {
        //     .text => {
        //         print("Rendering text {d} {d} {d} {d}\n", .{
        //             @as(i32, @intFromFloat(bounding_box.x)),
        //             @as(i32, @intFromFloat(bounding_box.y)),
        //             @as(i32, @intFromFloat(bounding_box.width)),
        //             @as(i32, @intFromFloat(bounding_box.height)),
        //         });
        //     },
        //     .scissor_start => {
        //         print("Scissor start\n", .{});
        //     },
        //     .scissor_end => {
        //         print("Scissor end\n", .{});
        //     },
        //     .rectangle => {
        //         print("Rectangle {d} {d} {d} {d}\n", .{
        //             @as(i32, @intFromFloat(bounding_box.x)),
        //             @as(i32, @intFromFloat(bounding_box.y)),
        //             @as(i32, @intFromFloat(bounding_box.width)),
        //             @as(i32, @intFromFloat(bounding_box.height)),
        //         });
        //
        //         const data = render_command.render_data.rectangle;
        //         consoleDrawRectangle(
        //             @intFromFloat(bounding_box.x),
        //             @intFromFloat(bounding_box.y),
        //             @intFromFloat(bounding_box.width),
        //             @intFromFloat(bounding_box.height),
        //             data.background_color,
        //             scissor_box,
        //         );
        //     },
        //     .border => {
        //         print("Border\n", .{});
        //     },
        //     .image => {
        //         print("Image\n", .{});
        //     },
        //     .none => {
        //         print("None\n", .{});
        //     },
        //     .custom => {
        //         print("Custom\n", .{});
        //     },
        // }

        switch (render_command.command_type) {
            .text => {
                const config = render_command.render_data.text;
                consoleDrawText(bounding_box, config, scissor_box);
            },
            .scissor_start => {
                scissor_box = bounding_box;
            },
            .scissor_end => {
                scissor_box = fullWindow;
            },
            .rectangle => {
                const data = render_command.render_data.rectangle;
                consoleDrawRectangle(
                    @intFromFloat(bounding_box.x),
                    @intFromFloat(bounding_box.y),
                    @intFromFloat(bounding_box.width),
                    @intFromFloat(bounding_box.height),
                    data.background_color,
                    scissor_box,
                );
            },
            .border => {
                const data = render_command.render_data.border;

                // Left border
                if (data.width.left > 0) {
                    consoleDrawRectangle(
                        @intFromFloat(bounding_box.x),
                        @intFromFloat(bounding_box.y + data.corner_radius.top_left),
                        data.width.left,
                        @intFromFloat(bounding_box.height - data.corner_radius.top_left - data.corner_radius.bottom_left),
                        data.color,
                        scissor_box,
                    );
                }

                // Right border
                if (data.width.right > 0) {
                    consoleDrawRectangle(
                        @as(i32, @intFromFloat(bounding_box.x + bounding_box.width)) - data.width.right,
                        @intFromFloat(bounding_box.y + data.corner_radius.top_right),
                        data.width.right,
                        @intFromFloat(bounding_box.height - data.corner_radius.top_right - data.corner_radius.bottom_right),
                        data.color,
                        scissor_box,
                    );
                }

                // Top border
                if (data.width.top > 0) {
                    consoleDrawRectangle(
                        @intFromFloat(bounding_box.x + data.corner_radius.top_left),
                        @intFromFloat(bounding_box.y),
                        @intFromFloat(bounding_box.width - data.corner_radius.top_left - data.corner_radius.top_right),
                        data.width.top,
                        data.color,
                        scissor_box,
                    );
                }

                // Bottom border
                if (data.width.bottom > 0) {
                    consoleDrawRectangle(
                        @intFromFloat(bounding_box.x + data.corner_radius.bottom_left),
                        @as(i32, @intFromFloat(bounding_box.y + bounding_box.height)) - data.width.bottom,
                        @intFromFloat(bounding_box.width - data.corner_radius.bottom_left - data.corner_radius.bottom_right),
                        data.width.bottom,
                        data.color,
                        scissor_box,
                    );
                }
            },
            .image => {},
            .none => {},
            .custom => {},
        }
    }

    // consoleMovesCursor(-1, -1); // TODO make the user not be able to write
}
