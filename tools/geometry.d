#!/usr/bin/env dub
/+ dub.sdl:
	name        "geometry"
	targetType  "executable"
	targetPath  "../bin"
	targetName  "geometry"
	dependency "biophysics" version="*" path=".."
	dependency "lubeck" version="~>1.1"
+/

/* Copyright (C) 2020 Andreas Füglistaler <andreas.fueglistaler@gmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module tools.pca;

import std.algorithm;
import biophysics.pdb;

auto geometry(Range)(Range atoms) {
	import std.math;
	import std.array;
	import std.range;
	import std.stdio;
	import mir.ndslice;
	import kaleidic.lubeck;
	import mir.math.sum;
	import std.typecons;

	auto com = [0., 0., 0.].sliced;
	double[] raw;
	foreach (a; atoms.filter!(a => a.isBB)) {
		immutable x = a.x;
		immutable y = a.y;
		immutable z = a.z;
		raw   ~= [x, y, z];
		com[] += [x, y, z];
	}
	auto crds = raw.sliced(raw.length/3, 3);
	com[]    /= (crds.length);
	auto p  = crds.pca;
	return tuple(com, p.latent, p.coeff.transposed);
}

immutable description=
"Rotate chains of PDB-FILE around three major axis and write to standard output.";

void main(string[] args) {
	import std.getopt;
	import std.stdio;
	import std.math;

	bool non = false;
	string chains = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	auto opt = getopt(
		args,
		"hetatm|n", "Use non-standard (HETATM) residues", &non,
		"chains|c", "Chains to rotate, default = all", &chains);

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
	auto file = (args.length == 2 ? File(args[1]) : stdin);
	auto g = file.parse(non).geometry;
	foreach (gi; g) 
		foreach (v; gi) 
			writef("%8.3f ", v);
	writeln();
}
