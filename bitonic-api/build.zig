const std = @import("std");

pub fn build(b: *std.Build) void {
    const ex_name = "bitonic-api";

    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const zap_dep = b.dependency("zap", .{});

    const exe_mod = b.addModule(ex_name, .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = ex_name,
        .root_module = exe_mod,
    });

    exe.root_module.addImport("zap", zap_dep.module("zap"));
    exe.linkSystemLibrary("c");

    b.installArtifact(exe);

    // Add test step
    const bitonic_tests = b.addTest(.{
        .root_source_file = b.path("src/bitonic_test.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_bitonic_tests = b.addRunArtifact(bitonic_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_bitonic_tests.step);
}
