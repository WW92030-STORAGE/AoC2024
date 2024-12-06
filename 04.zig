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

pub fn main() !void { // Please remove the space between the ordering and the inputs
    const stdout = std.io.getStdOut().writer();

    // First number = number of lines in orderings
    // Second number = total number of lines in input includes orderings and updates
    const N = 1176;
    const M = 1386 - N; // remove the uhh orderings

    var sortedpairs = std.AutoHashMap(i64, i64).init(alloc);
    defer sortedpairs.deinit();

    for (0..N) |_| {
        const line = try splitlineint("|");
        try stdout.print("{}|{}\n", .{ line.items[0], line.items[1] });
        try sortedpairs.put(line.items[0] + (line.items[1] << 32), 0);
    }

    var inputs = ArrayList(ArrayList(i64)).init(alloc);
    for (0..M) |_| {
        const line = try splitlineint(",");
        try inputs.append(line);
    }

    var protogen = ArrayList(ArrayList(i64)).init(alloc);
    var primagen = ArrayList(ArrayList(i64)).init(alloc);
    defer protogen.deinit();
    defer primagen.deinit();
    for (0..M) |i| {
        const thing = inputs.items[i];

        var isv: bool = true;
        for (0..thing.items.len) |x| {
            for (0..x) |y| {
                const thevalue = thing.items[y] + (thing.items[x] << 32);
                const valuethe = thing.items[x] + (thing.items[y] << 32);
                const forward = sortedpairs.get(thevalue);
                const backward = sortedpairs.get(valuethe);
                if (backward) |_| {
                    isv = false;
                }
                if (forward) |_| {
                    continue;
                }
            }
        }
        if (isv) {
            try protogen.append(thing);
        } else try primagen.append(thing);
    }
    var res: i64 = 0;

    for (0..protogen.items.len) |i| {
        res = res + protogen.items[i].items[protogen.items[i].items.len / 2];
    }

    var res2: i64 = 0;

    for (0..primagen.items.len) |ii| {
        const primogenitor = primagen.items[ii];

        // Bubble sort using the custom ordering
        for (0..primogenitor.items.len) |_| {
            for (0..primogenitor.items.len - 1) |i| {
                // const thevalue = primogenitor.items[i] + (primogenitor.items[i + 1] << 32);
                const valuethe = primogenitor.items[i + 1] + (primogenitor.items[i] << 32);
                // const forward = sortedpairs.get(thevalue);
                const backward = sortedpairs.get(valuethe);

                if (backward) |_| {
                    const temp = primogenitor.items[i];
                    primogenitor.items[i] = primogenitor.items[i + 1];
                    primogenitor.items[i + 1] = temp;
                }
            }
        }

        res2 += primogenitor.items[primogenitor.items.len / 2];
    }

    try stdout.print("END {}\n", .{res});
    try stdout.print("END2 {}\n", .{res2});
}
