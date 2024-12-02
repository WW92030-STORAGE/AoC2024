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

fn cmpByValue(context: void, a: i32, b: i32) bool {
    return std.sort.asc(i32)(context, a, b);
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
	const N = 1000; // size of the input

	var L: [N]i64 = undefined;
	var R: [N]i64 = undefined;
	
	for (0..N) |i| {
		const l = readint(' ') catch unreachable;
		const r = readint('\n') catch unreachable;
		L[i] = l;
		R[i] = r;
		try stdout.print("{} {} {}.\n", .{i, l, r});
	}

	std.mem.sort(i64, &L, {}, comptime std.sort.asc(i64));
	std.mem.sort(i64, &R, {}, comptime std.sort.asc(i64));

	var res: u64 = 0;

	for (0..N) |i| {
		try stdout.print("{} {}\n", .{L[i], R[i]});
		res += @abs(L[i] - R[i]);
	}

	try stdout.print("END {}\n", .{res});



	var map = std.AutoHashMap(i64, i64).init(alloc);
	defer map.deinit(); // prepare the data structure for freeing later

	for (0..N) |i| {
		const value = map.get(R[i]);
		if (value) |v| {
			try map.put(R[i], v + 1);
		}
		else {
			try map.put(R[i], 1);
		}
	}

	res = 0;
	for (0..N) |i| {
		const value = map.get(L[i]);
		if (value) |v| {
			// try stdout.print("{} = {}\n", .{L[i], v});
			res += @intCast(v * L[i]);
		}
	}
	try stdout.print("END2 {}\n", .{res});
}
