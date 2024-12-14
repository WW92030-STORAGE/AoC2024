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

pub fn disp(v: ArrayList([]const u8)) !void {
    std.debug.print("[", .{});
    for (0..v.items.len) |i| {
        if (i > 0) std.debug.print(", ", .{});
        std.debug.print("{s}", .{v.items[i]});
    }
    std.debug.print("]\n", .{});
}

pub fn protogen(ax: i64, ay: i64, bx: i64, by: i64, px: i64, py: i64) !i64 {
    var res: i64 = 3 * (px + py);
    var solved: bool = false;

    var times: usize = @intCast(@divFloor(px, ax));
    if (times > 100) times = 100;

    for (0..times + 4) |index| {
        const as: i64 = @intCast(index);
        const dx = ax * as;
        const dy = ay * as;
        const rx = px - dx;
        const ry = py - dy;
        if (rx < 0 or ry < 0) continue;
        if (@mod(rx, bx) != 0) continue;
        if (@mod(ry, by) != 0) continue;
        if (@divFloor(rx, bx) != @divFloor(ry, by)) continue;
        const tests = 3 * as + @divFloor(rx, bx);
        if (tests < res) res = tests;
        solved = true;
    }

    if (!solved) return 0;
    return res;
}

pub fn primagen(ax: i64, ay: i64, bx: i64, by: i64, pxx: i64, pyy: i64) !i64 {
    const px = pxx + 10000000000000;
    const py = pyy + 10000000000000;
    var res: i64 = 0;

    // 3A + B minimize
    // under the constraints
    // (ax)A + (bx)B = px
    // (ay)A + (by)B = py
    // actually because ax, ay, bx, by > 0 and so are px, py this means only one solution

    // Solve the system using Cramer's rule

    const d: i64 = ax * by - bx * ay;
    const dx: i64 = px * by - py * bx;
    const dy: i64 = ax * py - px * ay;

    if (@mod(dx, d) != 0 or @mod(dy, d) != 0) return res;
    const x = @divFloor(dx, d);
    const y = @divFloor(dy, d);
    res = 3 * x + y;
    return res;
}

pub fn main() !void {
    const NN = 1279; // Number of LINES in the input
    const N = @divFloor(NN + 1, 4); // Normalize with test cases

    var res: i64 = 0;
    var res2: i64 = 0;

    for (0..N) |sksk| {
        const A = try splitline(" ");
        const B = try splitline(" ");
        const P = try splitline(" ");
        if (sksk < N - 1) _ = try readstr('\n'); // There are spaces between test cases but not after the last one

        try disp(A);
        try disp(B);
        try disp(P);

        const ax = try fmt.parseInt(i64, A.items[2][2 .. A.items[2].len - 1], 10);
        const ay = try fmt.parseInt(i64, A.items[3][2..A.items[3].len], 10);

        const bx = try fmt.parseInt(i64, B.items[2][2 .. B.items[2].len - 1], 10);
        const by = try fmt.parseInt(i64, B.items[3][2..B.items[3].len], 10);

        const px = try fmt.parseInt(i64, P.items[1][2 .. P.items[1].len - 1], 10);
        const py = try fmt.parseInt(i64, P.items[2][2..P.items[2].len], 10);
        std.debug.print("A {} {}\n", .{ ax, ay });
        std.debug.print("B {} {}\n", .{ bx, by });
        std.debug.print("P {} {}\n", .{ px, py });

        const returns = try protogen(ax, ay, bx, by, px, py);
        res += returns;

        const returns2 = try primagen(ax, ay, bx, by, px, py);
        res2 += returns2;

        std.debug.print("PROTOGEN {}\n", .{returns});
        std.debug.print("PRIMAGEN {}\n", .{returns2});
    }

    std.debug.print("END {}\n", .{res});
    std.debug.print("END {}\n", .{res2});
}
