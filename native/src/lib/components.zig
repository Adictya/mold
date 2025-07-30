const std = @import("std");
const vaxis = @import("vaxis");
const cl = @import("zclay");

const Component = @This();

pub const BorderOptions = vaxis.Window.BorderOptions;

pub const ComponentType = enum(u8) {
    box,
    text,
};

ctype: ComponentType,
id: []const u8,
x: i32,
y: i32,
width: u32,
height: u32,
padding: cl.Padding = .{},
fg_color: vaxis.Color,
bg_color: vaxis.Color,
border: BorderOptions,
text: ?[]const u8, // Null-terminated string for text content
children: ?[]const @This(),

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
        "<{s} ctype: {s}, x: {}, y: {}, width: {}, height: {}, fg_color: {}, bg_color: {}, border: {}, text: {s}>",
        .{
            self.id,
            @tagName(self.ctype), // More idiomatic for enums
            self.x,
            self.y,
            self.width,
            self.height,
            self.fg_color,
            self.bg_color,
            self.border,
            if (self.text) |t| t else "null", // Still good for optional text
        },
    );

    // if (self.children) |children_slice| {
    //     for (children_slice) |child_component| {
    //         try writer.print("\n\t{any}", .{child_component}); // Added newline for better formatting
    //         try writer.print("\n\t</Component>", .{});
    //     }
    // }
}

pub fn Create(
    allocator: std.mem.Allocator,
    id: []const u8,
    ctype: ComponentType,
    x: i32,
    y: i32,
    width: u32,
    height: u32,
    padding: cl.Padding,
    fg_color: vaxis.Color,
    bg_color: vaxis.Color,
    border: BorderOptions,
    text: ?[]const u8,
) !*Component {
    const component = try allocator.create(Component);
    component.* = Component{
        .id = id,
        .ctype = ctype,
        .x = x,
        .y = y,
        .width = width,
        .height = height,
        .padding = padding,
        .fg_color = fg_color,
        .bg_color = bg_color,
        .border = border,
        .text = text,
        .children = null,
    };

    return component;
}

pub fn child(
    self: *Component,
    children: []const Component,
) void {
    self.children = @constCast(children);
}
