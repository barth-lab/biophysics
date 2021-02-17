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

auto renumber(Range)(Range atoms, int start = 1, bool gaps = false,
                          bool rechain = false, string chains = "") {
	import std.range;
	import std.stdio;

	int  delta      = 0;
	int  old_number = start - 1;
	uint atom_i     = start - 1;
	char old_chain  = ' ';
	char chain      = 'A' - 1;
	int  chain_i    = -1;

	return atoms.map!((atom) {
		if (atom.chainID != old_chain) {
			old_chain = atom.chainID;

			if (gaps) {
				delta = atom.resSeq - (old_number - delta) - 1;
			}
			if (rechain) {
				chain++;
			}
			else if (chain_i < cast(int) chains.length - 1) {
				chain_i++;	
			}
		}
		if (atom.resSeq != old_number) {
			old_number = atom.resSeq;
			atom_i++;
		}
		if (rechain)            atom.chainID = chain;
		else if (!chains.empty) atom.chainID = chains[chain_i];

		atom.resSeq = (gaps ? atom.resSeq - delta : atom_i);
		return atom;
	});
}

immutable description=
"Renumber residues from PDB-FILE, starting at start, to standard output.";

void main(string[] args) {
	import std.getopt;
	import std.stdio;

	bool   non     = false;
	uint   start   = 1;
	bool   rechain = false;
	bool   gaps    = false;
	string chains  = "";

	auto opt = getopt(
		args,
		"hetatm|n", "Use non-standard (HETATM) residues", &non,
		"rechain|r", "Renumber chains A through Z", &rechain,
		"chains|c", "Use these chainID", &chains,
		"keep_gaps|k", "keep the gaps", &gaps,
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
	auto pdbs = file.parse(non);
	pdbs.renumber(start, gaps, rechain, chains).print;
	//else pdbs.renumber(start, rechain, chains).print;
}
