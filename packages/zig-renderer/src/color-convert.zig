const std = @import("std");
const math = std.math;

pub const Color = struct {
    pub const RGB = struct {
        r: u8,
        g: u8,
        b: u8,
    };

    pub const Lab = struct {
        l: f32, // Lightness (0 to 100)
        a: f32, // Green-Red component (-128 to 127)
        b: f32, // Blue-Yellow component (-128 to 127)
    };
};

/// Convert RGB (0-255) to L*a*b color space
pub fn rgbToLab(rgb: Color.RGB) Color.Lab {
    // First convert RGB to XYZ
    const xyz = rgbToXyz(rgb);

    // Then convert XYZ to Lab
    return xyzToLab(xyz);
}

/// Convert L*a*b to RGB (0-255)
pub fn labToRgb(lab: Color.Lab) Color.RGB {
    // First convert Lab to XYZ
    const xyz = labToXyz(lab);

    // Then convert XYZ to RGB
    return xyzToRgb(xyz);
}

// Internal XYZ color space representation
const XYZ = struct {
    x: f32,
    y: f32,
    z: f32,
};

// D65 illuminant reference white point
const D65_X: f32 = 95.047;
const D65_Y: f32 = 100.000;
const D65_Z: f32 = 108.883;

/// Convert RGB to XYZ color space
fn rgbToXyz(rgb: Color.RGB) XYZ {
    // Normalize RGB values to 0-1
    var r = @as(f32, @floatFromInt(rgb.r)) / 255.0;
    var g = @as(f32, @floatFromInt(rgb.g)) / 255.0;
    var b = @as(f32, @floatFromInt(rgb.b)) / 255.0;

    @setEvalBranchQuota(10000);
    // Apply gamma correction (sRGB)
    r = if (r > 0.04045) math.pow(f32, (r + 0.055) / 1.055, 2.4) else r / 12.92;
    g = if (g > 0.04045) math.pow(f32, (g + 0.055) / 1.055, 2.4) else g / 12.92;
    b = if (b > 0.04045) math.pow(f32, (b + 0.055) / 1.055, 2.4) else b / 12.92;

    // Scale to 0-100
    r *= 100.0;
    g *= 100.0;
    b *= 100.0;

    // Convert to XYZ using sRGB matrix
    const x = r * 0.4124564 + g * 0.3575761 + b * 0.1804375;
    const y = r * 0.2126729 + g * 0.7151522 + b * 0.0721750;
    const z = r * 0.0193339 + g * 0.1191920 + b * 0.9503041;

    return XYZ{ .x = x, .y = y, .z = z };
}

/// Convert XYZ to RGB color space
fn xyzToRgb(xyz: XYZ) Color.RGB {
    // Convert XYZ to linear RGB using inverse sRGB matrix
    var r = xyz.x * 3.2404542 + xyz.y * -1.5371385 + xyz.z * -0.4985314;
    var g = xyz.x * -0.9692660 + xyz.y * 1.8760108 + xyz.z * 0.0415560;
    var b = xyz.x * 0.0556434 + xyz.y * -0.2040259 + xyz.z * 1.0572252;

    // Scale from 0-100 to 0-1
    r /= 100.0;
    g /= 100.0;
    b /= 100.0;

    @setEvalBranchQuota(10000);

    // Apply inverse gamma correction (sRGB)
    r = if (r > 0.0031308) 1.055 * math.pow(f32, r, 1.0 / 2.4) - 0.055 else 12.92 * r;
    g = if (g > 0.0031308) 1.055 * math.pow(f32, g, 1.0 / 2.4) - 0.055 else 12.92 * g;
    b = if (b > 0.0031308) 1.055 * math.pow(f32, b, 1.0 / 2.4) - 0.055 else 12.92 * b;

    // Clamp and convert to 0-255
    const r_clamped = @as(u8, @intFromFloat(@max(0.0, @min(255.0, r * 255.0 + 0.5))));
    const g_clamped = @as(u8, @intFromFloat(@max(0.0, @min(255.0, g * 255.0 + 0.5))));
    const b_clamped = @as(u8, @intFromFloat(@max(0.0, @min(255.0, b * 255.0 + 0.5))));

    return Color.RGB{ .r = r_clamped, .g = g_clamped, .b = b_clamped };
}

/// Convert XYZ to L*a*b color space
fn xyzToLab(xyz: XYZ) Color.Lab {
    // Normalize by reference white point (D65)
    const xn = xyz.x / D65_X;
    const yn = xyz.y / D65_Y;
    const zn = xyz.z / D65_Z;

    // Apply Lab transformation function
    const fx = labF(xn);
    const fy = labF(yn);
    const fz = labF(zn);

    const l = 116.0 * fy - 16.0;
    const a = 500.0 * (fx - fy);
    const b = 200.0 * (fy - fz);

    return Color.Lab{ .l = l, .a = a, .b = b };
}

