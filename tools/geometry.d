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

string geometry(Range)(Range atoms) {
	import std.math;
	import std.array;
	import std.range;
	import mir.ndslice;
	import kaleidic.lubeck;
	import mir.math.sum;
	import std.format;

	auto com = [0., 0., 0.].sliced;
	double[] raw;
	foreach (a; atoms.filter!(a => a.isCA)) {
		immutable x = a.x;
		immutable y = a.y;
		immutable z = a.z;
		raw   ~= [x, y, z];
		com[] += [x, y, z];
	}
	auto crds = raw.sliced(raw.length/3, 3);
	com[]    /= (crds.length);
	auto p  = crds.pca;
	auto w  = p.latent;
	auto v  = p.coeff.transposed;
	string s = "";
	s ~= format("%8.3f %8.3f %8.3f ",com[0], com[1], com[2]);
	s ~= format("%8.3f %8.3f %8.3f ",w[0], w[1], w[2]);
	foreach (i; 0 .. 3) {
		s ~= format("%8.3f %8.3f %8.3f ",v[i][0], v[i][1], v[i][2]);
	}
	return s;
}

immutable description=
"Print the geometric properties COM, eigenvalues and eigenvectors of PDB-FILE to standard output.";

void main(string[] args) {
	import std.getopt;
	import std.stdio;
	import std.math;

	bool   non    = false;
	bool   header = false;
	string chains = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	auto   opt    = getopt(
		args,
		"header|H", "print header", &header,
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
	if (header) {
		writefln("#%-7s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s %-8s", "com1", "com2", "com3", "w1", "w2", "w3", "v11", "v12", "v13", "v21", "v22", "v23", "v31", "v32", "v33");
	}

	auto file = (args.length == 2 ? File(args[1]) : stdin);
	file.parse(non).geometry.writeln;
}
