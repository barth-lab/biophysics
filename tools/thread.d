#!/usr/bin/env dub
/+ dub.sdl:
	name        "thread"
	targetType  "executable"
	targetPath  "../bin"
	targetName  "thread"
	dependency "biophysics" version="*" path=".."
+/

/* Copyright (C) 2020 Andreas Füglistaler <andreas.fueglistaler@gmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module tools.thread;

immutable description=
"Thread alignment in FASTA format onto PDB-file to standard output.";

void main(string[] args) {
	import biophysics.pdb;
	import biophysics.fasta;
	import std.getopt;
	import std.stdio;
	import std.string;

	bool   non     = false;
	bool   rm      = false;
	string fastaFn = "";

	auto opt = getopt(
		args,
		"hetatm|n",
		"Use non-standard (HETATM) residues",
		&non,

		"fasta|f",
		"alignement FASTA-file to use",
		&fastaFn,

		"remove|r",
		"Remove missing residues",
		&rm);

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

	auto pdb  = (args.length == 2 ? File(args[1]) : stdin).parse(non);
	auto atom = pdb.front;

	char[80] ter   = atom;
	char[80] empty = GLY;

	auto fasta  = File(fastaFn).fasta;
	auto target = fasta[0].seq;
	auto templ  = fasta[1].seq;
	int i_tem   = 1;
	int i_tar   = 1;
	int i_atom  = 1;
	outer: foreach (i; 0 .. target.length) {
		if (target[i] == '-' ) {
			if (!(templ[i] == '-')) ++i_tem;
		}	
		else if (templ[i] == '-') {
			if (!rm) {
			    empty.resName = target[i].aminoAcids;	

			    foreach (a; ["N", "CA", "C", "O"]) {
				    empty.name    = a;	
				    empty.resSeq  = i_tar;
				    empty.serial  = i_atom++;
				    empty.element = a[0 .. 1];
				    writefln("%-80s", empty);
			    }
			}
			++i_tar;
		}
		else {
			while (i_tem > atom.resSeq) {
				pdb.popFront;
				if (pdb.empty) {
					break outer;
				}
				atom = pdb.front;
			}
			while (i_tem == atom.resSeq) {
				if (target[i] == templ[i]) {	// same amino acid
					atom.resSeq  = i_tar;
					atom.serial  = i_atom++;
					atom.chainID = 'A';
					writefln("%-80s", atom);
				}
				else if (atom.isBB
				    || ((target[i] != 'G') && atom.isCB)) {
					// different amino acid
					atom.resName = target[i].aminoAcids;	
					atom.resSeq  = i_tar;
					atom.serial  = i_atom++;
					atom.chainID = 'A';
					writefln("%-80s", atom);
				}

				pdb.popFront;
				if (pdb.empty) {
					break outer;
				}
				atom = pdb.front;
			}
			++i_tar;
			++i_tem;	
		}
	}
	ter.serial  = i_atom;
	ter.chainID = 'A';
	ter.resSeq  = i_tar;
	ter[0..$].ter.writeln;
	writefln("%-80s", "END");
}
