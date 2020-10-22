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

auto parse(File file, bool heterogen=false) {
	return file.byLine.filter!( l =>
		l.hasLength && (l.isAtom || (heterogen && l.isHeterogen)));
}

void print(Range)(Range atoms) {
	import std.stdio;
	import std.range;

	auto ai = atoms.front;
	char ch = ai.chainID;
	int  i  = 1;
	char[80] old;

	for(;;) {
		if (ai.chainID != ch) {
			ch         = ai.chainID;
			old.serial = i++;
			old[0..$].ter.writeln;
		}
		ai.serial = i++;
		old       = ai;

		writefln("%-80s", ai);
		
		atoms.popFront;
		if (atoms.empty) {
			break;
		}
		ai = atoms.front;
	} 

	old.serial = i++;
	old[0..$].ter.writeln;
	writefln("%-80s", "END");
}

string ter(Atom a) {
	char[80] t = a;	
	t[0..6]    = "TER   ";
	t[11..17].fill(' ');
	t[27..$].fill(' ');
	return t.to!string;
}

double distance(const Atom a1, const Atom a2) {
	import std.math;
	immutable dx = a1.x - a2.x;
	immutable dy = a1.y - a2.y;
	immutable dz = a1.z - a2.z;
	return sqrt(dx*dx + dy*dy + dz*dz);
}

double distance(const double[3] c1, const double[3] c2) {
	import std.math;
	double[3] dc = c1[] - c2[];

	return sqrt(dc[0]*dc[0] + dc[1]*dc[1] + dc[2]*dc[2]);
}


bool hasLength(char[] l) { return l.length  == 80; }
bool isAtom(char[] l)    { return l[0 .. 4] == "ATOM"; }
bool isHeterogen(char[] l)   { return l[0 .. 6] == "HETATM"; }

alias Atom = char[];

uint serial(const Atom atom) { return atom[6 .. 11].strip.to!uint; }
void serial(Atom atom, uint value) { atom[6 .. 11] = value.format!"%5u"; }

string name(const Atom atom) { return atom[12 .. 16].strip.to!string; }
void name(Atom atom, string value)
{
	import std.ascii;
	if (value.length >= 4) {
		atom[12 .. 16] = value[0 .. 4];
	}
	else if (value[0].isDigit ) {
		atom[12 .. 16] = format!"%-4s"(value);
	}
	else {
		
		atom[12 .. 16] = format!" %-3s"(value);
	}
}

char altLoc(const Atom atom) { return atom[16]; }
void altLoc(Atom atom, char value) { atom[16] = value; }

string resName(const Atom atom) { return atom[17 .. 20].to!string; }
void resName(Atom atom, string value){ atom[17 .. 20] = value.format!"%3s"; }

char chainID(const Atom atom) { return atom[21]; }
void chainID(Atom atom, char value) { atom[21] = value; }

uint resSeq(const Atom atom) { return atom[22 .. 26].strip.to!uint; }
void resSeq(Atom atom, uint value) { atom[22 .. 26] = value.format!"%4u"; }

char iCode(const Atom atom) { return atom[26]; }
void iCode(Atom atom, char value) { atom[26] = value; }

double x(const Atom atom) { return atom[30 .. 38].strip.to!double; }
void x(Atom atom, double value) { atom[30 .. 38] = value.format!"%8.3f"; }
double y(const Atom atom) { return atom[38 .. 46].strip.to!double; }
void y(Atom atom, double value) { atom[38 .. 46] = value.format!"%8.3f"; }
double z(const Atom atom) { return atom[46 .. 54].strip.to!double; }
void z(Atom atom, double value) { atom[46 .. 54] = value.format!"%8.3f"; }

double occupancy(const Atom atom) { return atom[54 .. 60].strip.to!double; }
void occupancy(Atom atom, double value) { atom[54 .. 60] = value.format!"%6.2f"; }
double tempFactor(const Atom atom) { return atom[60 .. 66].strip.to!double; }
void tempFactor(Atom atom, double value) { atom[60 .. 66] = value.format!"%6.2f"; }

string element(const Atom atom) { return atom[76 .. 78].strip.to!string; }
void element(Atom atom, string value){ atom[76 .. 78] = value.format!"%2s"; }

string charge(const Atom atom) { return atom[78 .. 80].strip.to!string; }
void charge(Atom atom, string value){ atom[78 .. 80] = value.format!"%2s"; }

bool isH(const Atom atom) { return atom[13] == 'H';}

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
