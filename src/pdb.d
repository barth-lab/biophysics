
module pdb;

import std.algorithm;
import std.conv;
import std.format;
import std.string;

auto parse(const ref string filename, bool heavy=false)
{
	import std.stdio;
	return File(filename).byLine
		.filter!( l => l.hasLength && l.isAtom || (heavy && l.isHeavy));
}

void print(Range)(Range atoms, bool renumberAtoms=true) {
	import std.stdio;
	import std.range;
	char ch = atoms.front.chainID;
	//int  i  = 1;
	foreach (i, a; atoms.enumerate(1)) {
		if (renumberAtoms) { a.serial = i; }

		if (a.chainID != ch) {
			writefln("%-80s", "TER");
			ch = a.chainID;
		}
		writefln("%-80s", a);
	}
	writefln("%-80s", "END");
}

bool hasLength(char[] l) { return l.length == 80; }
bool isAtom(char[] l) { return l[0 .. 4] == "ATOM"; }
bool isHeavy(char[] l) { return l[0 .. 6] == "HETATM"; }

alias Atom = char[];

int serial(const Atom atom) { return atom[6 .. 11].strip.to!int; }
void serial(Atom atom, int value) { atom[6 .. 11] = value.format!"%5d"; }

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

int resSeq(const Atom atom) { return atom[22 .. 26].strip.to!int; }
void resSeq(Atom atom, int value) { atom[22 .. 26] = value.format!"%5d"; }

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

unittest {
	char[80] buf = "ATOM      2  CA  PRO A  51     -36.257  41.614 -51.758  1.00150.96           C  ";

	assert(buf.serial == 2);
	assert(buf.name == "CA");
	assert(buf.altLoc == ' ');
	assert(buf.chainID == 'A');
	assert(buf.resName == "PRO");
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
	buf.chainID    = 'B';
	buf.altLoc     = '.';
	buf.resName    = "PRO";
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
