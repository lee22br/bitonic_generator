const std = @import("std");

pub fn build(b: *std.Build) void {
    const ex_name = "bitonic-api";

    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const zap_dep = b.dependency("zap", .{});
    const okredis_dep = b.dependency("okredis", .{});

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
    exe.root_module.addImport("okredis", okredis_dep.module("okredis"));
    exe.linkSystemLibrary("c");

    b.installArtifact(exe);

    // Add test step
    const test_module = b.createModule(.{
        .root_source_file = b.path("src/bitonic_test.zig"),
        .target = target,
        .optimize = optimize,
    });
    test_module.addImport("okredis", okredis_dep.module("okredis"));

    const bitonic_tests = b.addTest(.{
        .name = "bitonic-tests",
        .root_module = test_module,

    });

    const run_bitonic_tests = b.addRunArtifact(bitonic_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_bitonic_tests.step);
}

