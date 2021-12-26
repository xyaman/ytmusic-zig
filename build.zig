const std = @import("std");
const deps = @import("deps.zig");

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const lib = b.addStaticLibrary("ytmusic-zig", "src/main.zig");
    lib.setBuildMode(mode);
    deps.pkgs.addAllTo(lib);
    lib.install();

    const main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);
    deps.pkgs.addAllTo(main_tests);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}
