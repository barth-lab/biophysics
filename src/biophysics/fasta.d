/* Copyright (C) 2020 Andreas Füglistaler <andreas.fueglistaler@gmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module biophysics.fasta;

import std.stdio;

immutable char[string] aminoAcids; 
shared static this() {
	aminoAcids = ["CYS": 'C', "ASP": 'D', "SER": 'S', "GLN": 'Q',
	              "LYS": 'K', "ILE": 'I', "PRO": 'P', "THR": 'T',
		      "PHE": 'F', "ASN": 'N', "GLY": 'G', "HIS": 'H',
		      "LEU": 'L', "ARG": 'R', "TRP": 'W', "ALA": 'A',
		      "VAL":'V', "GLU": 'E', "TYR": 'Y', "MET": 'M'];
}

string[char] fasta(Range)(Range atoms, bool showGaps) {
	import biophysics.pdb;
	import std.algorithm;
	import std.array;

	string[char] chains;
	char ch    = atoms.front.chainID;
	chains[ch] = "";
	int resNum = 0;

	foreach (a; atoms) {
		if (resNum == a.resSeq) continue;
		if (a.chainID != ch) {
			ch     = a.chainID;
			resNum = 0;
			chains.require(ch, "");
		}
		resNum = (showGaps ? resNum + 1 : a.resSeq);
		while (showGaps && resNum < a.resSeq) {
			chains[ch] ~= '-';
			resNum++;
		}
		if (auto aa = a.resName in aminoAcids) chains[ch] ~= *aa;
		else chains[ch] ~= 'X';
	}
	return chains;
}

string[char] fasta(File file) {
	import std.algorithm;
	import std.string;
	string[char] chains;
	char ch = void;
	foreach (l; file.byLine) {
		if (l.startsWith('>')) {
			ch = l.strip[$ - 1];	
			chains[ch]   = "";
		}
		else {
			chains[ch] ~= l.strip;
		}
	}
	return chains;
}

void print(string[char] fasta, string name) {
	import std.algorithm;
	import std.string;
	if (!name.empty) name ~= "_";

	foreach (key; sort(cast(ubyte[])fasta.keys)) {
		writeln('>', name, cast(char)key);
		auto s = fasta[key];
		while (s.length > 70) {
			s[0 .. 70].writeln;
			s = s[70 .. $];
		}
		s.writeln;
	}
}
