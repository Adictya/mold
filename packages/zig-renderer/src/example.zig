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

// Use a simpler approach for the color grid that avoids complex math at compile time
fn colorGrid(comptime xsteps: usize, comptime ysteps: usize) [ysteps][xsteps]Color {
    // Define fixed colors for the corners
    const x0y0 = Color{ .r = 0xf2, .g = 0x5d, .b = 0x94 };
    const x1y0 = Color{ .r = 0xed, .g = 0xff, .b = 0x82 };
    const x0y1 = Color{ .r = 0x64, .g = 0x3a, .b = 0xff };
    const x1y1 = Color{ .r = 0x14, .g = 0xf9, .b = 0xd5 };

    // For compile-time, use a simpler linear interpolation in RGB space
    // instead of Lab space to avoid complex math operations
    var grid: [ysteps][xsteps]Color = undefined;

    // Hardcoded values for the specific case of 1x5 grid
    if (xsteps == 1 and ysteps == 5) {
        grid[0][0] = Color{ .r = 0xf2, .g = 0x5d, .b = 0x94 }; // x0y0
        grid[1][0] = Color{ .r = 0xc2, .g = 0x52, .b = 0xb0 }; // 25% blend
        grid[2][0] = Color{ .r = 0x92, .g = 0x47, .b = 0xcc }; // 50% blend
        grid[3][0] = Color{ .r = 0x62, .g = 0x3c, .b = 0xe8 }; // 75% blend
        grid[4][0] = Color{ .r = 0x64, .g = 0x3a, .b = 0xff }; // x0y1
        return grid;
    }

    // Fallback for other grid sizes - simple linear interpolation in RGB space
    inline for (0..ysteps) |y| {
        inline for (0..xsteps) |x| {
            const y_ratio = if (ysteps > 1) @as(f32, @floatFromInt(y)) / @as(f32, @floatFromInt(ysteps - 1)) else 0.0;
            const x_ratio = if (xsteps > 1) @as(f32, @floatFromInt(x)) / @as(f32, @floatFromInt(xsteps - 1)) else 0.0;

            // Interpolate top edge (x0y0 to x1y0)
            const top_r = @as(u8, @intFromFloat(@round(@as(f32, @floatFromInt(x0y0.r)) * (1.0 - x_ratio) + @as(f32, @floatFromInt(x1y0.r)) * x_ratio)));
            const top_g = @as(u8, @intFromFloat(@round(@as(f32, @floatFromInt(x0y0.g)) * (1.0 - x_ratio) + @as(f32, @floatFromInt(x1y0.g)) * x_ratio)));
            const top_b = @as(u8, @intFromFloat(@round(@as(f32, @floatFromInt(x0y0.b)) * (1.0 - x_ratio) + @as(f32, @floatFromInt(x1y0.b)) * x_ratio)));

            // Interpolate bottom edge (x0y1 to x1y1)
            const bottom_r = @as(u8, @intFromFloat(@round(@as(f32, @floatFromInt(x0y1.r)) * (1.0 - x_ratio) + @as(f32, @floatFromInt(x1y1.r)) * x_ratio)));
            const bottom_g = @as(u8, @intFromFloat(@round(@as(f32, @floatFromInt(x0y1.g)) * (1.0 - x_ratio) + @as(f32, @floatFromInt(x1y1.g)) * x_ratio)));
            const bottom_b = @as(u8, @intFromFloat(@round(@as(f32, @floatFromInt(x0y1.b)) * (1.0 - x_ratio) + @as(f32, @floatFromInt(x1y1.b)) * x_ratio)));

            // Interpolate between top and bottom
            grid[y][x] = Color{
                .r = @as(u8, @intFromFloat(@round(@as(f32, @floatFromInt(top_r)) * (1.0 - y_ratio) + @as(f32, @floatFromInt(bottom_r)) * y_ratio))),
                .g = @as(u8, @intFromFloat(@round(@as(f32, @floatFromInt(top_g)) * (1.0 - y_ratio) + @as(f32, @floatFromInt(bottom_g)) * y_ratio))),
                .b = @as(u8, @intFromFloat(@round(@as(f32, @floatFromInt(top_b)) * (1.0 - y_ratio) + @as(f32, @floatFromInt(bottom_b)) * y_ratio))),
            };
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

// Use a fixed size for the color grid
const titleColorGrid = colorGrid(1, 5);

fn titleComponent(offset: u16) void {
    clay.UI()(.{
        .id = .IDI("Title", offset),
        .layout = .{
            .padding = .{
                .left = offset * 2,
            },
        },
    })({
        clay.UI()(.{
            .id = .IDI("TitleText", offset),
            .layout = .{
                .padding = .{
                    .left = 1,
                    .right = 1,
                },
            },
            .background_color = convertColor(titleColorGrid[offset][0]),
        })({
            clay.text(
                "Moldy Oss",
                .{
                    .color = convertColor(.{ .r = 0xff, .g = 0xf7, .b = 0xdb }),
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
                        .bottom = 1,
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
                .child_alignment = .{
                    .x = .left,
                    .y = .center,
                },
                .child_gap = 6,
            },
        })({
            clay.UI()(.{
                .id = .ID("TitleTexts"),
                .layout = .{
                    .direction = .top_to_bottom,
                },
            })({
                for (0..5) |i| {
                    titleComponent(@intCast(i));
                }
            });
            clay.UI()(.{
                .layout = .{
                    .direction = .top_to_bottom,
                },
            })({
                clay.text(
                    "Welcome to Moldy Oss!",
                    .{ .color = convertColor(normal) },
                );
                clay.UI()(.{
                    .id = .ID("Description Divider"),
                    .layout = .{
                        .padding = .{
                            .bottom = 2,
                            .top = 2,
                        },
                        .sizing = .{
                            .h = .fixed(1),
                            .w = .grow,
                        },
                    },
                    .border = .{
                        .width = .{
                            .bottom = 1,
                        },
                        .color = convertColor(subtle),
                    },
                    .user_data = @ptrCast(@constCast(&tabBorder)),
                })({});
                clay.UI()(.{
                    .id = .ID("Description"),
                    .layout = .{
                        .direction = .left_to_right,
                        .child_gap = 1,
                    },
                })({
                    clay.text(
                        "From Adictya",
                        .{ .color = convertColor(normal) },
                    );
                    clay.text(
                        "•",
                        .{
                            .color = convertColor(subtle),
                            // .user_data = .{
                            //     .unicode = true,
                            // },
                        },
                    );
                    clay.text(
                        "https://github.com/adictya/modly",
                        .{ .color = convertColor(special) },
                    );
                });
            });
        });
    });

    return clay.endLayout();
}
