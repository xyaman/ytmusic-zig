const std = @import("std");
const zfetch = @import("zfetch");

const lib = @import("main.zig");
const model = lib.model;
const parser = lib.parser;

pub const Client = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    headers: zfetch.Headers,

    pub fn init(allocator: std.mem.Allocator) !Client {
        var headers = zfetch.Headers.init(allocator);
        try headers.appendValue("accept", "*/*");
        try headers.appendValue("content-type", "application/json");
        try headers.appendValue("user-agent", "Mozilla/5.0 (X11; Linux x86_64; rv:94.0) Gecko/20100101 Firefox/94.0");
        try headers.appendValue("origin", "https://music.youtube.com");

        return Client{
            .allocator = allocator,
            .headers = headers,
        };
    }

    pub fn deinit(self: *Self) void {
        self.headers.deinit();
    }

    fn makeRequest(self: *Self, key: []const u8, value: []const u8) ![]u8 {
        var req = try zfetch.Request.init(self.allocator, "https://music.youtube.com/youtubei/v1/search?key=AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30", null);
        defer req.deinit();

        const body_fmt =
            \\ {{
            \\   {s}: "{s}",
            \\   context: {{
            \\     client: {{
            \\         clientName: "WEB_REMIX",
            \\         clientVersion: "1.20211122.00.00"
            \\     }},
            \\     user: {{}}
            \\  }}
            \\ }}
        ;

        var body = try std.fmt.allocPrint(self.allocator, body_fmt, .{ key, value });
        defer self.allocator.free(body);

        try req.do(.POST, self.headers, body);

        // try stdout.print("status: {d} {s}\n", .{ req.status.code, req.status.reason });
        const reader = req.reader();

        // read all (maybe in the future zjson will supports passing a reader)
        const body_content = try reader.readAllAlloc(self.allocator, std.math.maxInt(usize));
        return body_content;
    }

    pub fn search(self: *Self, query: []const u8) !model.SearchResult {
        var res_body = try self.makeRequest("query", query);
        defer self.allocator.free(res_body);

        const result = try parser.parseSearch(res_body, self.allocator);
        return result;
    }
};

test "basic add functionality" {
    std.testing.refAllDecls(@This());

    var client = try Client.init(std.testing.allocator);
    defer client.deinit();

    const response = try client.search("yaosobi");
    for (response.songs.items) |video| {
        std.log.warn("{s}", .{video.title});
    }
    defer response.deinit();
}
