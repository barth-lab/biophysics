#!/usr/bin/env dub
/+ dub.sdl:
	name        "insert"
	targetType  "executable"
	targetPath  "../bin"
	targetName  "insert"
	dependency "biophysics" version="*" path=".."
+/

/* Copyright (C) 2020 Andreas Füglistaler <andreas.fueglistaler@gmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module tools.fasta;

import biophysics.pdb;

void print_fill(Range)(Range atoms, string res) {
	import std.stdio;
	import std.range;

	auto atom = atoms.front;

	char ch = atom.chainID;
	int  ai = 1;
	int  ri = 1;
	char[80] old;

	for(;;) {
		if (atom.chainID != ch) {
			ch         = atom.chainID;
			old.serial = ai++;
			old[0..$].ter.writeln;
		}
		if (atom.resSeq != ri) {
			ri++;
		}
		while (ri < atom.resSeq) {
			writeln("insert ", res[ri-1], ri, " here");
			ri++;
		} 
		atom.serial = ai++;
		old         = atom;

		writefln("%-80s", atom);
		
		atoms.popFront;
		if (atoms.empty) {
			break;
		}
		atom = atoms.front;
	} 

	old.serial = ai++;
	old[0..$].ter.writeln;
	writefln("%-80s", "END");
}

immutable description=
"Insert missing residues definen in FASA-file to PDB-FILE to standard output.";

void main(string[] args) {
	import biophysics.fasta;
	import std.getopt;
	import std.stdio;
	import std.algorithm;
	import std.string;

	bool   non     = false;
	string fastaFn = "";

	auto opt = getopt(
		args,
		"hetatm|n",
		"Use non-standard (HETATM) residues",
		&non,

		"FASTA-filename|f",
		"FASTA-file to use",
		&fastaFn);

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
	auto pdb   = (args.length == 2 ? File(args[1]) : stdin).parse(non);
	auto fasta = File(fastaFn).fasta;
	string res = "";

	foreach (char ch; fasta.keys.representation.sort) {
		res ~= fasta[ch];
	}
	pdb.print_fill(res);
}
