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

auto str2index(string s) {
	import std.array;
	import std.conv;

	int[] index;
	immutable csplits = s.split(',');
	foreach (csp; csplits) {
		immutable dsplits = csp.split('-');	
		if (dsplits.length == 1) index ~= dsplits[0].to!int;
		else {
			immutable from = dsplits[0].to!int;
			immutable to   = dsplits[1].to!int + 1;
			foreach (i; from .. to) index ~= i;
		}
	}
	return index;
}

immutable description=
"Extract chains and/or residues from PDB-FILE to standard output.";

immutable extra =	
"Declare chains as capital letters. For example to extract A, C and E use 
--chains ACE.
Declare chainIDs the same way.

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

	bool   non      = false;
	string ids      = "";
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

		"chainIDs|i",
		"Use CHAINIDS instead of the original one, default = CHAINS",
		&ids,

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
	if (ids.empty) ids=chains;

	immutable resSeqs = str2index(residues);
	auto      file    = (args.length == 2 ? File(args[1]) : stdin);

	auto as = file.parse(non)
		       .filter!(a => chains.canFind(a.chainID))
		       .filter!(a => resSeqs.canFind(a.resSeq))
		       .map!dup
		       .array;

	if (as.empty) return;

	chains.map!(c => as.filter!(a => a.chainID == c))
	      .joiner
	      .map!((a) {
		 a.chainID = cast(char)(ids[chains.indexOf(a.chainID)]);
		 return a;})
	      .print;
}
