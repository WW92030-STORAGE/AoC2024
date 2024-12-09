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

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const N = 50;

    var grid = ArrayList(ArrayList(u8)).init(alloc);
    defer grid.deinit();

    for (0..N) |_| {
        try grid.append(try strtolist(try readstr('\n')));
    }

    const M = grid.items[0].items.len;

    for (0..N) |i| {
        for (0..M) |j| try stdout.print("{} ", .{grid.items[i].items[j]});
        try stdout.print("\n", .{});
    }

    var freqs = std.AutoHashMap(u8, ArrayList([]const usize)).init(alloc);
    defer freqs.deinit();

    for (0..N) |i| {
        for (0..M) |j| {
            const cell = grid.items[i].items[j];
            if (cell == '.') continue;
            const poses = freqs.getPtr(cell);
            if (poses) |*v| { // MUTABLE CAPTURE????
                var list = try alloc.alloc(usize, 2);
                errdefer alloc.free(list);
                list[0] = i;
                list[1] = j;

                try v.*.append(list);

                try stdout.print("{} = ", .{cell});
                for (0..v.*.items.len) |x| {
                    try stdout.print("{}:{} {} | ", .{ x, v.*.items[x][0], v.*.items[x][1] });
                }
                try stdout.print("\n", .{});
            } else {
                var line = ArrayList([]const usize).init(alloc);
                var list = try alloc.alloc(usize, 2);
                errdefer alloc.free(list);
                list[0] = i;
                list[1] = j;
                try line.append(list);

                try freqs.put(cell, line);
                errdefer line.deinit();
                // try stdout.print("CELL NOT FOUND {}\n", .{cell});

                try stdout.print("{} = ", .{cell});
                for (0..line.items.len) |x| {
                    try stdout.print("{}:{} {} | ", .{ x, line.items[x][0], line.items[x][1] });
                }
                try stdout.print("\n", .{});
            }
        }
    }

    var it = freqs.iterator();

    var protogen = try memset2(bool, N, M, false);
    var primagen = try memset2(bool, N, M, false);
    var res: i64 = 0;
    var res2: i64 = 0;

    while (it.next()) |kv| {
        const key = kv.key_ptr.*;
        const val = freqs.get(key);
        if (val) |v| {
            try stdout.print("BEGIN ITER ON KEY {}\n", .{key});
            const VL = v.items.len;

            for (0..v.items.len) |x| {
                try stdout.print("{}:{} {} | ", .{ x, v.items[x][0], v.items[x][1] });
            }
            try stdout.print("\n", .{});

            // PART ONE

            for (0..VL) |i| {
                for (0..i) |j| {
                    try stdout.print("{} {} / {} {}\n", .{ v.items[i][0], v.items[i][1], v.items[j][0], v.items[j][1] });
                    // HAHAAHAhAhAhAhAhAH RUNTIME SAFETY SO HYPE SO EFFICIENT SO CLEAN TOTALLY NOT OVERDONE HERE HURURR DURRR
                    // int dx = v.items[0] - v.items[1] BUT WE CAN'T BECAUSE IT'S NEGATIVE AND A USIZE HURRR DURURURHRRUR
                    const x1: i64 = @intCast(v.items[i][0]);
                    const x2: i64 = @intCast(v.items[j][0]);
                    const y1: i64 = @intCast(v.items[i][1]);
                    const y2: i64 = @intCast(v.items[j][1]);

                    const dx = x2 - x1;
                    const dy = y2 - y1;

                    const x3 = x1 - dx;
                    const y3 = y1 - dy;
                    const x4 = x2 + dx;
                    const y4 = y2 + dy;
                    // HAHAAHAhAhAhAhAhAH RUNTIME SAFETY SO HYPE SO EFFICIENT SO CLEAN TOTALLY NOT OVERDONE HERE HURURR DURRR
                    // ALL HAIL THE ONE TRUE GOD OF RUNTIME SAFETY
                    if (x3 >= 0 and x3 < N and y3 >= 0 and y3 < M) {
                        const fuckerx: usize = @intCast(x3);
                        const fuckery: usize = @intCast(y3);
                        protogen.items[fuckerx].items[fuckery] = true;
                    }
                    if (x4 >= 0 and x4 < N and y4 >= 0 and y4 < M) {
                        // HAHAAHAhAhAhAhAhAH RUNTIME SAFETY SO HYPE SO EFFICIENT SO CLEAN TOTALLY NOT OVERDONE HERE HURURR DURRR
                        const fuckerx: usize = @intCast(x4);
                        const fuckery: usize = @intCast(y4);
                        protogen.items[fuckerx].items[fuckery] = true;
                    }

                    var R: usize = N;
                    if (M > N) R = M;

                    // PART TWO

                    for (0..R) |dd| {
                        // HAHAAHAhAhAhAhAhAH RUNTIME SAFETY SO HYPE SO EFFICIENT SO CLEAN TOTALLY NOT OVERDONE HERE HURURR DURRR
                        const d: i64 = @intCast(dd);
                        const x5 = x1 - d * dx;
                        const y5 = y1 - d * dy;
                        if (x5 >= 0 and x5 < N and y5 >= 0 and y5 < M) {
                            // HAHAAHAhAhAhAhAhAH RUNTIME SAFETY SO HYPE SO EFFICIENT SO CLEAN TOTALLY NOT OVERDONE HERE HURURR DURRR
                            const fuckerx: usize = @intCast(x5);
                            const fuckery: usize = @intCast(y5);
                            primagen.items[fuckerx].items[fuckery] = true;
                        }
                        const x6 = x2 + d * dx;
                        const y6 = y2 + d * dy;
                        if (x6 >= 0 and x6 < N and y6 >= 0 and y6 < M) {
                            // HAHAAHAhAhAhAhAhAH RUNTIME SAFETY SO HYPE SO EFFICIENT SO CLEAN TOTALLY NOT OVERDONE HERE HURURR DURRR
                            const fuckerx: usize = @intCast(x6);
                            const fuckery: usize = @intCast(y6);
                            primagen.items[fuckerx].items[fuckery] = true;
                        }
                    }
                }
            }
        }
    }

    for (0..N) |i| {
        for (0..M) |j| {
            if (protogen.items[i].items[j]) {
                try stdout.print(">>{} {}\n", .{ i, j });
                res += 1;
            }
            if (primagen.items[i].items[j]) {
                try stdout.print("<<{} {}\n", .{ i, j });
                res2 += 1;
            }
        }
    }

    try stdout.print("END {}\n", .{res});
    try stdout.print("END2 {}\n", .{res2});
}
