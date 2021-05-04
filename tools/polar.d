#!/usr/bin/env dub
/+ dub.sdl:
	name        "polar"
	targetType  "executable"
	targetPath  "../bin"
	targetName  "polar"
	dependency "biophysics" version="*" path=".."
+/


/* Copyright (C) 2020 Andreas Füglistaler <andreas.fueglistaler@gmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module tools.polar;

import biophysics.pdb;

int[string] countPolarContacts(R1, R2)(R1 from, R2 to, double cut_off) {
	import std.range;
	import std.format;
	import std.conv;
	import std.string;

	int[string] contacts;

	double[3][] coords2;
	int[] resSeq2;
	
	foreach (a; to) {
		if (a.isH || a.isC) continue;

		coords2  ~= [a.x, a.y, a.z];
		resSeq2  ~= a.resSeq;
	}
	foreach (a; from) {
		if (a.isNonPolar || a.isH || a.isBB || a.isC) continue;

		immutable key1 = format("%c%04d/%s", a.chainID, a.resSeq, a.name);
		contacts[key1] = 0;

		immutable double[3] c1 = [a.x, a.y, a.z];
		int resSkip            = 0;
		foreach (j; 0..coords2.length) {
			if (resSeq2[j] == resSkip) continue;

			immutable d = c1.distance(coords2[j]);
			if (d > cut_off + 15) {
				resSkip = resSeq2[j];
				continue;
			}
			if (d > cut_off) continue;
			contacts[key1]++;
			//break;
		}
	}
	return contacts;
}

immutable description=
"Find residue-contacts in PDB-FILE or between PDB-FILE1 and 2 to standard output.";

void main(string[] args) {
	import std.getopt;
	import std.algorithm;
	import std.stdio;
	import std.array;
	import biophysics.util;

	double cutoff   = 3.5;
	string residues = "1-9999";
	string chains   = "";

	auto opt = getopt(
		args,
		"chains|c",
		"contacts to this CHAINS, default = all",
		&chains,

		"residues|r",
		"Contact must include this residue, default = all",
		&residues,

		"cutoff-distance|d",
		"Contact cutoff-distance, default = 3.5A",
		&cutoff);

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

	auto file = (args.length == 2 ? File(args[1]) : stdin);
	auto pdb  = file.parse.map!(dup).array;
	auto r    = pdb.filter!(a => !chains.canFind(a.chainID));
	auto c    = pdb.filter!(a => chains.canFind(a.chainID));
	auto cs   = countPolarContacts(c, r, cutoff);

	foreach (k; cs.keys.sort) {
		writefln("%-10s %2d", k, cs[k]);
	}
}