const builtin = @import("builtin");
const std = @import("std");

const io = std.io;
const fmt = std.fmt;

const eql = std.mem.eql;
const ArrayList = std.ArrayList;
var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
const alloc = gpa.allocator();

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

// You can specify a *Type argument to pass by reference
// In the caller this argument is passed aS &arg.
pub fn protogen(input: ArrayList([]const u8), i: usize, j: usize, c: u8, vis: ArrayList(ArrayList(bool)), nexie: *ArrayList(ArrayList(bool))) !void {
    // const stdout = std.io.getStdOut().writer();
    // try stdout.print(">> {} {} : {}\n", .{ i, j, c });
    if (c == '9') {
        nexie.items[i].items[j] = true;
        return;
    }

    const N = input.items.len;
    const M = input.items[0].len;

    const dx = [4]i64{ 1, 0, -1, 0 };
    const dy = [4]i64{ 0, 1, 0, -1 };

    // stuff like this is exactly why C++ is forever superior to this dictatorship of a language
    const x: i64 = @intCast(i);
    const y: i64 = @intCast(j);

    for (0..4) |d| {
        const xp = dx[d] + x;
        const yp = dy[d] + y;
        if (xp < 0 or yp < 0 or xp >= N or yp >= M) continue;
        const xpp: usize = @intCast(xp);
        const ypp: usize = @intCast(yp);

        if (vis.items[xpp].items[ypp]) continue;
        if (input.items[xpp][ypp] != c + 1) continue;

        vis.items[xpp].items[ypp] = true;
        try protogen(input, xpp, ypp, c + 1, vis, nexie);
        vis.items[xpp].items[ypp] = false;
    }
}

pub fn primagen(input: ArrayList([]const u8), i: usize, j: usize, c: u8, vis: ArrayList(ArrayList(bool))) !i64 {
    // const stdout = std.io.getStdOut().writer();
    // try stdout.print(">> {} {} : {}\n", .{ i, j, c });
    if (c == '9') {
        return 1;
    }

    const N = input.items.len;
    const M = input.items[0].len;

    const dx = [4]i64{ 1, 0, -1, 0 };
    const dy = [4]i64{ 0, 1, 0, -1 };

    // stuff like this is exactly why C++ is forever superior to this dictatorship of a language
    const x: i64 = @intCast(i);
    const y: i64 = @intCast(j);

    var res: i64 = 0;

    for (0..4) |d| {
        const xp = dx[d] + x;
        const yp = dy[d] + y;
        if (xp < 0 or yp < 0 or xp >= N or yp >= M) continue;
        const xpp: usize = @intCast(xp);
        const ypp: usize = @intCast(yp);

        if (vis.items[xpp].items[ypp]) continue;
        if (input.items[xpp][ypp] != c + 1) continue;

        vis.items[xpp].items[ypp] = true;
        res += try primagen(input, xpp, ypp, c + 1, vis);
        vis.items[xpp].items[ypp] = false;
    }

    return res;
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const N = 56;

    var input = ArrayList([]const u8).init(alloc);
    defer input.deinit();

    for (0..N) |_| {
        try input.append(try readstr('\n'));
    }

    const M = input.items[0].len;

    try stdout.print("{} {}\n", .{ N, M });

    for (0..N) |i| {
        try stdout.print("{s}\n", .{input.items[i]});
    }

    var res: i64 = 0;
    var res2: i64 = 0;

    for (0..N) |i| {
        for (0..M) |j| {
            if (input.items[i][j] == '0') {
                var vis = try memset2(bool, N, M, false);
                var pp = try memset2(bool, N, M, false);
                defer vis.deinit();
                defer pp.deinit();
                try protogen(input, i, j, '0', vis, &pp);

                var prism: i64 = 0;

                for (0..N) |x| {
                    for (0..M) |y| {
                        if (pp.items[x].items[y]) prism += 1;
                    }
                }

                var vis2 = try memset2(bool, N, M, false);
                defer vis2.deinit();
                const azion: i64 = try primagen(input, i, j, '0', vis2);

                res += prism;
                res2 += azion;

                try stdout.print("{} {} = {} {}\n", .{ i, j, prism, azion });
            }
        }
    }

    try stdout.print("END {}\n", .{res});
    try stdout.print("END2 {}\n", .{res2});
}
