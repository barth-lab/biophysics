
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

void print(Range)(Range lines) {
	import std.stdio;

	char ch = lines.front.chainID;

	foreach (l; lines) {
		if (l.chainID != ch) {
			writeln("TER");
			ch = l.chain;
		}
		writeln(l);
	}
	writeln("END");
}

bool hasLength(char[] l) { return l.length == 80; }
bool isAtom(char[] l) { return l[0 .. 4] == "ATOM"; }
bool isHeavy(char[] l) { return l[0 .. 6] == "HETATM"; }

int serial(char[] line) { return line[6 .. 11].strip.to!int; }
void serial(char[] line, int value) { line[6 .. 11] = format!"%5d"(value); }

unittest {
	char[80] buf;
	buf.serial = 123;
	assert(buf.serial == 123);
}

char chainID(char[] line) { return line[21]; }
void chainID(char[] line, char value) { line[21] = value; }

unittest {
	char[80] buf;
	buf.chainID = 'A';
	assert(buf.chainID == 'A');
}
