#!/usr/bin/env dub
/+ dub.sdl:
	name        "contacts"
	targetType  "executable"
	targetPath  "../bin"
	targetName  "contacts"
	dependency "biophysics" version="*" path=".."
+/

/* Copyright (C) 2020 Andreas Füglistaler <andreas.fueglistaler@gmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module tools.contacts;

import biophysics.pdb;

auto contacts(R1, R2)(R1 atoms1, R2 atoms2, double cut_off) {
	import std.range;
	import std.format;
	import std.conv;
	import std.string;
	string[] contacts;

	double[3][] coords2;
	int[] resSeq2;
	char[] chain2;
	
	foreach (a2; atoms2) {
		coords2 ~= [a2.x, a2.y, a2.z];
		resSeq2 ~= a2.resSeq;
		chain2  ~= a2.chainID;
	}

	foreach (a1; atoms1) {
		immutable double[3] c1 = [a1.x, a1.y, a1.z];
		immutable ch1 = a1.chainID;
		immutable resSeq1 = a1[22 .. 26].strip.to!string;
		int resSeq = 0;
		foreach (j; 0 .. coords2.length) {
			if (resSeq2[j] == resSeq) continue;

			immutable d = c1.distance(coords2[j]);
			if (d > cut_off + 15) resSeq = resSeq2[j];
			if (d > cut_off) continue;
			contacts ~= ch1
				~ resSeq1
				~ "-"
				~ chain2[j]
				~ resSeq2[j].to!string
				~ ": "
				~ d.format!"%4.1f";
		}
	}
	return contacts;
}

immutable description=
"Find residue-contacts in PDB-FILE between two chains to standard output.";

void main(string[] args) {
	import std.getopt;
	import std.algorithm;
	import std.stdio;
	import std.array;

	bool   non    = false;
	char   ch1    = 'A';
	char   ch2    = 'B';
	double cutoff = 4.;

	auto opt = getopt(
		args,
		"hetatm|n",
		"Use non-standard (HETATM) residues",
		&non,

		"cutoff|c",
		"Contact cutoff, default = 4A",
		&cutoff,

		"chain1|1",
		"First chain to calculate contact",
		&ch1,

		"chain2|2",
		"Second chain to calculate contact",
		&ch2);

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
	auto pdb  = file.parse(non)
	                .filter!(a => a.chainID == ch1 || a.chainID == ch2)
	                .filter!(a => !a.isH)
	                .map!dup
	                .array;
	auto chain1 = pdb.filter!(a => a.chainID == ch1);
	auto chain2 = pdb.filter!(a => a.chainID == ch2);
	contacts(chain1, chain2, cutoff).each!writeln;
}
