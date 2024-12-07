const builtin = @import("builtin");
const std = @import("std");

const io = std.io;
const fmt = std.fmt;

const eql = std.mem.eql;
const ArrayList = std.ArrayList;
const alloc = std.heap.page_allocator;

// read in an integer
pub fn readint(delim: u8) !i64 {
    const stdin = std.io.getStdIn().reader();

    const bare_line = stdin.readUntilDelimiterAlloc(alloc, delim, 8192) catch unreachable; // Allocates and reads into stdin (max 8192 bytes)
    defer std.heap.page_allocator.free(bare_line); // Prepares the data for freeing
    const line = std.mem.trim(u8, bare_line, "\r\n"); // Trim some unnecessary data from it

    const N: i64 = fmt.parseInt(i64, line, 10) catch unreachable; // parse to int
    return N;
}

// read in a string
pub fn readstr(delim: u8) ![]const u8 {
    const stdin = std.io.getStdIn().reader();
    // const stdout = std.io.getStdOut().writer();

    const bare_line = stdin.readUntilDelimiterAlloc(alloc, delim, 8192) catch unreachable; // Allocates and reads into stdin (max 8192 bytes)
    errdefer std.heap.page_allocator.free(bare_line); // Prepares the data for freeing
    const line = std.mem.trim(u8, bare_line, "\r\n"); // Trim some unnecessary data from it

    return line;
}

// read and split a line
pub fn splitline(delim: []const u8) !ArrayList([]const u8) {
    // const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    const bare_line = stdin.readUntilDelimiterAlloc(alloc, '\n', 8192) catch unreachable; // Allocates and reads into stdin (max 8192 bytes)
    errdefer std.heap.page_allocator.free(bare_line); // Prepares the data for freeing
    const line = std.mem.trim(u8, bare_line, "\r\n"); // Trim some unnecessary data from it

    var res = ArrayList([]const u8).init(alloc);

    var it = std.mem.split(u8, line, delim);
    while (it.next()) |x| {
        try res.append(x);
    }
    return res;
}

// read and split a line into integers
pub fn splitlineint(delim: []const u8) !ArrayList(i64) {
    // const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    const bare_line = stdin.readUntilDelimiterAlloc(alloc, '\n', 8192) catch unreachable; // Allocates and reads into stdin (max 8192 bytes)
    defer std.heap.page_allocator.free(bare_line); // Prepares the data for freeing
    const line = std.mem.trim(u8, bare_line, "\r\n"); // Trim some unnecessary data from it

    var res = ArrayList(i64).init(alloc);
    errdefer res.deinit(); // prevent mem leask in error
    // err defer things?

    var it = std.mem.split(u8, line, delim);
    while (it.next()) |x| {
        const integer = fmt.parseInt(i64, x, 10) catch unreachable;
        try res.append(integer);
    }
    return res;
}

// Compare 2 strings
pub fn strcmp(thing: []const u8, sus: []const u8) !bool {
    var i: usize = 0;
    if (thing.len != sus.len) {
        return false;
    }
    while (true) {
        if (i >= thing.len or i >= sus.len) {
            return true;
        }
        if (thing[i] != sus[i]) {
            return false;
        }

        i = i + 1;
    }
}

// Convert a string ([]const u8) into an ArrayList(u8)
pub fn strtolist(s: []const u8) !ArrayList(u8) {
    var res = ArrayList(u8).init(alloc);
    for (0..s.len) |i| {
        try res.append(s[i]);
    }
    return res;
}

// Setup an ArrayList(T) of size N containing the value V
pub fn memset(comptime T: type, N: usize, V: T) !ArrayList(T) {
    var res = ArrayList(T).init(alloc);

    for (0..N) |_| try res.append(V);
    return res;
}

// Setup an 2d ArrayList(T) of size (N, M) containing the value V
pub fn memset2(comptime T: type, N: usize, M: usize, V: T) !ArrayList(ArrayList(T)) {
    var res = ArrayList(ArrayList(T)).init(alloc);

    for (0..N) |_| {
        var line = ArrayList(T).init(alloc);
        for (0..M) |_| try line.append(V);
        try res.append(line);
    }
    return res;
}

pub fn search(grid: ArrayList(ArrayList(u8))) !i64 {
    // const stdout = std.io.getStdOut().writer();

    const N = grid.items.len;
    const M = grid.items[0].items.len;
    var vis = try memset2(i8, N, M, 0);
    defer vis.deinit();

    // try stdout.print("{} {}\n", .{ N, M });

    var x: i64 = 0;
    var y: i64 = 0;

    for (0..N) |i| {
        for (0..M) |j| {
            if (grid.items[i].items[j] == '^') {
                x = @intCast(i);
                y = @intCast(j);
            }
        }
    }

    // try stdout.print("START {} {}\n", .{ x, y });

    const dx = [4]i64{ -1, 0, 1, 0 };
    const dy = [4]i64{ 0, 1, 0, -1 };

    var d: usize = 0;

    while (true) {
        if (x < 0 or y < 0 or x >= N or y >= M) break;
        // HAHAAHAhAhAhAhAhAH RUNTIME SAFETY SO HYPE SO EFFICIENT SO CLEAN TOTALLY NOT OVERDONE HERE HURURR DURRR
        const xx: usize = @intCast(x);
        const yy: usize = @intCast(y);
        const fucker: u3 = @intCast(d); // ???????????????????????????????

        // check for loops

        if (vis.items[xx].items[yy] & (@as(i8, 1) << fucker) != 0) return -1;

        vis.items[xx].items[yy] |= (@as(i8, 1) << fucker);

        const xp = x + dx[d];
        const yp = y + dy[d];

        if (xp >= 0 and yp >= 0 and xp < N and yp < M) {
            // HAHAAHAhAhAhAhAhAH RUNTIME SAFETY SO HYPE SO EFFICIENT SO CLEAN TOTALLY NOT OVERDONE HERE HURURR DURRR
            const xpp: usize = @intCast(xp);
            const ypp: usize = @intCast(yp);
            if (grid.items[xpp].items[ypp] == '#') {
                d = (d + 1) % 4;
                continue;
            }
        }
        x = xp;
        y = yp;
    }

    var res: i64 = 0;
    for (0..N) |i| {
        for (0..M) |j| {
            if (vis.items[i].items[j] > 0) res += 1;
        }
    }

    return res;
}

pub fn main() !void { // Please remove the space between the ordering and the inputs
    const stdout = std.io.getStdOut().writer();

    const N = 130;

    var grid = ArrayList(ArrayList(u8)).init(alloc);

    defer grid.deinit();

    for (0..N) |_| {
        const line = try readstr('\n');
        try grid.append(try strtolist(line));
    }

    const res = try search(grid);
    try stdout.print("END {}\n", .{res});

    var res2: i64 = 0;

    const M = grid.items[0].items.len;

    for (0..N) |i| {
        for (0..M) |j| {
            if (grid.items[i].items[j] != '.') continue;
            grid.items[i].items[j] = '#';
            if (try search(grid) < 0) res2 += 1;
            grid.items[i].items[j] = '.';
        }
    }

    try stdout.print("END2 {}\n", .{res2});
}
