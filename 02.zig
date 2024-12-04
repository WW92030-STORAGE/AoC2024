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
    //const line = std.mem.trim(u8, bare_line, "\r\n"); // Trim some unnecessary data from it

    return bare_line;
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

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const N = 6;

    var res: i64 = 0;
    var res2: i64 = 0;
    var protogen: bool = true;
    for (0..N) |_| {
        const line = readstr('\n') catch unreachable;
        defer std.heap.page_allocator.free(line);
        try stdout.print("{}\n", .{line.len});

        const L: i64 = @intCast(line.len);

        var i: usize = 0;

        while (i < L) {
            // try stdout.print("{c}", .{line[i]});
            if (i < L - 4 and try strcmp(line[i .. i + 4], "do()")) {
                protogen = true;
                i = i + 4;
                continue;
            }
            if (i < L - 7 and try strcmp(line[i .. i + 7], "don't()")) {
                protogen = false;
                i = i + 7;
                continue;
            }
            if (i < L - 4 and try strcmp(line[i .. i + 3], "mul")) {
                try stdout.print("MUL FOUND {s}\n", .{line[i..]});
                i = i + 3;

                if (line[i] != '(') continue;
                i = i + 1;
                const open: usize = i;
                var comma: usize = 0;
                var close: usize = 0;
                var invalid: bool = false;
                while (true) {
                    if (line[i] == ',') {
                        if (comma > 0 or close > 0) {
                            invalid = true;
                            break;
                        }
                        comma = @intCast(i);
                    } else if (line[i] == ')') {
                        if (comma <= 0) {
                            invalid = true;
                        }
                        close = @intCast(i);
                        break;
                    } else if (line[i] >= '0' and line[i] <= '9') {} else {
                        invalid = true;
                        break;
                    }
                    i = i + 1;
                }
                if (invalid) {
                    continue;
                }
                if (comma <= 0 or close <= 0) {
                    continue;
                }
                try stdout.print("{} {} {}\n", .{ open, comma, close });

                for (open..comma) |x| {
                    if (line[x] < '0' or line[x] > '9') {
                        invalid = true;
                    }
                }
                for (comma + 1..close) |x| {
                    if (line[x] < '0' or line[x] > '9') {
                        invalid = true;
                    }
                }
                try stdout.print("INVALID {}\n", .{invalid});
                if (invalid) {
                    continue;
                }

                const x = std.fmt.parseInt(i64, line[open..comma], 10) catch unreachable;
                const y = std.fmt.parseInt(i64, line[comma + 1 .. close], 10) catch unreachable;
                try stdout.print("VARS {} {}\n", .{ x, y });
                res += x * y;
                if (protogen) res2 += x * y;
            } else {
                i += 1;
            }
        }
    }

    try stdout.print("END {}\n", .{res});
    try stdout.print("END2 {}\n", .{res2});
}
