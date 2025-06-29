const clay = @import("zclay");
const std = @import("std");
const renderer = @import("termrender.zig");

const light_grey: clay.Color = .{ 224, 215, 210, 255 };
const red: clay.Color = .{ 168, 66, 28, 255 };
const orange: clay.Color = .{ 225, 138, 50, 255 };
const white: clay.Color = .{ 250, 250, 255, 255 };

const sidebar_item_layout: clay.LayoutConfig = .{ .sizing = .{ .w = .grow, .h = .fixed(50) } };

// Re-useable components are just normal functions
fn sidebarItemComponent(index: u32) void {
    clay.UI()(.{
        .id = .IDI("SidebarBlob", index),
        .layout = sidebar_item_layout,
        .background_color = orange,
    })({});
}

fn createLayout() []clay.RenderCommand {
    clay.beginLayout();
    clay.UI()(.{
        .id = .ID("OuterContainer"),
        .layout = .{ .direction = .left_to_right, .sizing = .grow, .padding = .all(16), .child_gap = 16 },
        .background_color = white,
    })({
        clay.UI()(.{
            .id = .ID("SideBar"),
            .layout = .{
                .direction = .top_to_bottom,
                .sizing = .{ .h = .grow, .w = .fixed(300) },
                .padding = .all(16),
                .child_alignment = .{ .x = .center, .y = .top },
                .child_gap = 16,
            },
            .background_color = light_grey,
        })({
            clay.UI()(.{
                .id = .ID("ProfilePictureOuter"),
                .layout = .{
                    .sizing = .{ .w = .grow },
                    .padding = .all(16),
                    .child_alignment = .{ .x = .center, .y = .center },
                    .child_gap = 16,
                },
                .background_color = red,
            })({
                clay.text("Clay - UI Library", .{ .font_size = 1, .color = light_grey });
            });

            for (0..5) |i| sidebarItemComponent(@intCast(i));
        });

        clay.UI()(.{
            .id = .ID("MainContent"),
            .layout = .{ .sizing = .grow },
            .background_color = light_grey,
        })({
            //...
        });
    });
    return clay.endLayout();
}

// An example function to begin the "root" of your layout tree
fn createSimpleLayout() []clay.RenderCommand {
    clay.beginLayout();
    clay.UI()(.{
        .id = .ID("OuterContainer"),
        .layout = .{
            .direction = .top_to_bottom,
            .sizing = .{ .h = .fixed(20), .w = .fixed(100) },
            .padding = .all(16),
            .child_gap = 16,
        },
        .background_color = white,
    })({
        clay.text("Clay - UI Library", .{ .font_size = 24, .color = light_grey });
    });
    return clay.endLayout();
}

pub fn init() !void {
    const allocator = std.heap.page_allocator;

    const min_memory_size: u32 = clay.minMemorySize();
    const memory = try allocator.alloc(u8, min_memory_size);
    defer allocator.free(memory);
    const arena: clay.Arena = clay.createArenaWithCapacityAndMemory(memory);
    _ = clay.initialize(arena, .{ .h = 100, .w = 100 }, .{});
    clay.setMeasureTextFunction(void, {}, renderer.consoleMeasureText);
    renderer.clayTerminalRender(createSimpleLayout(), 100, 100) catch unreachable;
}
