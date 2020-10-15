/* Copyright (C) 2020 Andreas Füglistaler <andreas.fueglistaler@gmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module biophysics.fasta;

immutable char[string] aminoAcids; 
shared static this() {
	aminoAcids = ["CYS": 'C', "ASP": 'D', "SER": 'S', "GLN": 'Q',
	              "LYS": 'K', "ILE": 'I', "PRO": 'P', "THR": 'T',
		      "PHE": 'F', "ASN": 'N', "GLY": 'G', "HIS": 'H',
		      "LEU": 'L', "ARG": 'R', "TRP": 'W', "ALA": 'A',
		      "VAL":'V', "GLU": 'E', "TYR": 'Y', "MET": 'M'];
}

string fasta(Range)(Range atoms, string fn, bool showGaps) {
	import biophysics.pdb;
	import std.algorithm;
	import std.array;

	fn          = fn.split('/')[$ - 1].split(".pdb")[0];
	char chain  = atoms.front.chainID;
	string sout = '>' ~ fn ~ '_' ~ chain ~ '\n';
	int counter = 0;
	int resNum  = 0;

	foreach (a; atoms) {
		if (resNum == a.resSeq) continue;
		if (a.chainID != chain) {
			chain = a.chainID;
			counter = 0;
			resNum  = 0;
			sout ~= "\n>" ~ fn ~ '_' ~ chain ~ '\n';
		}
		resNum = (showGaps ? resNum + 1 : a.resSeq);
		while (showGaps && resNum < a.resSeq) {
			sout ~= '-';
			resNum++;
			if (++counter >= 70) {
				sout   ~= '\n';
				counter = 0;
			}
		}
		if (auto aa = a.resName in aminoAcids) sout ~= *aa;
		else sout ~= 'X';
		if (++counter >= 70) {
			sout   ~= '\n';
			counter = 0;
		}
	}
	return sout;
}
