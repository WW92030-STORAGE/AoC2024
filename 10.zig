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

pub fn protogen(thing: i64) !ArrayList(i64) {
    var res = ArrayList(i64).init(alloc);
    errdefer res.deinit();
    if (thing == 0) {
        try res.append(1);
        return res;
    }
    const str = try itolist(thing);
    if (str.items.len % 2 == 0) {
        const M = str.items.len / 2;
        var L = ArrayList(u8).init(alloc);
        var R = ArrayList(u8).init(alloc);
        errdefer L.deinit();
        errdefer R.deinit();

        for (0..M) |j| {
            try L.append(str.items[j]);
            try R.append(str.items[j + M]);
        }

        try res.append(try fmt.parseInt(i64, L.items, 10));
        try res.append(try fmt.parseInt(i64, R.items, 10));
        return res;
    }
    try res.append(thing * 2024);
    return res;
}

// brute force part 1 using an arraylist
pub fn protogen2(input: ArrayList(i64)) !ArrayList(i64) {
    const DEBUG = false;

    var res = ArrayList(i64).init(alloc);
    const N = input.items.len;
    if (DEBUG) std.debug.print("LEN INPUT {}\n", .{N});
    for (0..N) |i| {
        const thing = input.items[i];
        if (thing == 0) {
            if (DEBUG) std.debug.print("ZERO\n", .{});
            try res.append(1);
            continue;
        }
        const str = try itolist(thing);
        if (DEBUG) std.debug.print("STR LEN {} = {}\n", .{ input.items[i], str.items.len });
        if (str.items.len % 2 == 0) {
            const M = str.items.len / 2;
            var L = ArrayList(u8).init(alloc);
            var R = ArrayList(u8).init(alloc);
            errdefer L.deinit();
            errdefer R.deinit();

            for (0..M) |j| {
                try L.append(str.items[j]);
                try R.append(str.items[j + M]);
            }

            if (DEBUG) std.debug.print("HALF/HALF {s} {s}\n", .{ L.items, R.items });

            try res.append(try fmt.parseInt(i64, L.items, 10));
            try res.append(try fmt.parseInt(i64, R.items, 10));
            continue;
        }
        if (DEBUG) std.debug.print("ODD ONE OUT {}\n", .{thing});
        try res.append(thing * 2024);
    }
    return res;
}

pub fn primogenitor(input: std.AutoHashMap(i64, i64)) !i64 {
    var res: i64 = 0;
    var it = input.iterator();
    while (it.next()) |thing| res += thing.value_ptr.*;
    return res;
}

pub fn primagen(input: std.AutoHashMap(i64, i64)) !std.AutoHashMap(i64, i64) {
    var res = std.AutoHashMap(i64, i64).init(alloc);
    var it = input.iterator();
    while (it.next()) |thing| {
        const key = thing.key_ptr.*;
        const val = thing.value_ptr.*;

        const theresult = try protogen(key);
        for (0..theresult.items.len) |i| {
            const k = theresult.items[i];
            const ss = res.get(k);
            if (ss) |cnt| {
                try res.put(k, cnt + val);
            } else {
                try res.put(k, val);
            }
        }
    }
    return res;
}

pub fn main() !void {
    var list = try splitlineint(" ");
    defer list.deinit();
    var input = ArrayList(i64).init(alloc);
    defer input.deinit();

    for (0..list.items.len) |i| try input.append(list.items[i]);

    const N = list.items.len;
    const K = 25; // Number of times to do it

    std.debug.print("{}\n", .{N});

    for (0..N) |i| std.debug.print("{} ", .{list.items[i]});
    std.debug.print("\n", .{});

    for (0..K) |_| {
        list = try protogen2(list);
        errdefer list.deinit();

        std.debug.print("{}\n", .{list.items.len});
    }

    const res = list.items.len;

    var freq = std.AutoHashMap(i64, i64).init(alloc);
    defer freq.deinit();

    // PART TWO

    const K2 = 75;

    for (0..N) |i| {
        const x = input.items[i];
        const existing = freq.get(x);
        if (existing) |v| {
            try freq.put(x, v + 1);
        } else {
            try freq.put(x, 1);
        }
    }

    for (0..K2) |_| {
        freq = try primagen(freq);
        errdefer freq.deinit();
        std.debug.print("{}\n", .{try primogenitor(freq)});
    }

    const res2 = try primogenitor(freq);

    std.debug.print("END {}\n", .{res});
    std.debug.print("END2 {}\n", .{res2});
}
