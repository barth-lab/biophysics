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

	double[string] contacts;
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
		immutable key1    =  format("%c%04d",a1.chainID, a1.resSeq);
		int       resSkip = 0;
		foreach (j; 0 .. coords2.length) {
			if (resSeq2[j] == resSkip) continue;

			immutable d = c1.distance(coords2[j]);
			if (d > cut_off + 15) resSkip = resSeq2[j];
			if (d > cut_off) continue;
			immutable key = format("%s-%c%04d", key1, chain2[j],
			                       resSeq2[j]);
			auto dh = contacts.require(key, d);
			if (dh > d) contacts[key] = d;
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
	double cutoff = 4.;

	auto opt = getopt(
		args,
		"hetatm|n",
		"Use non-standard (HETATM) residues",
		&non,

		"cutoff|c",
		"Contact cutoff, default = 4A",
		&cutoff);

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

	auto pdb1 = file1.parse(non).filter!(a => !a.isH);
	auto pdb2 = file2.parse(non).filter!(a => !a.isH);

	auto cs = contacts(pdb1, pdb2, cutoff);

	foreach (k, v; cs) {
		writefln("%s: %5.2f", k, v);
	}
}
