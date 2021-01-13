#!/usr/bin/env dub
/+ dub.sdl:
	name        "pdb_info"
	targetType  "executable"
	targetPath  "../bin"
	targetName  "pdb_info"
	dependency "biophysics" version="*" path=".."
+/

/* Copyright (C) 2020 Andreas Füglistaler <andreas.fueglistaler@gmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module tools.info;

import biophysics.pdb;

auto count(Range)(Range atoms) {
	int[char] chains;
	int[char] old_res;

	foreach (a; atoms) {
		immutable ch = a.chainID;
		chains.require(ch, 0);
		old_res.require(ch, 0);
		if (a.resSeq != old_res[ch]) {
			old_res[ch] = a.resSeq;
			chains[ch]++;
		}
	}
	return chains;
}

immutable description=
"Print information about a protein file.";

void main(string[] args) {
	import std.getopt;
	import std.algorithm;
	import std.stdio;
	import std.array;
	import std.string;

	auto opt = getopt(args);

	if (args.length > 2 || opt.helpWanted) {
		defaultGetoptPrinter(
			"Usage: " ~ args[0]
			~ " [OPTIONS]... [FILE]\n"
			~ description
			~ "\n\nWith no FILE, or when FILE is --,"
			~ " read standard input.\n",
			opt.options);
		return;
	}

	immutable hasFile = args.length == 2;
	immutable fn      = (hasFile ? args[1] : "");
	auto file = (hasFile ? File(fn) : stdin);
	auto chains = file.parse.count;

	int tot = 0;
	foreach (nres; chains.values.sort.reverse) {
		writef("%5d ", nres);
		tot += nres;
	}
	writef("%5d ", tot);
	writefln("%-12s", fn);
}
