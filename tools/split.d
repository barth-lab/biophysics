#!/usr/bin/env dub
/+ dub.sdl:
	name        "split"
	targetType  "executable"
	targetPath  "../bin"
	targetName  "split"
	dependency "biophysics" version="*" path=".."
+/

/* Copyright (C) 2020 Andreas Füglistaler <andreas.fueglistaler@gmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module tools.split;

import biophysics.pdb;

auto splitChains(Range)(lazy Range atoms, double dist) {
	import std.algorithm;

	char[80] old;
	old.x = 1e6;
	old.y = 1e6;
	old.z = 1e6;
	char chain = 'A' - 1;
	uint old_number = 0;

	return atoms.map!((atom) {
		immutable rs = atom.resSeq;       
		if (rs != old_number) {
			if (distance(atom, old) > dist) chain++;

			old_number = rs;
			old        = atom;
		}
		atom.chainID = chain;

		return atom;
	});
}

auto splitChains(Range)(lazy Range atoms) {
	import std.algorithm;

	char[80] old;
	old.x = 1e6;
	old.y = 1e6;
	old.z = 1e6;
	char chain = 'A' - 1;
	int old_number = -1;

	return atoms.map!((atom) {
		immutable rs = atom.resSeq;       
		if (rs != old_number) {
			if (rs - old_number > 1) chain++;

			old_number = rs;
			old        = atom;
		}
		atom.chainID = chain;

		return atom;
	});
}

immutable description=
"Split chains from PDB-FILE and write to standard output.";

void main(string[] args) {
	import std.getopt;
	import std.stdio;

	bool non   = false;
	bool byres = false;

	auto opt = getopt(
		args,
		"hetatm|n", "Use non-standard residues", &non,
		"by_residue|r", "Split by residue-number break", &byres);

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

	if (byres) {
		file.parse(non)
		    .splitChains
		    .print;

	    }
	else {
		file.parse(non)
		    .splitChains(4.)
		    .print;
	}

}
