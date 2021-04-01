#!/usr/bin/env dub
/+ dub.sdl:
	name        "split_pdb"
	targetType  "executable"
	targetPath  "../bin"
	targetName  "split_pdb"
	dependency "biophysics" version="*" path=".."
+/

/* Copyright (C) 2020 Andreas Füglistaler <andreas.fueglistaler@gmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module tools.split;

import biophysics.pdb;

auto splitByDist(Range)(lazy Range atoms, double dist) {
	import std.algorithm;
	import std.stdio;

	char[80] old;
	old.x           = 1e6;
	old.y           = 1e6;
	old.z           = 1e6;
	char chain      = 'A' - 1;
	char old_chain  = 'A' - 1;
	uint old_number = 0;

	return atoms.map!((atom) {
		immutable rs = atom.resSeq;       
		immutable ci = atom.chainID;
		if (rs != old_number) {
			if (old_chain != ci) {
				chain++;
				old_chain = ci;
			}
			else if (distance(atom, old) > dist) {
				chain++;
			}
			old_number = rs;
			old        = atom;
		}
		atom.chainID = chain;

		return atom;
	});
}

auto splitByRes(Range)(lazy Range atoms) {
	import std.algorithm;

	char chain      = 'A' - 1;
	char old_chain  = 'A' - 1;
	int  old_number = 0;

	return atoms.map!((atom) {
		immutable rs = atom.resSeq;
		immutable ci = atom.chainID;
		if (rs != old_number) {
			if (old_chain != ci) {
				chain++;
				old_chain = ci;
			}
			else if (rs - old_number > 1) {
				chain++;
			}
			old_number = rs;
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
	import std.algorithm;
	import std.array;

	bool non      = false;
	bool byres    = false;
	bool bydist   = false;
	bool perchain = false;

	auto opt = getopt(
		args,
		"hetatm|n", "Use non-standard residues", &non,
		"by_residue|r", "Split by residue-number break", &byres,
		"by_distance|d", "Split by distance cutoff", &bydist,
		"per_chain|p", "Output one pdb per chain", &perchain);

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
	immutable hasFile = args.length == 2;
	immutable fn      = (hasFile ? args[1] : "");
	auto file = (hasFile ? File(fn) : stdin);

	if (byres) {
		auto of = file.parse(non).splitByRes;
		if (!perchain) of.print;
		else of.print_chains(fn);
	    }
	else if (bydist) {
		auto of = file.parse(non).splitByDist(6.);
		if (!perchain) of.print;
		else of.print_chains(fn);
	}
	else {
		auto of = file.parse(non);
		if (!perchain) of.print;
		else of.print_chains(fn);
	}
}
