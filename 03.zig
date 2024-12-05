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

// read and split a line (does not work)
pub fn splitline() !ArrayList([]const u8) {
    // const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    const bare_line = stdin.readUntilDelimiterAlloc(alloc, '\n', 8192) catch unreachable; // Allocates and reads into stdin (max 8192 bytes)
    errdefer std.heap.page_allocator.free(bare_line); // Prepares the data for freeing
    const line = std.mem.trim(u8, bare_line, "\r\n"); // Trim some unnecessary data from it

    var res = ArrayList([]const u8).init(alloc);

    var it = std.mem.split(u8, line, " ");
    while (it.next()) |x| {
        try res.append(x);
    }
    return res;
}

// read and split a line into integers
pub fn splitlineint() !ArrayList(i64) {
    // const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    const bare_line = stdin.readUntilDelimiterAlloc(alloc, '\n', 8192) catch unreachable; // Allocates and reads into stdin (max 8192 bytes)
    defer std.heap.page_allocator.free(bare_line); // Prepares the data for freeing
    const line = std.mem.trim(u8, bare_line, "\r\n"); // Trim some unnecessary data from it

    var res = ArrayList(i64).init(alloc);
    errdefer res.deinit(); // prevent mem leask in error
    // err defer things?

    var it = std.mem.split(u8, line, " ");
    while (it.next()) |x| {
        const integer = fmt.parseInt(i64, x, 10) catch unreachable;
        try res.append(integer);
    }
    return res;
}

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

pub fn search(grid: ArrayList([]const u8), str: []const u8) !i64 {
    const DEBUG = false;

    const stdout = std.io.getStdOut().writer();
    const N = grid.items.len;
    const M = grid.items[0].len;
    const L = str.len;
    const LP = L - 1;
    try stdout.print("{} {} {} {}\n", .{ N, M, L, LP });
    var res: i64 = 0;
    for (0..N) |i| {
        for (0..M - LP) |j| {
            if (try strcmp(grid.items[i][j .. j + L], str)) {
                if (DEBUG) try stdout.print("FOUND {} {}\n", .{ i, j });
                res += 1;
            }
        }
    }
    for (0..N) |i| {
        for (LP..M) |j| {
            var isv: bool = true;
            for (0..L) |k| {
                if (grid.items[i][j - k] != str[k]) {
                    isv = false;
                }
            }
            if (isv) {
                if (DEBUG) try stdout.print("FOUND {} {}\n", .{ i, j });
                res += 1;
            }
        }
    }
    for (0..N - LP) |i| {
        for (0..M) |j| {
            var isv: bool = true;
            for (0..L) |k| {
                if (grid.items[i + k][j] != str[k]) {
                    isv = false;
                }
            }
            if (isv) {
                if (DEBUG) try stdout.print("FOUND {} {}\n", .{ i, j });
                res += 1;
            }
        }
    }
    for (LP..N) |i| {
        for (0..M) |j| {
            var isv: bool = true;
            for (0..L) |k| {
                if (grid.items[i - k][j] != str[k]) {
                    isv = false;
                }
            }
            if (isv) {
                if (DEBUG) try stdout.print("FOUND {} {}\n", .{ i, j });
                res += 1;
            }
        }
    }

    for (0..N - LP) |i| {
        for (0..M - LP) |j| {
            var isv: bool = true;
            for (0..L) |k| {
                if (grid.items[i + k][j + k] != str[k]) {
                    isv = false;
                }
            }
            if (isv) {
                if (DEBUG) try stdout.print("FOUND {} {}\n", .{ i, j });
                res += 1;
            }
        }
    }
    for (LP..N) |i| {
        for (0..M - LP) |j| {
            var isv: bool = true;
            for (0..L) |k| {
                if (grid.items[i - k][j + k] != str[k]) {
                    isv = false;
                }
            }
            if (isv) {
                if (DEBUG) try stdout.print("FOUND {} {}\n", .{ i, j });
                res += 1;
            }
        }
    }
    for (LP..N) |i| {
        for (LP..M) |j| {
            var isv: bool = true;
            for (0..L) |k| {
                if (grid.items[i - k][j - k] != str[k]) {
                    isv = false;
                }
            }
            if (isv) {
                if (DEBUG) try stdout.print("FOUND {} {}\n", .{ i, j });
                res += 1;
            }
        }
    }
    for (0..N - LP) |i| {
        for (LP..M) |j| {
            var isv: bool = true;
            for (0..L) |k| {
                if (grid.items[i + k][j - k] != str[k]) {
                    isv = false;
                }
            }
            if (isv) {
                if (DEBUG) try stdout.print("FOUND {} {}\n", .{ i, j });
                res += 1;
            }
        }
    }
    return res;
}

pub fn protogen(grid: ArrayList([]const u8)) !i64 {
    const N = grid.items.len;
    const M = grid.items[0].len;
    const LP = 1;

    const dx = [8]i64{ 1, 1, -1, -1, 1, 1, -1, -1 };
    const dy = [8]i64{ 1, -1, -1, 1, 1, -1, -1, 1 };
    const dz = [4]u8{ 'M', 'M', 'S', 'S' };

    var res: i64 = 0;
    for (1..N - LP) |i| {
        for (1..M - LP) |j| {
            var iv: bool = false;
            if (grid.items[i][j] != 'A') continue;
            for (0..4) |d| {
                var ivs: bool = true;
                for (0..4) |p| {
                    const x: i64 = @intCast(i);
                    const y: i64 = @intCast(j);
                    const xx: usize = @intCast(x + dx[d + p]);
                    const yy: usize = @intCast(y + dy[d + p]);
                    if (grid.items[xx][yy] != dz[p]) ivs = false;
                }

                if (ivs) iv = true;
            }
            if (iv) res += 1;
        }
    }

    return res;
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const N = 140;

    var grid = ArrayList([]const u8).init(alloc);

    for (0..N) |_| {
        try grid.append(try readstr('\n'));
    }

    const res: i64 = try search(grid, "XMAS");
    try stdout.print("END {}\n", .{res});

    const res2: i64 = try protogen(grid);
    try stdout.print("END2 {}\n", .{res2});
}
