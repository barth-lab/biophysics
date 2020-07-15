
module pdb;

import std.algorithm;
import std.conv;
import std.format;
import std.string;

auto parse(const ref string filename, bool heavy=false)
{
	import std.stdio;
	return File(filename).byLine.filter!(
	        l => hasLength(l)
		&& (isAtom(l) || (heavy && isHeavy(l))));
}

void print(Range)(Range atoms, bool renumberAtoms=false) {
	import std.stdio;

	char ch = atoms.front.chainID;

	int i = 1;
	foreach (a; atoms) {
		if (renumberAtoms) { a.serial = i++; }

		if (a.chainID != ch) {
			writeln("TER");
			ch = a.chainID;
		}
		writeln(a);
	}
	writeln("END");
}


bool hasLength(char[] l) { return l.length == 80; }
bool isAtom(char[] l) { return l[0 .. 4] == "ATOM"; }
bool isHeavy(char[] l) { return l[0 .. 6] == "HETATM"; }

alias Atom = char[];

int serial(Atom atom) { return atom[6 .. 11].strip.to!int; }
void serial(Atom atom, int value) { atom[6 .. 11] = format!"%5d"(value); }

char chainID(Atom atom) { return atom[21]; }
void chainID(Atom atom, char value) { atom[21] = value; }

char[] name(Atom atom) { return atom[12 .. 16].strip; }
void name(Atom atom, const char[] value)
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

unittest {
	char[80] buf;
	buf.serial = 123;
	buf.chainID = 'A';
	buf.name = "H";

	assert(buf.serial == 123);
	assert(buf.chainID == 'A');
	assert(buf.name == "H");
}
