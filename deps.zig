const std = @import("std");
pub const pkgs = struct {
    pub const zfetch = std.build.Pkg{
        .name = "zfetch",
        .path = .{ .path = "deps/zfetch/src/main.zig" },
        .dependencies = &[_]std.build.Pkg{
            std.build.Pkg{
                .name = "hzzp",
                .path = .{ .path = "deps/hzzp/src/main.zig" },
            },
            std.build.Pkg{
                .name = "iguanaTLS",
                .path = .{ .path = "deps/iguanaTLS/src/main.zig" },
            },
            std.build.Pkg{
                .name = "network",
                .path = .{ .path = "deps/zig-network/network.zig" },
            },
            std.build.Pkg{
                .name = "uri",
                .path = .{ .path = "deps/zig-uri/uri.zig" },
            },
        },
    };

    pub const zjson = std.build.Pkg{
        .name = "zjson",
        .path = .{ .path = "deps/zjson/src/lib.zig" },
    };

    pub fn addAllTo(artifact: *std.build.LibExeObjStep) void {
        @setEvalBranchQuota(1_000_000);
        inline for (std.meta.declarations(pkgs)) |decl| {
            if (decl.is_pub and decl.data == .Var) {
                artifact.addPackage(@field(pkgs, decl.name));
            }
        }
    }
};

pub const exports = struct {
    pub const ytmusic = std.build.Pkg{
        .name = "ytmusic",
        .path = .{ .path = "src/main.zig" },
        .dependencies = &.{
            pkgs.zfetch,
        },
    };
};
pub const base_dirs = struct {
    pub const wz = "lib/wz";
};
