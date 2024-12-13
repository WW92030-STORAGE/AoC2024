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

// Convert an integer (i64) to an ArrayList(u8) of digits
pub fn itolist(v: i64) !ArrayList(u8) {
    var vv = ArrayList(u8).init(alloc);
    defer vv.deinit();
    var isn = false;
    var x: i64 = v;
    if (x < 0) {
        isn = true;
        x = -1 * v;
    }
    while (x > 0) {
        const thing: u8 = @intCast(@mod(x, 10)); // TOTALLY NECESSARY RUNTIME SAFETY THING
        try vv.append('0' + thing);
        x = @divFloor(x, 10);
    }
    var res = ArrayList(u8).init(alloc);
    for (0..vv.items.len) |i| {
        try res.append(vv.items[vv.items.len - 1 - i]);
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

pub fn protogen(grid: ArrayList([]const u8), vis: *ArrayList(ArrayList(bool)), si: usize, sj: usize) !i64 {
    var q = std.fifo.LinearFifo([]const i64, .Dynamic).init(alloc);
    defer q.deinit();

    const N = grid.items.len;
    const M = grid.items[0].len;
    const sc = grid.items[si][sj];

    const sx: i64 = @intCast(si);
    const sy: i64 = @intCast(sj);

    const srclist = [2]i64{ sx, sy };

    try q.writeItem(&srclist);

    const dx = [4]i64{ 0, 1, 0, -1 };
    const dy = [4]i64{ 1, 0, -1, 0 };

    var prism: i64 = 0;
    var azion: i64 = 0;

    while (q.readableLength() > 0) {
        const now = q.readItem().?; // POLL POLL POLL

        const x: usize = @intCast(now[0]);
        const y: usize = @intCast(now[1]);

        // std.debug.print("{} {} {}\n", .{ x, y, grid.items[x][y] });

        if (!vis.items[x].items[y]) {
            vis.items[x].items[y] = true;
            azion += 1;
        }
        for (0..4) |d| {
            const xsp = dx[d] + now[0];
            const ysp = dy[d] + now[1];
            if (xsp < 0 or ysp < 0 or xsp >= N or ysp >= M) {
                prism += 1;
                continue;
            }
            const xp: usize = @intCast(xsp);
            const yp: usize = @intCast(ysp);
            if (grid.items[xp][yp] != sc) {
                prism += 1;
                continue;
            }
            if (vis.items[xp].items[yp]) continue;

            vis.items[xp].items[yp] = true;
            azion += 1;

            var nextList = try alloc.alloc(i64, 2);
            errdefer alloc.free(nextList);
            nextList[0] = xsp;
            nextList[1] = ysp;
            // std.debug.print("[{} {}]\n", .{ nextList[0], nextList[1] });
            try q.writeItem(nextList);
        }
    }

    std.debug.print("{} {} {} : {} {}\n", .{ sx, sy, sc, azion, prism });

    return prism * azion;
}

pub fn primagen(grid: ArrayList([]const u8), si: usize, sj: usize) !i64 {
    var q = std.fifo.LinearFifo([]const i64, .Dynamic).init(alloc);
    defer q.deinit();

    const N = grid.items.len;
    const M = grid.items[0].len;
    const sc = grid.items[si][sj];

    const sx: i64 = @intCast(si);
    const sy: i64 = @intCast(sj);

    var vis2 = try memset2(bool, N, M, false);
    defer vis2.deinit();

    var vislist = ArrayList([]const i64).init(alloc);
    defer vislist.deinit();

    const srclist = [2]i64{ sx, sy };

    try q.writeItem(&srclist);

    const dx = [4]i64{ 1, 0, -1, 0 };
    const dy = [4]i64{ 0, 1, 0, -1 };
    const dc = [4]i64{ 1, -1, -1, 1 };
    const ds = [4]i64{ 1, 1, -1, -1 };

    while (q.readableLength() > 0) {
        const now = q.readItem().?; // POLL POLL POLL

        const x: usize = @intCast(now[0]);
        const y: usize = @intCast(now[1]);

        // std.debug.print("{} {} {}\n", .{ x, y, grid.items[x][y] });

        if (!vis2.items[x].items[y]) {
            vis2.items[x].items[y] = true;
            try vislist.append(now);
        }
        for (0..4) |d| {
            const xsp = dx[d] + now[0];
            const ysp = dy[d] + now[1];
            if (xsp < 0 or ysp < 0 or xsp >= N or ysp >= M) continue;
            const xp: usize = @intCast(xsp);
            const yp: usize = @intCast(ysp);
            if (grid.items[xp][yp] != sc) continue;
            if (vis2.items[xp].items[yp]) continue;

            if (!vis2.items[xp].items[yp]) {
                vis2.items[xp].items[yp] = true;
                const list = try alloc.alloc(i64, 2);
                list[0] = xsp;
                list[1] = ysp;
                errdefer alloc.free(list);
                try vislist.append(list);
            }

            var nextList = try alloc.alloc(i64, 2);
            errdefer alloc.free(nextList);
            nextList[0] = xsp;
            nextList[1] = ysp;
            // std.debug.print("[{} {}]\n", .{ nextList[0], nextList[1] });
            try q.writeItem(nextList);
        }
    }

    var res: i64 = 0;
    var nexie: i64 = 0;

    // Have you ever learned shapes in school? A polygon has the same number of sides as it does corners

    // (dc, ds)[d] is the corner directly between (x down, y right) (dx, dy)[d] and [d + 1]

    // std.debug.print("...{} {}\n", .{ sx, sy });

    for (0..vislist.items.len) |in| {
        const i: usize = @intCast(vislist.items[in][0]);
        const j: usize = @intCast(vislist.items[in][1]);

        if (!vis2.items[i].items[j]) continue;
        res += 1;

        // std.debug.print("<{} {}>\n", .{ i, j });

        const x = vislist.items[in][0];
        const y = vislist.items[in][1];
        for (0..4) |d| {
            const dd: usize = @mod(d + 1, 4);

            // edge1, corner, edge2
            const xxx = [3]i64{ x + dx[d], x + dc[d], x + dx[dd] };
            const yyy = [3]i64{ y + dy[d], y + ds[d], y + dy[dd] };

            var status: [3]bool = undefined;

            for (0..3) |ss| {
                status[ss] = false;
                if (xxx[ss] < 0 or xxx[ss] >= N or yyy[ss] < 0 or yyy[ss] >= M) {
                    continue;
                }

                const ux: usize = @intCast(xxx[ss]);
                const uy: usize = @intCast(yyy[ss]);

                if (vis2.items[ux].items[uy]) status[ss] = true;
            }

            // Three types of corners (in this diagram to the up left of the O).
            // ... X.. .XX
            // .OX .OX XOX
            // .XX .XX XXX

            // Count the corners where there is no corner but then the neighboring sides are either filled in or not.
            if (!status[1] and (status[0] == status[2])) nexie += 1;
            // Also count potential corners where there is a corner but the neighboring sides aRe not filled
            if (status[1] and !status[0] and !status[2]) nexie += 1;
        }
    }

    std.debug.print("{} {} {} : {}\n", .{ sx, sy, sc, nexie });

    return res * nexie;
}

pub fn main() !void {
    const N = 140;
    var grid = ArrayList([]const u8).init(alloc);
    defer grid.deinit();

    for (0..N) |_| try grid.append(try readstr('\n'));
    const M = grid.items[0].len;

    var vis = try memset2(bool, N, M, false);
    defer vis.deinit();

    var res: i64 = 0;
    var res2: i64 = 0;

    for (0..N) |i| {
        for (0..M) |j| {
            if (!vis.items[i].items[j]) {
                res += try protogen(grid, &vis, i, j);
                res2 += try primagen(grid, i, j);
            }
        }
    }

    res2 += 1;
    res2 -= 1;

    std.debug.print("END {}\n", .{res});
    std.debug.print("END2 {}\n", .{res2});
}
