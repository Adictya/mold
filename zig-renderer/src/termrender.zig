const unicode = @import("std").unicode;
const std = @import("std");
const cl = @import("zclay");
const uni = @import("uni.zig");
const colorUtil = @import("color.zig");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

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

pub const BorderCharacters = struct {
    // Using u21 to support Unicode box drawing characters
    top: u21 = '─',
    bottom: u21 = '─',
    left: u21 = '│',
    right: u21 = '│',
    top_left: u21 = '┌',
    top_right: u21 = '┐',
    bottom_left: u21 = '└',
    bottom_right: u21 = '┘',
};

/// A cell in the terminal buffer
const BufferCell = struct {
    char: u21 = ' ',
    bg_color: []const u8 = "",
    fg_color: []const u8 = "",
    modified: bool = false,
};

/// A 2D buffer for terminal rendering
pub const TermBuffer = struct {
    width: usize,
    height: usize,
    buffer: [][]BufferCell,
    allocator: Allocator,

    /// Initialize a new terminal buffer with the given dimensions
    pub fn init(allocator: Allocator, width: usize, height: usize) !*TermBuffer {
        var self = try allocator.create(TermBuffer);
        self.* = TermBuffer{
            .width = width,
            .height = height,
            .buffer = undefined,
            .allocator = allocator,
        };

        // Allocate the 2D buffer
        self.buffer = try allocator.alloc([]BufferCell, height);
        for (0..height) |y| {
            self.buffer[y] = try allocator.alloc(BufferCell, width);
            for (0..width) |x| {
                self.buffer[y][x] = BufferCell{};
            }
        }

        return self;
    }

    /// Free the buffer memory
    pub fn deinit(self: *TermBuffer) void {
        for (0..self.height) |y| {
            self.allocator.free(self.buffer[y]);
        }
        self.allocator.free(self.buffer);
        self.allocator.destroy(self);
    }

    /// Clear the buffer
    pub fn clear(self: *TermBuffer) void {
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                self.buffer[y][x] = BufferCell{};
            }
        }
    }

    /// Set a character at the given position
    pub fn setChar(self: *TermBuffer, x: usize, y: usize, char: u21) void {
        if (x >= self.width or y >= self.height) return;
        self.buffer[y][x].char = char;
        self.buffer[y][x].modified = true;
    }

    /// Set background color at the given position
    pub fn setBgColor(self: *TermBuffer, x: usize, y: usize, color: []const u8) void {
        if (x >= self.width or y >= self.height) return;
        self.buffer[y][x].bg_color = color;
        self.buffer[y][x].modified = true;
    }

    /// Set foreground color at the given position
    pub fn setFgColor(self: *TermBuffer, x: usize, y: usize, color: []const u8) void {
        if (x >= self.width or y >= self.height) return;
        self.buffer[y][x].fg_color = color;
        self.buffer[y][x].modified = true;
    }

    /// Flush the buffer to stdout
    pub fn flush(self: *TermBuffer) !void {
        var unicodeBuffer: [4]u8 = undefined;
        print("\x1b[H\x1b[J", .{}); // Clear screen

        for (0..self.height) |y| {
            for (0..self.width) |x| {
                const cell = self.buffer[y][x];
                if (cell.modified) {
                    print("\x1b[{d};{d}H", .{ y + 1, x + 1 }); // Move cursor
                    if (cell.bg_color.len > 0) {
                        print("{s}", .{cell.bg_color});
                    }
                    if (cell.fg_color.len > 0) {
                        print("{s}", .{cell.fg_color});
                    }
                    const uniChar = try uni.codepointToUtf8Bytes(cell.char, &unicodeBuffer);
                    print("{s}{s}", .{ uniChar, RESET });
                }
            }
        }
    }
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

