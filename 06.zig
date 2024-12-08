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

// Here the index is to begin at 1. We implicitly place ops[0] into the register before doing anything so we have a value to start with.
pub fn protogen(ops: ArrayList(i64), val: i64, index: usize, register: i64) !bool {
    const N = ops.items.len;
    if (index >= N) return register == val;

    var res: bool = false;

    const plus = register + ops.items[index];
    if (plus <= val) res = res or try protogen(ops, val, index + 1, plus);
    const times = register * ops.items[index];
    if (times <= val) res = res or try protogen(ops, val, index + 1, times);

    return res;
}

pub fn primagen(ops: ArrayList(i64), val: i64, index: usize, register: i64) !bool {
    // const stdout = std.io.getStdOut().writer();

    const N = ops.items.len;
    if (index >= N) return register == val;

    var res: bool = false;

    const plus = register + ops.items[index];
    if (plus <= val) res = res or try primagen(ops, val, index + 1, plus);
    const times = register * ops.items[index];
    if (times <= val) res = res or try primagen(ops, val, index + 1, times);

    var v1: ArrayList(u8) = try itolist(register);
    const v2 = try itolist(ops.items[index]);
    for (0..v2.items.len) |i| {
        try v1.append(v2.items[i]);
    }

    const concat = try fmt.parseInt(i64, v1.items, 10);
    // try stdout.print("{} {} >> {}\n", .{ register, ops.items[index], concat });
    if (concat <= val) res = res or try primagen(ops, val, index + 1, concat);

    return res;
}

pub fn main() !void { // Please remove the space between the ordering and the inputs
    const stdout = std.io.getStdOut().writer();

    const N = 850;

    var res: i64 = 0;
    var res2: i64 = 0;

    for (0..N) |_| {
        const theline = try splitline(" ");
        const M = theline.items.len;

        const target: i64 = try fmt.parseInt(i64, theline.items[0][0 .. theline.items[0].len - 1], 10);

        var ops = ArrayList(i64).init(alloc);
        defer ops.deinit();
        for (1..M) |i| {
            try ops.append(try fmt.parseInt(i64, theline.items[i], 10));
        }

        const pres = try protogen(ops, target, 1, ops.items[0]);
        try stdout.print(">{} = {}\n", .{ target, pres });

        if (pres) res += target;

        const pres2 = try primagen(ops, target, 1, ops.items[0]);
        try stdout.print("+{} = {}\n", .{ target, pres2 });

        if (pres2) res2 += target;
    }

    try stdout.print("END {}\n", .{res});
    try stdout.print("END2 {}\n", .{res2});
}
