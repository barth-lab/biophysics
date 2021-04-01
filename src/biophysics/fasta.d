/* Copyright (C) 2020 Andreas Füglistaler <andreas.fueglistaler@gmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module biophysics.fasta;

import std.stdio;
import std.typecons;

alias Chain = Tuple!(string, "name", string, "seq");
alias Fasta = Chain[];


char aminoAcids(string threeLetter) {
	immutable aminoAcids = ["ALA": 'A', "ARG": 'R', "ASN": 'N', "ASP": 'D',
				"CYS": 'C', "GLN": 'Q', "GLU": 'E', "GLY": 'G',
				"HIS": 'H', "ILE": 'I', "LEU": 'L', "LYS": 'K',
				"MET": 'M', "PHE": 'F', "PRO": 'P', "SER": 'S',
				"THR": 'T', "TRP": 'W', "TYR": 'Y', "VAL":'V'];
	if (auto aa = threeLetter in aminoAcids) return *aa;
	return 'X';
}

string aminoAcids(char oneLetter) {
	immutable aminoAcids = ['A': "ALA", 'C': "CYS", 'D': "ASP", 'E': "GLU",
				'F': "PHE", 'G': "GLY", 'H': "HIS", 'I': "ILE",
				'K': "LYS", 'L': "LEU", 'M': "MET", 'N': "ASN",
				'P': "PRO", 'Q': "GLN", 'R': "ARG", 'S': "SER",
				'T': "THR", 'V': "VAL", 'W': "TRP", 'Y': "TYR"];
	if (auto aa = oneLetter in aminoAcids) return *aa;
	return "X00";
}

Fasta fasta(Range)(Range atoms, bool showGaps) {
	import biophysics.pdb;
	import std.algorithm;
	import std.array;
	import std.conv;

	Fasta chains;
	char ch = atoms.front.chainID;
	chains ~= Chain(ch.to!string, "");
	int resNum = 0;

	foreach (a; atoms) {
		if (resNum == a.resSeq) continue;
		if (a.chainID != ch) {
			ch = a.chainID;
			chains ~= Chain(ch.to!string, "");
		}
		resNum = (showGaps ? resNum + 1 : a.resSeq);
		while (showGaps && resNum < a.resSeq) {
			chains[$ - 1].seq ~= '-';
			resNum++;
		}
		chains[$ - 1].seq ~= aminoAcids(a.resName);
	}
	return chains;
}

Fasta fasta(File file) {
	import std.algorithm;
	import std.string;
	import std.conv;
	Fasta chains;
	string ch = void;
	foreach (l; file.byLine) {
		if (l.startsWith('>')) {
			ch = l[1 .. $].strip.to!string;
			chains ~= Chain(ch, "");
		}
		else {
			chains[$ - 1].seq ~= l.strip;
		}
	}
	return chains;
}

void print(Fasta fasta, string name) {
	import std.algorithm;
	import std.string;
	if (!name.empty) name ~= "_";

	foreach (ch; fasta) {
		writeln('>', name, ch.name);
		auto s = ch.seq;
		while (s.length > 70) {
			s[0 .. 70].writeln;
			s = s[70 .. $];
		}
		s.writeln;
	}
}
