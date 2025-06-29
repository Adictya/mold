const renderer = @import("termrender.zig");
const clay = @import("zclay");
const std = @import("std");
const colorSpaceUtils = @import("color-convert.zig");

pub const Color = colorSpaceUtils.Color.RGB;

fn convertColor(color: Color) clay.Color {
    return clay.Color{
        @floatFromInt(color.r),
        @floatFromInt(color.g),
        @floatFromInt(color.b),
        255,
    };
}

fn colorGrid(xsteps: usize, ysteps: usize) [ysteps][xsteps]Color {
    const x0y0 = Color{ .r = 0xf2, .g = 0x5d, .b = 0x94 };
    const x1y0 = Color{ .r = 0xed, .g = 0xff, .b = 0x82 };
    const x0y1 = Color{ .r = 0x64, .g = 0x3a, .b = 0xff };
    const x1y1 = Color{ .r = 0x14, .g = 0xf9, .b = 0xd5 };

    var x0: [ysteps]Color = undefined;
    for (0..ysteps) |i| {
        x0[i] = colorSpaceUtils.labToRgb(
            colorSpaceUtils.blendLab(
                colorSpaceUtils.rgbToLab(x0y0),
                colorSpaceUtils.rgbToLab(x0y1),
                @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(ysteps - 1)),
            ),
        );
    }

    var x1: [ysteps]Color = undefined;
    for (0..ysteps) |i| {
        x1[i] = colorSpaceUtils.labToRgb(
            colorSpaceUtils.blendLab(
                colorSpaceUtils.rgbToLab(x1y0),
                colorSpaceUtils.rgbToLab(x1y1),
                @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(ysteps - 1)),
            ),
        );
    }

    var grid: [ysteps][xsteps]Color = undefined;
    for (0..ysteps) |x| {
        const y0 = x0[x];
        for (0..xsteps) |y| {
            grid[x][y] = colorSpaceUtils.labToRgb(
                colorSpaceUtils.blendLab(
                    y0,
                    x1[x],
                    @as(f32, @floatFromInt(y)) / @as(f32, @floatFromInt(xsteps - 1)),
                ),
            );
        }
    }

    return grid;
}

const normal = Color{ .r = 0xee, .g = 0xee, .b = 0xee };
const subtle = Color{ .r = 0x38, .g = 0x38, .b = 0x38 };
const highlight = Color{ .r = 0x7d, .g = 0x56, .b = 0xf4 };
const special = Color{ .r = 0x73, .g = 0xf5, .b = 0x9f };
const blends = colorSpaceUtils.blends(
    std.heap.page_allocator,
    Color{
        .r = 0xf2,
        .g = 0x5d,
        .b = 0x94,
    },
    Color{ .r = 0xed, .g = 0xff, .b = 0x82 },
    50,
);

const activeTabBorder = renderer.BorderCharacters{
    .top = '─',
    .bottom = ' ',
    .left = '│',
    .right = '│',
    .top_left = '╭',
    .top_right = '╮',
    .bottom_left = '┘',
    .bottom_right = '└',
};

const tabBorder = renderer.BorderCharacters{
    .top = '─',
    .bottom = '─',
    .left = '│',
    .right = '│',
    .top_left = '╭',
    .top_right = '╮',
    .bottom_left = '┴',
    .bottom_right = '┴',
};

const tab = clay.ElementDeclaration{
    .border = .{
        .width = .all(1),
        .color = convertColor(highlight),
    },
    .layout = .{
        .padding = .{
            .top = 1,
            .bottom = 1,
            .left = 2,
            .right = 2,
        },
    },
};

fn tabComponent(index: u32, text: []const u8) void {
    clay.UI()(.{
        .id = .IDI("Tab", index),
        .border = tab.border,
        .layout = tab.layout,
        .user_data = @ptrCast(@constCast(&tabBorder)),
    })({
        clay.text(text, .{ .color = convertColor(normal) });
    });
}

const titleColorGrid = colorGrid(1, 5);

fn titleComponent(offset: u16) void {
    clay.UI()(.{
        .id = .IDI("Title", offset),
        .layout = .{
            .padding = .{
                .left = offset,
            },
        },
    })({
        clay.UI()(.{
            .id = .IDI("TitleText", offset),
            .layout = .{
                .padding = .{
                    .left = 2,
                    .right = 2,
                },
            },
            .background_color = convertColor(titleColorGrid[offset][0]),
        })({
            clay.text(
                "Mold Oss",
                .{
                    .color = convertColor(normal),
                },
            );
        });
    });
}

pub fn funLayout() []clay.RenderCommand {
    clay.beginLayout();

    clay.UI()(.{
        .id = .ID("MainContainer"),
        .layout = .{
            .direction = .top_to_bottom,
            .sizing = .{
                .h = .grow,
                .w = .fixed(96),
            },
            .child_gap = 1,
        },
    })({
        clay.UI()(.{
            .id = .ID("Header"),
            .layout = .{
                .direction = .left_to_right,
                .sizing = .{
                    .w = .grow,
                },
                .child_alignment = .{
                    .x = .left,
                    .y = .bottom,
                },
            },
        })({
            clay.UI()(.{
                .id = .ID("ActiveTab"),
                .border = tab.border,
                .layout = tab.layout,
                .user_data = @ptrCast(@constCast(&activeTabBorder)),
            })({
                clay.text("Lip Gloss", .{ .color = convertColor(normal) });
            });
            tabComponent(0, "Blush");
            tabComponent(1, "Eye Shadow");
            tabComponent(2, "Mascara");
            tabComponent(3, "Foundation");
            clay.UI()(.{
                .id = .ID("Gap"),
                .layout = .{
                    .sizing = .{
                        .h = .fixed(1),
                        .w = .grow,
                    },
                },
                .border = .{
                    .width = .{
                        .top = 0,
                        .bottom = 1,
                        .left = 0,
                        .right = 0,
                    },
                    .color = convertColor(highlight),
                },
                .user_data = @ptrCast(@constCast(&tabBorder)),
            })({});
        });
        clay.UI()(.{
            .id = .ID("Title"),
            .layout = .{
                .sizing = .{
                    .w = .grow,
                },
            },
        })({
            clay.UI()(.{
                .id = .ID("TitleTexts"),
            })({});

            for (0..5) |i| {
                titleComponent(@intCast(i));
            }
        });
    });

    return clay.endLayout();
}
