#!/usr/bin/env dub
/+ dub.sdl:
	name        "fasta"
	targetType  "executable"
	targetPath  "../bin"
	targetName  "fasta"
	dependency "biophysics" version="*" path=".."
+/

/* Copyright (C) 2020 Andreas Füglistaler <andreas.fueglistaler@gmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module tools.fasta;

immutable description=
"Print Sequence of PDB-FILE in FASTA format to standard output.";

void main(string[] args) {
	import biophysics.pdb;
	import biophysics.fasta;
	import std.getopt;
	import std.stdio;
	import std.string;

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
	immutable hasFile = args.length == 2;
	immutable name    = (hasFile ? args[1].split('/')[$ - 1].split(".pdb")[0] : "");
	auto      file    = (hasFile ? File(args[1]) : stdin);
	file.parse(non).fasta(showGaps).print(name);
}
