/* Copyright (C) 2020 Andreas Füglistaler <andreas.fueglistaler@gmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module biophysics.pdb;

import std.algorithm;
import std.conv;
import std.format;
import std.string;
import std.stdio;

/// Parse a pbd-file, including hetatoms or not
auto parse(File file, bool heterogen=false) {
	bool function(Atom a) f =
	        (heterogen ? (l => l.hasLength && (l.isAtom || l.isHeterogen))
	                   : (l => l.hasLength && l.isAtom));
	return file.byLine.filter!f;
}

/// Print a pdb-file, including TER lines and END lines
void print(Range)(Range atoms, File file = stdout) {
	import std.stdio;
	import std.range;

	auto ai = atoms.front;
	char ch = ai.chainID;
	int  i  = 1;

	char[80] ter;
	ter.fill(' ');
	ter[0..6] = "TER   ";

	for(;;) {
		char chainID_i = ai.chainID;
		if (chainID_i != ch) {
			ch         = chainID_i;
			ter.serial = i++;
			file.writeln(ter);
		}
		ai.serial = i++;
		file.writeln(ai);
		
		ter[17 .. 27] = ai[17 .. 27];
		atoms.popFront;
		if (atoms.empty) {
			break;
		}
		ai = atoms.front;
	} 
	ter.serial = i;
	file.writeln(ter);
	file.writeln("END                                                                             ");
}

/// Print each chain to a pdb-file, including TER lines and END lines
void print_chains(Range)(Range atoms, string filename) {
	import std.stdio;
	import std.range;

	auto ai = atoms.front;
	char ch = ai.chainID;
	int  i  = 1;

	char[80] ter;
	ter.fill(' ');
	ter[0..6] = "TER   ";

	filename = (filename.empty
	                    ? filename
	                    : filename.split(".")[0].split("/")[$ - 1] ~'_');
	File file = File(filename ~ ch ~ ".pdb", "w");

	for(;;) {
		char chainID_i = ai.chainID;
		if (chainID_i != ch) {
			ch         = chainID_i;
			ter.serial = i++;
			file.writeln(ter);
			file.writeln("END                                                                             ");
			file.close;
			file.open(filename ~ ch ~ ".pdb", "w");
		}
		ai.serial     = i++;
		ter[17 .. 27] = ai[17 .. 27];

		file.writeln(ai);
		
		atoms.popFront;
		if (atoms.empty) {
			break;
		}
		ai = atoms.front;
	} 
	ter.serial = i;
	file.writeln(ter);
	file.writeln("END                                                                             ");
}

/// TER line of pdb
string ter(Atom a) pure nothrow {
	char[80] t = a.dup;	
	t[0..6]    = "TER   ";
	t[11..17].fill(' ');
	t[27..$].fill(' ');
	return t.to!string;
}

/// Distance between two atoms
double distance(const Atom a1, const Atom a2) pure {
	import std.math;
	immutable dx = a1.x - a2.x;
	immutable dy = a1.y - a2.y;
	immutable dz = a1.z - a2.z;
	return sqrt(dx*dx + dy*dy + dz*dz);
}

/// Distance between two points
double distance(const double[3] c1, const double[3] c2) pure nothrow {
	import std.math;
	double[3] dc = c1[] - c2[];
	return sqrt(dc[0]*dc[0] + dc[1]*dc[1] + dc[2]*dc[2]);
}
unittest {
	import std.math;
	immutable double[3] c1 = [1, 1, 1];
	immutable double[3] c2 = [1, 2, 1];
	immutable double[3] c3 = [2, 2, 2];
	assert(distance(c1, c2).isClose(1.));
	assert(distance(c1, c3).isClose(sqrt(3.)));
}

/// Has an atom-line the correct length
bool hasLength(char[] l) pure nothrow { return l.length  == 80; }

/// Is it an ATOM-Record?
bool isAtom(char[] l) pure nothrow { return l[0 .. 4] == "ATOM"; }

/// Is it an HETATM-Record?
bool isHeterogen(char[] l) pure nothrow { return l[0 .. 6] == "HETATM"; }

/// Pseudo-Atom-type
alias Atom = char[];

uint serial(const Atom atom) pure { return atom[6 .. 11].stripLeft.to!uint; }
void serial(Atom atom, uint value) pure { atom[6 .. 11].sformat!"%5u"(value); }

string name(const Atom atom) pure { return atom[12 .. 16].strip.to!string; }
void name(Atom atom, string value) pure {
	import std.ascii;
	if (value.length >= 4) {
		atom[12 .. 16] = value[0 .. 4];
	}
	else if (value[0].isDigit ) {
		atom[12 .. 16].sformat!"%-4s"(value);
	}
	else {
		atom[12 .. 16].sformat!" %-3s"(value);
	}
}

char altLoc(const Atom atom) pure nothrow { return atom[16]; }
void altLoc(Atom atom, char value) pure nothrow { atom[16] = value; }

string resName(const Atom atom) pure { return atom[17 .. 20].to!string; }
void resName(Atom atom, string value) pure { atom[17 .. 20].sformat!"%3s"(value); }

char chainID(const Atom atom) pure nothrow { return atom[21]; }
void chainID(Atom atom, char value) pure { atom[21] = value; }

uint resSeq(const Atom atom) pure { return atom[22 .. 26].stripLeft.to!uint; }
void resSeq(Atom atom, uint value) pure { atom[22 .. 26].sformat!"%4u"(value); }

char iCode(const Atom atom) pure nothrow { return atom[26]; }
void iCode(Atom atom, char value) pure nothrow { atom[26] = value; }

double x(const Atom atom) pure { return atom[30 .. 38].stripLeft.to!double; }
void x(Atom atom, double value) { atom[30 .. 38].sformat!"%8.3f"(value); }
double y(const Atom atom) pure { return atom[38 .. 46].stripLeft.to!double; }
void y(Atom atom, double value) { atom[38 .. 46].sformat!"%8.3f"(value); }
double z(const Atom atom) pure { return atom[46 .. 54].stripLeft.to!double; }
void z(Atom atom, double value) { atom[46 .. 54].sformat!"%8.3f"(value); }

double occupancy(const Atom atom) pure { return atom[54 .. 60].stripLeft.to!double; }
void occupancy(Atom atom, double value) { atom[54 .. 60].sformat!"%6.2f"(value); }
double tempFactor(const Atom atom) pure { return atom[60 .. 66].stripLeft.to!double; }
void tempFactor(Atom atom, double value) { atom[60 .. 66].sformat!"%6.2f"(value); }

string element(const Atom atom) pure { return atom[76 .. 78].strip.to!string; }
void element(Atom atom, string value) pure { atom[76 .. 78].sformat!"%2s"(value); }

string charge(const Atom atom) pure { return atom[78 .. 80].strip.to!string; }
void charge(Atom atom, string value) pure { atom[78 .. 80].sformat!"%2s"(value); }

bool isH(const Atom atom) pure nothrow { return atom[13] == 'H';}

bool isO(const Atom atom) pure nothrow { return atom[13] == 'O';}

bool isN(const Atom atom) pure nothrow { return atom[13] == 'N';}

bool isC(const Atom atom) pure nothrow { return atom[13] == 'C';}

bool isNonPolar(const Atom atom) pure nothrow {
	immutable nonPolar = ["ALA", "CYS", "GLY", "ILE", "LEU",
			      "MET", "PHE", "PRO", "TRP", "VAL"];
	auto r = atom[17 .. 20];
	return nonPolar.canFind(r);
}

bool isBB(const Atom atom) pure nothrow {
	auto n = atom[12..16];
	return (n == " N  " || n == " C  " || n == " O  " || n == " CA ");
}

bool isCB(const Atom atom) pure nothrow { return atom[12 .. 16] == " CB ";}

bool isCA(const Atom atom) pure nothrow { return atom[12 .. 16] == " CA ";}

enum char[80] GLY =  "ATOM      1  CA  GLY A   1       0.000   0.000   0.000 -1.00  0.00           C  ";

///
unittest {
	char[80] buf = "ATOM      2  CA  PRO A  51     -36.257  41.614 -51.758  1.00150.96           C  ";

	assert(buf.serial == 2);
	assert(buf.name == "CA");
	assert(buf.altLoc == ' ');
	assert(buf.resName == "PRO");
	assert(buf.chainID == 'A');
	assert(buf.resSeq == 51);
	assert(buf.iCode == ' ');
	assert(buf.x == -36.257);
	assert(buf.y == 41.614);
	assert(buf.z == -51.758);
	assert(buf.occupancy == 1.);
	assert(buf.tempFactor == 150.96);
	assert(buf.element == "C");
	assert(buf.charge == "");

	buf.serial     = 12345;
	buf.name       = "N";
	buf.altLoc     = '.';
	buf.resName    = "PRO";
	buf.chainID    = 'B';
	buf.resSeq     = 1234;
	buf.iCode      = '.';
	buf.x          = 1;
	buf.y          = 2;
	buf.z          = 3;
	buf.occupancy  = 4;
	buf.tempFactor = 5;
	buf.element    = "N";
	buf.charge    = "+1";

	assert(buf.serial == 12345);
	assert(buf.name == "N");
	assert(buf.altLoc == '.');
	assert(buf.chainID == 'B');
	assert(buf.iCode == '.');
	assert(buf.x == 1.);
	assert(buf.y == 2.);
	assert(buf.z == 3.);
	assert(buf.occupancy == 4.);
	assert(buf.tempFactor == 5.);
	assert(buf.element == "N");
	assert(buf.charge == "+1");
}