/// Global terminal buffer
var term_buffer: ?*TermBuffer = null;

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
    const termColor = colorUtil.getTrueColorBackground(std.heap.page_allocator, colorUtil.Color{
        .r = @intFromFloat(color.r),
        .g = @intFromFloat(color.g),
        .b = @intFromFloat(color.b),
    }) catch {
        std.debug.panic("Failed to get true color background", .{});
    };
    // const termColor = colorUtil.getClosestAnsiBackground(colorUtil.Color{ .r = 0, .g = 0, .b = 0 });
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

            // Write to buffer instead of stdout
            if (term_buffer) |buffer| {
                const ux: usize = @intCast(x);
                const uy: usize = @intCast(y);
                if (ux < buffer.width and uy < buffer.height) {
                    buffer.setBgColor(ux, uy, termColor);
                    buffer.setChar(ux, uy, ' ');
                }
            } else {
                // Fallback to direct output if buffer not initialized
                consoleMovesCursor(x, y);
                print("{s} {s}", .{ termColor, RESET });
            }

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

/// Renders a border with custom characters
fn consoleRenderBorder(
    bounding_box: cl.BoundingBox,
    border_chars: BorderCharacters,
    color: cl.Color,
) void {
    const fg_color = colorUtil.getTrueColorForeground(std.heap.page_allocator, colorUtil.Color{
        .r = @intFromFloat(color[0]),
        .g = @intFromFloat(color[1]),
        .b = @intFromFloat(color[2]),
    }) catch {
        std.debug.panic("Failed to get true color foreground", .{});
    };

    const x0: usize = @intFromFloat(bounding_box.x);
    const y0: usize = @intFromFloat(bounding_box.y);
    const width: usize = @intFromFloat(bounding_box.width);
    const height: usize = @intFromFloat(bounding_box.height);

    // Draw corners
    if (term_buffer) |buffer| {
        // Top-left corner
        const tlx: usize = @intCast(x0);
        const tly: usize = @intCast(y0);
        if (tlx < buffer.width and tly < buffer.height) {
            buffer.setFgColor(tlx, tly, fg_color);
            buffer.setFgColor(tlx, tly, fg_color);
            if (width > 1 and height > 1) {
                buffer.setChar(tlx, tly, border_chars.top_left);
            } else if (width > 1) {
                buffer.setChar(tlx, tly, border_chars.bottom);
            } else {
                buffer.setChar(tlx, tly, border_chars.top);
            }
        }

        // Top-right corner
        const trx: usize = @intCast(x0 + width - 1);
        const tr_y: usize = @intCast(y0);
        if (trx < buffer.width and tr_y < buffer.height) {
            buffer.setFgColor(trx, tr_y, fg_color);
            if (width > 1 and height > 1) {
                buffer.setChar(trx, tr_y, border_chars.top_right);
            } else if (width > 1) {
                buffer.setChar(trx, tr_y, border_chars.bottom);
            } else {
                buffer.setChar(trx, tr_y, border_chars.top);
            }
        }

        if (width > 1 and height > 1) {
            // Bottom-left corner
            const blx: usize = @intCast(x0);
            const bly: usize = @intCast(y0 + height - 1);
            if (blx < buffer.width and bly < buffer.height) {
                buffer.setFgColor(blx, bly, fg_color);
                buffer.setChar(blx, bly, border_chars.bottom_left);
            }

            // Bottom-right corner
            const brx: usize = @intCast(x0 + width - 1);
            const bry: usize = @intCast(y0 + height - 1);
            if (brx < buffer.width and bry < buffer.height) {
                buffer.setFgColor(brx, bry, fg_color);
                buffer.setChar(brx, bry, border_chars.bottom_right);
            }
        }

        if (width > 1) {
            // Draw top edge
            for (1..width - 1) |i| {
                const tx: usize = @intCast(x0 + i);
                const ty: usize = @intCast(y0);
                if (tx < buffer.width and ty < buffer.height) {
                    buffer.setFgColor(tx, ty, fg_color);
                    buffer.setChar(tx, ty, border_chars.top);
                }
            }

            // Draw bottom edge
            for (1..width - 1) |i| {
                const bx: usize = @intCast(x0 + i);
                const by: usize = @intCast(y0 + height - 1);
                if (bx < buffer.width and by < buffer.height) {
                    buffer.setFgColor(bx, by, fg_color);
                    buffer.setChar(bx, by, border_chars.bottom);
                }
            }
        }

        // Draw left edge
        if (height > 1) {
            for (1..height - 1) |i| {
                const lx: usize = @intCast(x0);
                const ly: usize = @intCast(y0 + i);
                if (lx < buffer.width and ly < buffer.height) {
                    buffer.setFgColor(lx, ly, fg_color);
                    buffer.setChar(lx, ly, border_chars.left);
                }
            }

            // Draw right edge
            for (1..height - 1) |i| {
                const rx: usize = @intCast(x0 + width - 1);
                const ry: usize = @intCast(y0 + i);
                if (rx < buffer.width and ry < buffer.height) {
                    buffer.setFgColor(rx, ry, fg_color);
                    buffer.setChar(rx, ry, border_chars.right);
                }
            }
        }
    }
}

