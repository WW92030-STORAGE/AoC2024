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

// read in a string (WARNING - For today's problem the line length is super long so it needs to be increased)
pub fn readstr(delim: u8) ![]const u8 {
    const stdin = std.io.getStdIn().reader();
    // const stdout = std.io.getStdOut().writer();

    const bare_line = stdin.readUntilDelimiterAlloc(alloc, delim, 65536) catch unreachable; // Allocates and reads into stdin (max 8192 bytes)
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

// C:/Users/WILLI/Documents/Miscellaneous/VSCODE/ZIG/AOC24_9
pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const theLine = try strtolist(try readstr('\n'));
    const N = theLine.items.len;

    try stdout.print("LEN {}\n", .{N});

    // PART ONE

    var protogen = ArrayList(i64).init(alloc);
    var res: i64 = 0;
    for (0..N) |i| {
        // hhhhhhhhhhhhhhhhhhhhhhh
        const id: i64 = @intCast(i / 2);
        const filesize: usize = @intCast(theLine.items[i] - '0');
        for (0..filesize) |_| {
            if (i % 2 == 0) try protogen.append(id);
            if (i % 2 == 1) try protogen.append(-1);
        }
    }

    const M = protogen.items.len;

    var R = M - 1;
    var L: usize = 0;
    while (L < R) {
        while (L < M and protogen.items[L] >= 0) L = L + 1;
        while (R >= 0 and protogen.items[R] < 0) R = R - 1;
        if (L >= R) break;
        protogen.items[L] = protogen.items[R];
        protogen.items[R] = -1;
    }

    for (0..M) |i| {
        // hhhhhhhhhhhhhhhhhhhhhhh
        const index: i64 = @intCast(i);
        const id: i64 = @intCast(protogen.items[i]);
        // try stdout.print("{} {}\n", .{ index, id });
        if (id < 0) continue;
        res += index * id;
    }

    // PART TWO

    // Maintain a linked list of (id, size) values. Then modify as needed and finish by doing the same thing as in protogen.

    var primagen = ArrayList([]const i64).init(alloc);
    defer primagen.deinit();

    for (0..N) |i| {
        // hhhhhhhhhhhhhhhhhhhhhhh
        const id: i64 = @intCast(i / 2);
        const filesize: i64 = @intCast(theLine.items[i] - '0');

        const list = try alloc.alloc(i64, 2);
        errdefer alloc.free(list);
        list[0] = id;
        list[1] = filesize;
        if (i % 2 == 1) list[0] = -1;
        try primagen.append(list);
    }

    const LEN = primagen.items.len;

    for (0..LEN) |i| {
        try stdout.print("[{} {}]\n", .{ primagen.items[i][0], primagen.items[i][1] });
    }

    // starting from the end, we do this:
    // R pointer goes left until it finds a suitable value to look into
    // From there an L pointer moves from the left (starts from 0) rightwards (until R) until it finds a free block large enough
    // If it does then the R block is removed, and the L block is split into two sections: one identical to the original R block and then a -1 remaining space

    var R2: i64 = @intCast(LEN - 1);
    while (R2 >= 0) {
        R = @intCast(R2);
        if (primagen.items[R][0] < 0) {
            R2 -= 1;
            continue;
        }
        L = LEN;
        for (0..R) |i| {
            if (primagen.items[i][0] < 0 and primagen.items[i][1] >= primagen.items[R][1]) {
                L = i;
                break;
            }
        }
        if (L >= LEN) {
            try stdout.print("NO PRIMAGEN FOUND {} {} {}\n", .{ R, primagen.items[R][0], primagen.items[R][1] });
            R2 -= 1;
            continue;
        }

        try stdout.print("PRIMAGEN FOUND {} {} / {} {} {}\n", .{ L, primagen.items[L][1], R, primagen.items[R][0], primagen.items[R][1] });

        const id: i64 = primagen.items[R][0];
        const filesize: i64 = primagen.items[R][1];
        const bigfile: i64 = primagen.items[L][1];

        _ = primagen.orderedRemove(R);

        const thing = try alloc.alloc(i64, 2);
        errdefer alloc.free(thing);

        thing[0] = -1;
        thing[1] = filesize;

        try primagen.insert(R, thing);

        _ = primagen.orderedRemove(L);

        const blk = try alloc.alloc(i64, 2);
        const rem = try alloc.alloc(i64, 2);

        errdefer alloc.free(blk);
        errdefer alloc.free(rem);

        blk[0] = id;
        blk[1] = filesize;

        rem[0] = -1;
        rem[1] = bigfile - filesize;

        // Insert the remaining block
        try primagen.insert(L, rem);
        // Insert the relocated R;
        try primagen.insert(L, blk);

        R2 -= 1;
    }

    for (0..primagen.items.len) |i| {
        try stdout.print("[{} {}] ", .{ primagen.items[i][0], primagen.items[i][1] });
    }
    try stdout.print("\n", .{});

    var res2: i64 = 0;
    var index: i64 = 0;

    for (0..primagen.items.len) |i| {
        const id: i64 = @intCast(primagen.items[i][0]);
        const filesize: usize = @intCast(primagen.items[i][1]);
        if (filesize <= 0) continue;

        for (0..filesize) |_| {
            if (id >= 0) res2 += index * id;
            index += 1;
        }
    }

    try stdout.print("END {}\n", .{res});
    try stdout.print("END2 {}\n", .{res2});
}
