const std = @import("std");
const zjson = @import("zjson");

const lib = @import("main.zig");
const model = lib.model;

pub fn parseSearch(input: []const u8, allocator: std.mem.Allocator) !model.SearchResult {
    const shelves = try zjson.get(input, .{ "contents", "tabbedSearchResultsRenderer", "tabs", 0, "tabRenderer", "content", "sectionListRenderer", "contents" });

    var search_result = model.SearchResult.init(allocator);
    errdefer search_result.deinit();

    var shelves_iter = try zjson.ArrayIterator.init(shelves);
    while (try shelves_iter.next()) |shelf| {

        // sometimes key is not found, and its because search query can be misspelled
        // so first shelf is the common: did you mean ...? so its safe to skip
        const shelf_name = zjson.get(shelf.bytes, .{ "musicShelfRenderer", "title", "runs", 0, "text" }) catch continue;
        const shelf_type = try model.ShelfType.from_str(shelf_name.bytes);

        const shelf_items = try zjson.get(shelf.bytes, .{ "musicShelfRenderer", "contents" });
        var items = try zjson.ArrayIterator.init(shelf_items);
        while (try items.next()) |item| {
            switch (shelf_type) {
                .top_result => {},
                .song => {
                    const song = try parseSong(allocator, item.bytes);
                    try search_result.songs.append(song);
                },
                .video => {
                    const video = try parseVideo(allocator, item.bytes);
                    try search_result.videos.append(video);
                },
                .artist => {
                    const artist = try parseArtist(allocator, item.bytes);
                    try search_result.artists.append(artist);
                },
                else => {},
            }
        }
    }

    return search_result;
}

pub fn parseSong(allocator: std.mem.Allocator, input: []const u8) !model.Song {

    // Runs 0 contains Song info
    // text: Song title
    // endpoint: Song ID
    const item_flex0 = try zjson.get(input, .{ "musicResponsiveListItemRenderer", "flexColumns", 0, "musicResponsiveListItemFlexColumnRenderer" });
    const runs0 = try zjson.get(item_flex0.bytes, .{ "text", "runs", 0 });
    const runs0_text = try zjson.get(runs0.bytes, .{"text"});
    const runs0_endpoint = try zjson.get(runs0.bytes, .{ "navigationEndpoint", "watchEndpoint", "videoId" });

    // Runs 1 contains artist related info
    // text: artist name
    // endpoint: artist ID
    const item_flex1 = try zjson.get(input, .{ "musicResponsiveListItemRenderer", "flexColumns", 1, "musicResponsiveListItemFlexColumnRenderer" });
    const runs1 = try zjson.get(item_flex1.bytes, .{ "text", "runs", 2 });
    const runs1_text = try zjson.get(runs1.bytes, .{"text"});
    const runs1_endpoint = try zjson.get(runs1.bytes, .{ "navigationEndpoint", "browseEndpoint", "browseId" });

    // Runs 4 contains album related info
    // text: album name
    // endpoint: album ID
    const runs4 = try zjson.get(item_flex1.bytes, .{ "text", "runs", 4 });
    const runs4_text = try zjson.get(runs4.bytes, .{"text"});
    const runs4_endpoint = try zjson.get(runs4.bytes, .{ "navigationEndpoint", "browseEndpoint", "browseId" });

    return model.Song{
        .title = try std.fmt.allocPrint(allocator, "{s}", .{runs0_text.bytes}),
        .id = try std.fmt.allocPrint(allocator, "{s}", .{runs0_endpoint.bytes}),
        .artist_name = try std.fmt.allocPrint(allocator, "{s}", .{runs1_text.bytes}),
        .artist_id = try std.fmt.allocPrint(allocator, "{s}", .{runs1_endpoint.bytes}),
        .album_name = try std.fmt.allocPrint(allocator, "{s}", .{runs4_text.bytes}),
        .album_id = try std.fmt.allocPrint(allocator, "{s}", .{runs4_endpoint.bytes}),
    };
}

pub fn parseVideo(allocator: std.mem.Allocator, input: []const u8) !model.Video {

    // Runs 0 contains Song info
    // text: Song title
    // endpoint: Song ID
    const item_flex0 = try zjson.get(input, .{ "musicResponsiveListItemRenderer", "flexColumns", 0, "musicResponsiveListItemFlexColumnRenderer" });
    const runs0 = try zjson.get(item_flex0.bytes, .{ "text", "runs", 0 });
    const runs0_text = try zjson.get(runs0.bytes, .{"text"});
    const runs0_endpoint = try zjson.get(runs0.bytes, .{ "navigationEndpoint", "watchEndpoint", "videoId" });

    // Runs 1 contains artist related info
    // text: artist name
    // endpoint: artist ID
    const item_flex1 = try zjson.get(input, .{ "musicResponsiveListItemRenderer", "flexColumns", 1, "musicResponsiveListItemFlexColumnRenderer" });
    const runs1 = try zjson.get(item_flex1.bytes, .{ "text", "runs", 2 });
    const runs1_text = try zjson.get(runs1.bytes, .{"text"});
    const runs1_endpoint = try zjson.get(runs1.bytes, .{ "navigationEndpoint", "browseEndpoint", "browseId" });

    return model.Video{
        .title = try std.fmt.allocPrint(allocator, "{s}", .{runs0_text.bytes}),
        .id = try std.fmt.allocPrint(allocator, "{s}", .{runs0_endpoint.bytes}),
        .artist_name = try std.fmt.allocPrint(allocator, "{s}", .{runs1_text.bytes}),
        .artist_id = try std.fmt.allocPrint(allocator, "{s}", .{runs1_endpoint.bytes}),
    };
}

pub fn parseArtist(allocator: std.mem.Allocator, input: []const u8) !model.Artist {

    // Artist
    // text: Artist name
    // endpoint: null
    const item_flex0 = try zjson.get(input, .{ "musicResponsiveListItemRenderer", "flexColumns", 0, "musicResponsiveListItemFlexColumnRenderer" });
    const runs0 = try zjson.get(item_flex0.bytes, .{ "text", "runs", 0 });
    const runs0_text = try zjson.get(runs0.bytes, .{"text"});

    const endpoint = try zjson.get(input, .{ "musicResponsiveListItemRenderer", "navigationEndpoint", "browseEndpoint", "browseId" });

    // Subscribers
    //const item_flex1 = try zjson.get(input, .{ "musicResponsiveListItemRenderer", "flexColumns", 1, "musicResponsiveListItemFlexColumnRenderer" });
    //const runs1 = try zjson.get(item_flex1.bytes, .{ "text", "runs", 2 });
    //const runs1_text = try zjson.get(runs1.bytes, .{"text"});

    return model.Artist{
        .name = try std.fmt.allocPrint(allocator, "{s}", .{runs0_text.bytes}),
        .id = try std.fmt.allocPrint(allocator, "{s}", .{endpoint.bytes}),
    };
}
