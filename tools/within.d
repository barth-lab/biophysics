#!/usr/bin/env dub
/+ dub.sdl:
	name        "within"
	targetType  "executable"
	targetPath  "../bin"
	targetName  "within"
	dependency "biophysics" version="*" path=".."
+/

/* Copyright (C) 2020 Andreas Füglistaler <andreas.fueglistaler@gmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module tools.within;

import biophysics.pdb;

immutable description=
"Find residues in PDB-FILE within DISTANCE of chain/residues to standard output.";

auto within(R1, R2)(R1 from, R2 to, double distance) {
	import std.algorithm;
	import std.math;
	import std.range;
	import std.stdio;
	double[3][] coords;
	foreach (a; to) {
		coords  ~= [a.x, a.y, a.z];
	}
	int[] res = [0];
	foreach (ai; from) {
		auto rs = ai.resSeq;

		immutable double[3] ci = [ai.x, ai.y, ai.z];
		foreach (cj; coords) {
			if ((res[$ - 1] == rs)) break;
			if (ci.distance(cj) < distance) {
				res ~= rs;
			}	
		}
	}
	return res[1 .. $];
}

void main(string[] args) {
	import std.getopt;
	import std.algorithm;
	import std.stdio;
	import std.array;

	bool   non      = false;
	double distance = 4.;
	string chains   = "B";

	auto opt = getopt(
		args,
		"hetatm|n",
		"Use non-standard (HETATM) residues",
		&non,

		"distance|d",
		"Within this DISTANCE",
		&distance,

		"chains|c",
		"CHAINS to use, default = all",
		&chains);

	if (args.length > 2 || args.length == 0 || opt.helpWanted) {
		defaultGetoptPrinter(
			"Usage: " ~ args[0]
			~ " [OPTIONS]... FILE1 [FILE2]\n"
			~ description
			~ "\n\nWith no FILE2, or when FILE2 is --,"
			~ " read standard input.\n",
			opt.options);
		return;
	}

	auto file  = (args.length == 2 ? File(args[1]) : stdin);
	auto pdb   = file.parse(non)
		       .map!dup
		       .array;
	auto from  = pdb.filter!(a => !chains.canFind(a.chainID));
	auto to    = pdb.filter!(a => chains.canFind(a.chainID));
	string sout = "";
	import std.format;
	foreach (res; within(from, to, distance)) {
		sout ~= format("%d", res);
		sout ~= ',';
	}
	if (!sout.empty) writeln(sout[0 .. $-1]);
}
