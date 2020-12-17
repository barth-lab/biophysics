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
	import std.conv;

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
	foreach (char ch; fasta.keys.representation.sort) {
		res ~= fasta[ch];
	}
	int [] rnums;

	foreach (i, r; res.enumerate) {
		if (r == '-') rnums ~= cast(int) i+1;
	}
	if (rnums.empty) return;

	int iLast = rnums[0];
	int i_1   = rnums[0];
	string sout = iLast.to!string;
	foreach (i; rnums[1 .. $]) {
		if (i - i_1== 1) {
			i_1= i;	
		}
		else {
			if (i_1 != iLast) {
				sout ~= '-' ~ i_1.to!string;
			}		
			sout ~= ',' ~ i.to!string;
			iLast = i;
			i_1   = i;
		}
	}
	if (i_1 != iLast) {
		sout ~= '-' ~ i_1.to!string;
	}		
	sout.writeln;
}
