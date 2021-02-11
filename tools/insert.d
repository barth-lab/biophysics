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

module tools.insert;

import biophysics.pdb;
import biophysics.fasta;

void print_fill(Range, StringOrChar)(Range atoms, StringOrChar res) {
	import std.stdio;
	import std.range;

	auto atom = atoms.front;
	char ch   = atom.chainID;
	int  ai   = 1;
	int  ri   = 0;
	char[80] old = atom;

	for(;;) {
		if (atom.resSeq != ri) {
			ri++;
		}
		while (ri < atom.resSeq) {
			static if (is (StringOrChar == string)) {
			    if (res[ri-1] == '-') {
				    ri++;
				    continue;
			    }
			}
			old.x = 0;
			old.y = 0;
			old.z = 0;
			old.occupancy  = -1;
			old.tempFactor = 0;
			foreach (a; ["N", "CA", "C", "O"]) {
				old.name = a;	
				static if (is (StringOrChar == string)) {
					old.resName = res[ri-1].aminoAcids;
				}
				else if (is (StringOrChar == char)) {
					old.resName = res.aminoAcids;
				}
				old.resSeq  = ri;
				old.serial  = ai++;
				old.element = a[0 .. 1];
				writefln("%-80s", old);
			}
			ri++;
		} 
		if (atom.chainID != ch) {
			ch         = atom.chainID;
			old.serial = ai++;
			old[0..$].ter.writeln;
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

	static if (is (StringOrChar == string)) {
		while (ri < res.length) {
			ri++;
			old.x = 0;
			old.y = 0;
			old.z = 0;
			old.occupancy  = -1;
			old.tempFactor = 0;
			foreach (a; ["N", "CA", "C", "O"]) {
				old.name = a;	
				old.resName = res[ri-1].aminoAcids;
				old.resSeq  = ri;
				old.serial  = ai++;
				old.element = a[0 .. 1];
				writefln("%-80s", old);
			}
		}
	}
	old.serial = ai++;
	old[0..$].ter.writeln;
	writefln("%-80s", "END");
}

immutable description=
"Insert missing residues defined in FASTA-file or RESIDUE-type to PDB-FILE to standard output.";

void main(string[] args) {
	import std.getopt;
	import std.stdio;
	import std.algorithm;
	import std.string;

	bool   non     = false;
	string fastaFn = "";
	char   resType = 'G';

	auto opt = getopt(
		args,
		"hetatm|n",
		"Use non-standard (HETATM) residues",
		&non,

		"resType|r",
		"RESIDUE-type to use",
		&resType,

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
	auto pdb = (args.length == 2 ? File(args[1]) : stdin).parse(non);

	if (fastaFn.empty) {
		pdb.print_fill(resType);
	}
	else {
		auto fasta = File(fastaFn).fasta;
		string res = "";
		foreach (ch; fasta) {
			res ~= ch.seq;
		}
		pdb.print_fill(res);
	}
}
