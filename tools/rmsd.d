#!/usr/bin/env dub
/+ dub.sdl:
	name        "rmsd"
	targetType  "executable"
	targetPath  "../bin"
	targetName  "rmsd"
	dependency "biophysics" version="*" path=".."
+/

/* Copyright (C) 2020 Andreas Füglistaler <andreas.fueglistaler@gmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module tools.rmsd;

import biophysics.pdb;

double rmsd(R1, R2)(R1 atoms1, R2 atoms2) {
	import std.range;
	import std.math;

	double s = 0;
	int    l = 0;

	foreach (a1, a2; zip(atoms1, atoms2)) {
		immutable dx = a1.x - a2.x;	
		immutable dy = a1.y - a2.y;	
		immutable dz = a1.z - a2.z;	
		s += dx*dx + dy*dy + dz*dz;
		l++;
	}
	return sqrt(s/l);
}

immutable description=
"Calculate CA-rmsd between PDB-FILE1 and PDB-FILE2 to standard output.";

void main(string[] args) {
	import std.getopt;
	import std.algorithm;
	import std.stdio;

	bool   non    = false;
	string chains = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

	auto opt = getopt(
		args,
		"hetatm|n",
		"Use non-standard (HETATM) residues",
		&non,

		"chains|c",
		"CHAINS to use, default = all",
		&chains);

	if (args.length > 3 || args.length == 0 || opt.helpWanted) {
		defaultGetoptPrinter(
			"Usage: " ~ args[0]
			~ " [OPTIONS]... FILE1 [FILE2]\n"
			~ description
			~ "\n\nWith no FILE2, or when FILE2 is --,"
			~ " read standard input.\n",
			opt.options);
		return;
	}
	auto file1 = File(args[1]);
	auto file2 = (args.length == 3 ? File(args[2]) : stdin);

	auto pdb1 = file1.parse(non)
		          .filter!(a => (non && a.isHeterogen) || a.name == "CA")
	                  .filter!(a => chains.canFind(a.chainID));
	auto pdb2  = file2.parse(non)
		          .filter!(a => (non && a.isHeterogen) || a.name == "CA")
	                  .filter!(a => chains.canFind(a.chainID));

	writefln("%+.3e", rmsd(pdb1, pdb2));
}
