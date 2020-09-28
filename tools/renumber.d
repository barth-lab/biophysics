#!/usr/bin/env dub
/+ dub.sdl:
	name        "renumber"
	targetType  "executable"
	targetPath  "../bin"
	targetName  "renumber"
	dependency "biophysics" version="*" path=".."
+/

/* Copyright (C) 2020 Andreas Füglistaler <andreas.fueglistaler@gmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module tools.renumber;

import std.algorithm;
import biophysics.pdb;

auto renumber(Range)(Range atoms, uint start=1, bool rechain=false) {
	uint old_number = 0;
	char old_chain  = ' ';
	char chain      = 'A' - 1;
	start--;

	return atoms.map!((atom) {
		if (atom.resSeq != old_number) {
			old_number = atom.resSeq;
			start++;
		}
		if (rechain && (atom.chainID != old_chain)) {
			old_chain = atom.chainID;
			chain++;	
		}
		if (rechain) atom.chainID = chain;

		atom.resSeq = start;
		return atom;
	});
}

immutable description=
"Renumber residues from PDB-FILE, starting at start, to standard output.";

void main(string[] args) {
	import std.getopt;
	import std.stdio;

	bool non     = false;
	uint start   = 1;
	bool rechain =false;
	auto opt     = getopt(
		args,
		"hetatm|n", "Use non-standard (HETATM) residues", &non,
		"rechain|c", "Renumber chains A through Z", &rechain,
		"start|s", "Start at this value", &start);

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
	file.parse(non).renumber(start, rechain).print;
}
