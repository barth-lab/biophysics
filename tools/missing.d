#!/usr/bin/env dub
/+ dub.sdl:
	name        "missing"
	targetType  "executable"
	targetPath  "../bin"
	targetName  "missing"
	dependency "biophysics" version="*" path=".."
+/

/* Copyright (C) 2020 Andreas Füglistaler <andreas.fueglistaler@gmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module tools.fasta;

immutable description=
"Print all missing residues of FASTA file to standard output.";

void main(string[] args) {
	import biophysics.pdb;
	import biophysics.fasta;
	import std.getopt;
	import std.stdio;
	import std.string;
	import std.algorithm;
	import std.range;
	import biophysics.util;

	bool non      = false;
	bool showGaps = false;

	auto opt = getopt(
		args,
		"hetatm|n",
		"Use non-standard (HETATM) residues",
		&non,

		"show_gaps|s",
		"Indicate SeqNum jumps by '-'",
		&showGaps);

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
	auto file  = (args.length == 2 ? File(args[1]) : stdin);
	auto fasta = file.fasta;
	string res = "";
	foreach (ch; fasta) {
		res ~= ch.seq;
	}
	int [] rnums;

	foreach (i, r; res.enumerate) {
		if (r == '-') rnums ~= cast(int) i+1;
	}
	rnums.index2str.writeln;
}
