const std = @import("std");
const vaxis = @import("vaxis");
const cl = @import("zclay");
const color = @import("color.zig");

const Component = @This();

pub const BorderOptions = vaxis.Window.BorderOptions;

pub const ComponentType = enum(u8) {
    box,
    text,
};

const Color = struct {
    hex: []const u8 = "",
    color: vaxis.Color,
    unset: bool = true,

    pub fn populateColor(self: *Color) !void {
        self.color = try color.parseHexColor(self.hex);
        self.unset = false;
        std.log.debug("Color populated: {s} {any}", .{ self.hex, self.color.rgb });
    }

    pub fn toClay(_: *const Color) cl.Color {
        return .{ 0, 0, 0, 255 };
    }
};

const defaultFgColor: Color = .{ .color = .{ .rgb = .{ 255, 255, 255 } } };
const defaultBgColor: Color = .{ .color = .{ .rgb = .{ 0, 0, 0 } } };

pub const Position = struct {
    offset: cl.Vector2 = .{ .x = 0, .y = 0 },
    parent_id: ?cl.ElementId = null,
    z_index: i16 = 0,
    attach_points: cl.FloatingAttachPoints = .{ .element = .left_top, .parent = .left_top },

    pub fn toClay(self: *const Position) cl.FloatingElementConfig {
        return .{
            .offset = self.offset,
            .z_index = self.z_index,
            .attach_points = self.attach_points,
        };
    }
};

pub const SizingConstraint = struct {
    minmax: cl.SizingMinMax = .{},
    percent: f32 = 0,
    type: cl.SizingType = .fit,

    pub fn toClay(self: *const SizingConstraint) cl.SizingAxis {
        if (self.type == .percent) {
            return .{
                .size = .{ .percent = self.percent },
                .type = .percent,
            };
        } else {
            return .{
                .size = .{
                    .minmax = .{
                        .min = self.minmax.min,
                        .max = self.minmax.max,
                    },
                },
                .type = self.type,
            };
        }
    }
};

pub const Sizing = struct {
    w: SizingConstraint = .{},
    h: SizingConstraint = .{},

    pub fn toClay(self: *const Sizing) cl.Sizing {
        return .{
            .w = self.w.toClay(),
            .h = self.h.toClay(),
        };
    }
};

pub const ChildLayout = struct {
    child_gap: u16 = 0,
    child_alignment: cl.ChildAlignment = .{},
    direction: cl.LayoutDirection = .left_to_right,
};

pub const Style = struct {
    bg_color: Color = defaultBgColor,
};

pub const BorderWhere = struct {
    top: bool = false,
    bottom: bool = false,
    left: bool = false,
    right: bool = false,
};

pub const BorderType = enum(u8) {
    single_rounded = 0,
    single_square = 1,
};

pub const Border = struct {
    where: BorderWhere = .{},
    type: BorderType = .single_rounded,
    color: Color = defaultFgColor,

    pub fn toClay(self: *const Border) cl.BorderElementConfig {
        return .{
            .width = .{
                .top = @intFromBool(self.where.top),
                .bottom = @intFromBool(self.where.bottom),
                .left = @intFromBool(self.where.left),
                .right = @intFromBool(self.where.right),
            },
        };
    }
};

pub const Scroll = cl.ClipElementConfig;

pub const ViewProps = struct {
    position: Position = .{},
    sizing: Sizing = .{},
    padding: cl.Padding = .{},
    child_layout: ChildLayout = .{},
    scroll: cl.ClipElementConfig = .{.horizontal = true, .vertical = true},
    style: Style = .{},
    border: Border = .{},
    // children are handled by the view element itself in Zig, not a prop

    pub fn toClay(self: *const ViewProps) cl.ElementDeclaration {
        return .{
            .layout = .{
                .sizing = self.sizing.toClay(),
                .padding = self.padding,
                .child_gap = self.child_layout.child_gap,
                .child_alignment = self.child_layout.child_alignment,
                .direction = self.child_layout.direction,
            },
            .background_color = self.style.bg_color.toClay(),
            .floating = self.position.toClay(),
            .border = self.border.toClay(),
            .clip = self.scroll,
        };
    }
};

pub const UnderlineType = enum(u8) {
    off = 0,
    single = 1,
    double = 2,
    curly = 3,
    dotted = 4,
    dashed = 5,
};

pub const TextProps = struct {
    fg_color: Color = defaultFgColor,
    bg_color: Color = defaultBgColor,
    ul_color: Color = defaultFgColor,
    ul_style: UnderlineType = .off,

    bold: bool = false,
    dim: bool = false,
    italic: bool = false,
    blink: bool = false,
    reverse: bool = false,
    invisible: bool = false,
    strikethrough: bool = false,

    wrap_mode: cl.TextElementConfigWrapMode = .words,
    alignment: cl.TextAlignment = .left,

    pub fn toClay(self: *const TextProps) cl.TextElementConfig {
        return .{
            .wrap_mode = self.wrap_mode,
            .alignement = self.alignment,
        };
    }
};

ctype: ComponentType,
id: cl.ElementId,
string_id: []const u8,
view_props: ViewProps = .{},
text_props: TextProps = .{},
height: u16 = 0,
width: u16 = 0,
text: []const u8 = "", // Null-terminated string for text content
breaks: u16 = 0,

pub const single_rounded: [6][]const u8 = .{ "╭", "─", "╮", "│", "╯", "╰" };

pub fn format(
    self: *const Component,
    comptime fmt_str: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    _ = fmt_str; // Unused, but part of the signature
    _ = options; // Unused, but part of the signature
    // Delegate to your custom `fmt` function which does the actual work
    try self.fmt(writer);
}

pub fn fmt(
    self: *const Component,
    writer: anytype,
) !void {
    try writer.print(
        "<{s} ctype: {s}, textContent: {s}>",
        .{
            self.string_id,
            @tagName(self.ctype), // More idiomatic for enums
            // self.view_props,
            // self.text_props,
            self.text,
        },
    );
    // try writer.print(
    //     "<{s} ctype: {s}, view: {}, text: {}, textContent: {s}>",
    //     .{
    //         self.string_id,
    //         @tagName(self.ctype), // More idiomatic for enums
    //         self.view_props,
    //         self.text_props,
    //         self.text,
    //     },
    // );

    // if (self.children) |children_slice| {
    //     for (children_slice) |child_component| {
    //         try writer.print("\n\t{any}", .{child_component}); // Added newline for better formatting
    //         try writer.print("\n\t</Component>", .{});
    //     }
    // }
}
