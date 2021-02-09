#!/usr/bin/env dub
/+ dub.sdl:
	name        "extract"
	targetType  "executable"
	targetPath  "../bin"
	targetName  "extract"
	dependency "biophysics" version="*" path=".."
+/

/* Copyright (C) 2020 Andreas Füglistaler <andreas.fueglistaler@gmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module tools.extract;

immutable description=
"Extract chains and/or residues from PDB-FILE to standard output.";

immutable extra =	
"Declare chains as capital letters. For example to extract A, C and E use 
--chains ACE. 

You can change the order of chains by --chains BA, printing first chain B and 
then chain A. Best use together with renumber.

Declare residues as numbers, seperated by '-' and ','. For example, to
extract residues 1 to 10, 13 and 15 to 20, use
--residues 1-10,13,15-20.";

void main(string[] args) {
	import std.getopt;
	import std.algorithm;
	import std.stdio;
	import std.array;
	import std.string;
	import biophysics.pdb;
	import biophysics.util;

	bool   non      = false;
	string chains   = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	string residues = "1-9999";

	auto opt = getopt(
		args,
		"hetatm|n",
		"Use non-standard (HETATM) residues",
		&non,

		"chains|c",
		"CHAINS to extract, default = ABC...",
		&chains,

		"residues|r",
		"residues to extract, default = 1-9999.",
		&residues);

	if (args.length > 2 || opt.helpWanted) {
		defaultGetoptPrinter(
			"Usage: " ~ args[0]
			~ " [OPTIONS]... [FILE]\n"
			~ description
			~ "\n\nWith no FILE, or when FILE is --,"
			~ " read standard input.\n",
			opt.options);
		writeln("\n" ~ extra);
		return;
	}

	immutable resSeqs  = str2index(residues);
	auto      file     = (args.length == 2 ? File(args[1]) : stdin);
	auto      atoms_in = file.parse(non)
	                         .filter !(a => resSeqs.canFind(a.resSeq))
	                         .map !dup.array;

	if (atoms_in.empty) return;

	chains.map!(c => atoms_in.filter!(a => a.chainID == c))
	      .joiner
	      .print;
}
