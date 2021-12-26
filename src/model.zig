const std = @import("std");
const ArrayList = std.ArrayList;

pub const ShelfType = enum {
    top_result,
    song,
    video,
    artist,
    album,
    community_playlists,
    featured_playlists,

    pub fn from_str(str: []const u8) !ShelfType {
        std.log.warn("{s}", .{str});

        if (std.mem.eql(u8, str, "Top result")) {
            return .top_result;
        } else if (std.mem.eql(u8, str, "Songs")) {
            return .song;
        } else if (std.mem.eql(u8, str, "Videos")) {
            return .video;
        } else if (std.mem.eql(u8, str, "Artists")) {
            return .artist;
        } else if (std.mem.eql(u8, str, "Albums")) {
            return .album;
        } else if (std.mem.eql(u8, str, "Community playlists")) {
            return .community_playlists;
        } else if (std.mem.eql(u8, str, "Featured playlists")) {
            return .featured_playlists;
        }

        return error.InvalidType;
    }
};

pub const TopResult = union(enum) {
    song: Song,
    video: Video,
    artist,
    album,
    community_playlists,
    featured_playlists,
};

pub const Track = struct {
    title: []u8,
    artist_name: []u8,
    artist_id: []u8,
    id: []u8,
};

pub const Song = Track;
pub const Video = Track;

// Responses

pub const SearchResult = struct {
    top_result: TopResult = undefined,
    songs: ArrayList(Song),
    videos: ArrayList(Video),
    featured_playlists: u16 = 1,
    community_playlists: u16 = 1,
    albums: u16 = 1,
    artists: u16 = 1,

    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .songs = ArrayList(Song).init(allocator),
            .videos = ArrayList(Video).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: Self) void {
        for (self.songs.items) |song| {
            self.allocator.free(song.title);
            self.allocator.free(song.id);
            self.allocator.free(song.artist_name);
            self.allocator.free(song.artist_id);
        }

        for (self.videos.items) |video| {
            self.allocator.free(video.title);
            self.allocator.free(video.id);
            self.allocator.free(video.artist_name);
            self.allocator.free(video.artist_id);
        }

        self.songs.deinit();
        self.videos.deinit();
    }
};
