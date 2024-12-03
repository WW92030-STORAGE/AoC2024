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

	const bare_line = stdin.readUntilDelimiterAlloc(alloc, delim, 8192) catch unreachable; // Allocates and reads into stdin (max 8192 bytes)
	defer std.heap.page_allocator.free(bare_line); // Prepares the data for freeing
	const line = std.mem.trim(u8, bare_line, "\r\n"); // Trim some unnecessary data from it

	return line;
}

// read and split a line (does not work)
pub fn splitline() !ArrayList([]const u8) {
	// const stdout = std.io.getStdOut().writer();
	const stdin = std.io.getStdIn().reader();

	const bare_line = stdin.readUntilDelimiterAlloc(alloc, '\n', 8192) catch unreachable; // Allocates and reads into stdin (max 8192 bytes)
	defer std.heap.page_allocator.free(bare_line); // Prepares the data for freeing
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

	var it = std.mem.split(u8, line, " ");
    while (it.next()) |x| {
		const integer = fmt.parseInt(i64, x, 10) catch unreachable;
		try res.append(integer);
    }
	return res;

}

// PART I

pub fn check(splits: ArrayList(i64)) !bool {
		const length = splits.items.len; // consts can be inferred

		// try stdout.print("LEN {}\n", .{length});

		var isvalid: bool = true; // variables must be declared with a type.
		var direction: i8 = 0;

		// control flow must be bracketed in this strange way where the else is on the same line as the close bracket.
		if (splits.items[0] > splits.items[1]) {
			direction = -1;
		} else if (splits.items[0] < splits.items[1]) {
			direction = 1;
		} else {
			return false;
		}

		// PART I

		var k: usize = 0; // this is our loop counter. it is isolated to demonstrate the next line.
		for (0..(length - 1)) |_| { // [+] ... even in nested loops
			// try stdout.print("{} ", .{splits.items[k]});
			if ((direction > 0) != (splits.items[k] < splits.items[k + 1])) {
			 	// try stdout.print("ITER {} FAILS THE DIRECTION CHECK", .{k});
				isvalid = false;
			}
			if (@abs(splits.items[k] - splits.items[k + 1]) > 3) {
				// try stdout.print("ITER {} FAILS THE SMOOTH CHECK", .{k});
				isvalid = false;
			}
			if (@abs(splits.items[k] - splits.items[k + 1]) <= 0) {
				// try stdout.print("ITER {} FAILS THE CHANGE CHECK", .{k});
				isvalid = false;
			}
			k = k + 1; // increment the loop counter
		}

		return isvalid;
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
	const N = 1000; // size of the input



	var res: i64 = 0;
	var res2: i64 = 0;

	for (0..N) |_| { // you can use the _ symbol for an empty closure ... [+]
		const splits = try splitlineint(); // this function reads in a series of integers from stdin
		const length = splits.items.len;

		const p1 = check(splits) catch unreachable;
		if (p1) res += 1;

		// PART II

		var isvalid: bool = false;

		for (0..length) |i| {
			var list = ArrayList(i64).init(alloc);
			for (0..length) |j| {
				if (j == i) continue;

				try list.append(splits.items[j]);
			}

			const p2 = check(list) catch unreachable;
			if (p2) isvalid = true;
		}
		if (isvalid) res2 += 1;
	}
	
	try stdout.print("END {}\n", .{res});
	try stdout.print("END2 {}\n", .{res2});

}
