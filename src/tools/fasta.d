#!/usr/bin/env rdmd

/* Copyright (C) 2020 Andreas Füglistaler <andreas.fueglistaler@gmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module tools.fasta;

immutable description=
"Print Sequence of PDB-FILE in FASTA format to standard output.";

immutable char[string] aminoAcids; 
shared static this() {
	aminoAcids = ["CYS": 'C', "ASP": 'D', "SER": 'S', "GLN": 'Q',
	              "LYS": 'K', "ILE": 'I', "PRO": 'P', "THR": 'T',
		      "PHE": 'F', "ASN": 'N', "GLY": 'G', "HIS": 'H',
		      "LEU": 'L', "ARG": 'R', "TRP": 'W', "ALA": 'A',
		      "VAL":'V', "GLU": 'E', "TYR": 'Y', "MET": 'M'];
}

string fasta(Range)(Range atoms, string fn) {
	import biophysics.pdb;
	import std.algorithm;
	import std.array;

	fn          = fn.split('/')[$ - 1].split(".pdb")[0];
	char chain  = atoms.front.chainID;
	string sout = '>' ~ fn ~ '_' ~ chain ~ '\n';
	int counter = 0;
	int resNum  = 0;

	foreach (a; atoms) {
		if (a.chainID != chain) {
			chain = a.chainID;
			counter = 0;
			sout ~= "\n>" ~ fn ~ '_' ~ chain ~ '\n';
		}
		if (counter >= 70) {
			sout   ~= '\n';
			counter = 0;
		}
		if (resNum == a.resSeq) continue;
		resNum = a.resSeq;

		if (auto aa1 = a.resName in aminoAcids) sout ~= *aa1;
		else sout ~= 'X';

		counter++;
	}
	return sout;
}

void main(string[] args) {
	import biophysics.pdb;
	import std.getopt;
	import std.stdio;

	bool non = false;
	auto opt = getopt(args, "hetatm|n",
			  "Use non-standard (HETATM) residues", &non);

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
	auto      file    = (hasFile ? File(fn) : stdin);
	file.parse(non).fasta(fn).writeln;
}
