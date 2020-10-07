#!/usr/bin/env dub
/+ dub.sdl:
	name        "rm_res"
	targetType  "executable"
	targetPath  "../bin"
	targetName  "rm_res"
	dependency "biophysics" version="*" path=".."
+/

/* Copyright (C) 2020 Andreas Füglistaler <andreas.fueglistaler@gmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module tools.extract;

auto str2index(string s) {
	import std.array;
	import std.conv;

	int[] index;
	immutable csplits = s.split(',');
	foreach (csp; csplits) {
		immutable dsplits = csp.split('-');	
		if (dsplits.length == 1) index ~= dsplits[0].to!int;
		else {
			immutable from = dsplits[0].to!int;
			immutable to   = dsplits[1].to!int + 1;
			foreach (i; from .. to) index ~= i;
		}
	}
	return index;
}

immutable description=
"Remove residues from PDB-FILE and print remaining file to standard output.";

immutable extra =	
"Declare residues as numbers, seperated by '-' and ','. For example, to
remove residues 1 to 10, 13 and 15 to 20, use
--residues 1-10,13,15-20.";

void main(string[] args) {
	import std.getopt;
	import std.algorithm;
	import std.stdio;
	import std.array;
	import std.string;
	import biophysics.pdb;

	bool   non      = false;
	string residues = "";

	auto opt = getopt(
		args,
		"hetatm|n",
		"Use non-standard (HETATM) residues",
		&non,

		"residues|r",
		"residues to extract.",
		&residues);

	if (args.length > 2 || opt.helpWanted) {
		defaultGetoptPrinter(
			"Usage: " ~ args[0]
			~ " [OPTIONS]... [FILE]\n"
			~ description
			~ "\n\nWith no FILE, or when FILE is --,"
			~ " read standard input.\n",
			opt.options);
		writeln("\n" ~ extra);
		return;
	}
	immutable resSeqs = str2index(residues);
	auto      file    = (args.length == 2 ? File(args[1]) : stdin);

	file.parse(non)
	    .map!((a){
		if (resSeqs.canFind(a.resSeq)) {
			a.x = 0;
			a.y = 0;
			a.z = 0;

			a.occupancy = -1;
		}
		return a;})
	    .print;
}
