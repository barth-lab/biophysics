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

int[] within(R1, R2)(R1 from, R2 to, double dist) {
	int[] rnums;
	double[3][] coords2;
	int[] resSeq2;
	
	foreach (a; to) {
		if ((a.isAtom && !a.isCA) || a.isH) continue;
		coords2  ~= [a.x, a.y, a.z];
		resSeq2  ~= a.resSeq;
	}
	foreach (a; from) {
		if (!a.isCA) continue;

		immutable double[3] crd = [a.x, a.y, a.z];
		foreach (j; 0..coords2.length) {
			immutable d = distance(crd, coords2[j]);
			if (d < dist) {
				rnums ~= a.resSeq;
				break;
			}
		}
	}
	return rnums;
}

immutable description=
"List all atoms of PDB-FILE within DISTANCE of CHAINs to standard output.";

void main(string[] args) {
	import std.getopt;
	import std.algorithm;
	import std.stdio;
	import std.array;
	import biophysics.util;

	bool   non    = false;
	double dist   = 15;
	string chains = "";
	bool   list   = false;

	auto opt = getopt(
		args,

		"hetatm|n", "Use non-standard (HETATM) residues", &non,

		"chains|c",
		"contacts to this CHAINS, default = all",
		&chains,

		"list|l",
		"list all contacts, default = all",
		&list,

		"distance|d",
		"Contact cutoff-distance, default = 15A",
		&dist);

	if (args.length > 2 || args.length == 0 || opt.helpWanted) {
		defaultGetoptPrinter(
			"Usage: " ~ args[0]
			~ " [OPTIONS]... FILE -c CHAINS\n"
			~ description
			~ "\n\nWith no FILE2, or when FILE2 is --,"
			~ " read standard input.\n",
			opt.options);
		return;
	}

	auto file = (args.length == 2 ? File(args[1]) : stdin);
	auto pdb  = file.parse(non).map!(dup).array;
	auto from = pdb.filter!(a => !chains.canFind(a.chainID));
	auto to   = pdb.filter!(a => chains.canFind(a.chainID));
	auto res  = within(from, to, dist);

	res.index2str.writeln;
}
