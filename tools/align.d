#!/usr/bin/env dub
/+ dub.sdl:
	name        "align"
	targetType  "executable"
	targetPath  "../bin"
	targetName  "align"
	dependency "biophysics" version="*" path=".."
	dependency "lubeck" version="~>1.1"
+/

/* Copyright (C) 2020 Andreas Füglistaler <andreas.fueglistaler@gmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module tools.alignPDB;

import std.algorithm;
import biophysics.pdb;

auto alignPDB(R1, R2)(R1 atoms, R2 to) {
	import std.range;
	import mir.ndslice;
	import kaleidic.lubeck;

	auto all = atoms.map!dup.array;

	auto com = [0., 0., 0.].sliced;
	double[] raw;

	foreach (a; all.filter!(a => a.isCA)) {
		immutable x = a.x;
		immutable y = a.y;
		immutable z = a.z;
		raw   ~= [x, y, z];
		com[] += [x, y, z];
	}
	auto crds = raw.sliced(raw.length/3, 3);
	com[]    /= crds.length;
	crds[]   -= com;

	auto comTo = [0., 0., 0.].sliced;
	double[] rawTo;
	foreach (a; to.filter!(a => a.isCA)) {
		immutable x = a.x;
		immutable y = a.y;
		immutable z = a.z;
		rawTo   ~= [x, y, z];
		comTo[] += [x, y, z];
	}
	auto crdsTo = rawTo.sliced(raw.length/3, 3);
	comTo[]    /= crdsTo.length;
	crdsTo[]   -= comTo;

	auto cov = mtimes(crdsTo.transposed, crds);
	auto s   = svd(cov);  
	auto rot = mtimes(s.u, s.vt);	
	foreach (a; all) {
		auto v = [a.x - com[0], a.y - com[1], a.z - com[2]].sliced;
		auto vnew = mtimes(rot, v);
		a.x = vnew[0] + comTo[0];
		a.y = vnew[1] + comTo[1];
		a.z = vnew[2] + comTo[2];
		
	}
	return all;
}

immutable description=
"Align PDB-FILE to PDB-file TO to standard output.";

void main(string[] args) {
	import std.getopt;
	import std.stdio;

	bool   non    = false;
	string chains = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	string to     = "";

	auto opt = getopt(
		args,
		"hetatm|n",
		"Use non-standard (HETATM) residues",
		&non,

		"to|t",
		"PDB-file to align to",
		&to);

	if (args.length > 2 || args.length == 0 || opt.helpWanted) {
		defaultGetoptPrinter(
			"Usage: " ~ args[0]
			~ " [OPTIONS]... FILE\n"
			~ description
			~ "\n\nWith no FILE, or when FILE is --,"
			~ " read standard input.\n",
			opt.options);
		return;
	}
	auto file   = (args.length == 2 ? File(args[1]) : stdin);
	auto fileTo = File(to).parse(non);
	file.parse(non).alignPDB(fileTo).print;
}
