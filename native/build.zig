const std = @import("std");
const napigen = @import("napigen");

const Build_exe = false;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const vaxis = b.dependency("vaxis", .{
        .target = target,
        .optimize = optimize,
    });
    lib_mod.addImport("vaxis", vaxis.module("vaxis"));

    const zclay = b.dependency("zclay", .{
        .target = target,
        .optimize = optimize,
    });
    lib_mod.addImport("zclay", zclay.module("zclay"));

    const lib = b.addSharedLibrary(.{
        .name = "mold_native_lib",
        .root_module = lib_mod,
    });

    napigen.setup(lib);

    b.installArtifact(lib);

    const copy_node_step = b.addInstallLibFile(lib.getEmittedBin(), "../../../packages/core/native/mold_native.node");

    b.getInstallStep().dependOn(&copy_node_step.step);

    const lib_unit_tests = b.addTest(.{
        .root_module = lib_mod,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