/// Renders text to the terminal
fn consoleDrawText(
    bounding_box: cl.BoundingBox,
    config: cl.TextRenderData,
    scissor_box: cl.BoundingBox,
) void {
    const text = config.string_contents.chars[0..@intCast(config.string_contents.length)];
    const color = clayColorToTerminallibColor(config.text_color);
    const termColor = colorUtil.getTrueColorForeground(std.heap.page_allocator, colorUtil.Color{
        .r = @intFromFloat(color.r),
        .g = @intFromFloat(color.g),
        .b = @intFromFloat(color.b),
    }) catch {
        std.debug.panic("Failed to get true color background", .{});
    };
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

        // Write to buffer instead of stdout
        if (term_buffer) |buffer| {
            const ux: usize = @intCast(cursorX);
            const uy: usize = @intCast(cursorY);
            if (ux < buffer.width and uy < buffer.height) {
                buffer.setFgColor(ux, uy, termColor);
                buffer.setChar(ux, uy, text[x]);
            }
        } else {
            // Fallback to direct output if buffer not initialized
            consoleMovesCursor(cursorX, cursorY);
            print("{c}", .{text[x]});
        }
    }
}

pub fn clayTerminalRender(
    renderCommands: []cl.RenderCommand,
    width: i32,
    height: i32,
    // _: i32,
    // _: i32,
) !void {
    // Initialize the buffer if it doesn't exist or if dimensions have changed
    if (term_buffer) |buffer| {
        if (buffer.width != @as(usize, @intCast(width)) or buffer.height != @as(usize, @intCast(height))) {
            buffer.deinit();
            term_buffer = null;
        }
    }

    if (term_buffer == null) {
        term_buffer = try TermBuffer.init(std.heap.page_allocator, @intCast(width), @intCast(height));
    }

    // Clear the buffer
    if (term_buffer) |buffer| {
        buffer.clear();
    }

    const fullWindow = cl.BoundingBox{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(width),
        .height = @floatFromInt(height),
    };

    var scissor_box = fullWindow;

    // Render all commands to the buffer
    for (0..renderCommands.len) |j| {
        const render_command = renderCommands[j];
        const bounding_box = render_command.bounding_box;

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

                // Check if we have custom border characters in user_data
                if (render_command.user_data != null) {
                    // Extract border characters from user_data
                    const border_chars_ptr: *BorderCharacters = @ptrCast(@alignCast(render_command.user_data));

                    // Use the custom border rendering function
                    consoleRenderBorder(
                        bounding_box,
                        border_chars_ptr.*,
                        data.color,
                    );
                } else {
                    // Fallback to the original rectangle-based border rendering

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
                }
            },
            .image => {},
            .none => {},
            .custom => {},
        }
    }

    // Flush the buffer to stdout
    if (term_buffer) |buffer| {
        buffer.flush() catch {
            unreachable; // Handle any errors in flushing the buffer

        };
    }
}

/// Cleanup function to free the terminal buffer
pub fn clayTerminalCleanup() void {
    if (term_buffer) |buffer| {
        buffer.deinit();
        term_buffer = null;
    }
}