/// Convert L*a*b to XYZ color space
fn labToXyz(lab: Color.Lab) XYZ {
    const fy = (lab.l + 16.0) / 116.0;
    const fx = lab.a / 500.0 + fy;
    const fz = fy - lab.b / 200.0;

    const xn = labFInverse(fx);
    const yn = labFInverse(fy);
    const zn = labFInverse(fz);

    const x = xn * D65_X;
    const y = yn * D65_Y;
    const z = zn * D65_Z;

    return XYZ{ .x = x, .y = y, .z = z };
}

/// Lab transformation function f(t)
fn labF(t: f32) f32 {
    @setEvalBranchQuota(10000);
    const delta: f32 = 6.0 / 29.0;
    const delta_cubed = delta * delta * delta;

    return if (t > delta_cubed)
        math.pow(f32, t, 1.0 / 3.0)
    else
        t / (3.0 * delta * delta) + 4.0 / 29.0;
}

/// Inverse Lab transformation function f^(-1)(t)
fn labFInverse(t: f32) f32 {
    const delta: f32 = 6.0 / 29.0;

    return if (t > delta)
        t * t * t
    else
        3.0 * delta * delta * (t - 4.0 / 29.0);
}

/// Blend two colors in L*a*b color space
pub fn blendLab(color1: Color.Lab, color2: Color.Lab, ratio: f32) Color.Lab {
    const l_blended = color1.l + (color2.l - color1.l) * ratio;
    const a_blended = color1.a + (color2.a - color1.a) * ratio;
    const b_blended = color1.b + (color2.b - color1.b) * ratio;

    return Color.Lab{ .l = l_blended, .a = a_blended, .b = b_blended };
}

pub fn blends(allocator: std.mem.Allocator, color1: Color.RGB, color2: Color.RGB, steps: u8) []Color.RGB {
    const lab1 = rgbToLab(color1);
    const lab2 = rgbToLab(color2);

    const blended_colors: [steps]Color.RGB = std.ArrayList(Color.RGB).init(allocator);
    for (0..steps) |i| {
        const delta: f32 = 1.0 / @as(f32, @floatFromInt(steps + 1));
        // const ratio: f32 = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(steps - 1));
        const blended_lab = blendLab(
            lab1,
            lab2,
            delta * @as(f32, @floatFromInt(i)),
        );
        const blended_rgb = labToRgb(blended_lab);

        blended_colors[i] = blended_rgb;
    }

    return blended_colors;
}

test "RGB to Lab and back conversion" {
    const test_colors = [_]Color.RGB{
        Color.RGB{ .r = 255, .g = 0, .b = 0 }, // Red
        Color.RGB{ .r = 0, .g = 255, .b = 0 }, // Green
        Color.RGB{ .r = 0, .g = 0, .b = 255 }, // Blue
        Color.RGB{ .r = 255, .g = 255, .b = 255 }, // White
        Color.RGB{ .r = 0, .g = 0, .b = 0 }, // Black
        Color.RGB{ .r = 128, .g = 128, .b = 128 }, // Gray
    };

    for (test_colors) |original_rgb| {
        const lab = rgbToLab(original_rgb);
        const converted_rgb = labToRgb(lab);

        std.debug.print("Original RGB: ({}, {}, {}) -> Lab: ({d:.2}, {d:.2}, {d:.2}) -> RGB: ({}, {}, {})\n", .{ original_rgb.r, original_rgb.g, original_rgb.b, lab.l, lab.a, lab.b, converted_rgb.r, converted_rgb.g, converted_rgb.b });

        // Allow for small rounding errors in conversion
        try std.testing.expect(@abs(@as(i16, converted_rgb.r) - @as(i16, original_rgb.r)) <= 1);
        try std.testing.expect(@abs(@as(i16, converted_rgb.g) - @as(i16, original_rgb.g)) <= 1);
        try std.testing.expect(@abs(@as(i16, converted_rgb.b) - @as(i16, original_rgb.b)) <= 1);
    }
}

test "Lab blending" {
    const red_rgb = Color.RGB{ .r = 255, .g = 0, .b = 0 };
    const blue_rgb = Color.RGB{ .r = 0, .g = 0, .b = 255 };

    const red_lab = rgbToLab(red_rgb);
    const blue_lab = rgbToLab(blue_rgb);

    const blended_lab = blendLab(red_lab, blue_lab, 0.5);
    const blended_rgb = labToRgb(blended_lab);

    std.debug.print("Red Lab: ({d:.2}, {d:.2}, {d:.2})\n", .{ red_lab.l, red_lab.a, red_lab.b });
    std.debug.print("Blue Lab: ({d:.2}, {d:.2}, {d:.2})\n", .{ blue_lab.l, blue_lab.a, blue_lab.b });
    std.debug.print("Blended Lab: ({d:.2}, {d:.2}, {d:.2})\n", .{ blended_lab.l, blended_lab.a, blended_lab.b });
    std.debug.print("Blended RGB: ({}, {}, {})\n", .{ blended_rgb.r, blended_rgb.g, blended_rgb.b });
}
