#!/usr/bin/env rdmd

import std.stdio;
import std.algorithm;

auto pdb_in(const ref string filename)
{
	return File(filename)
		.byLine.filter!(l => l.length == 80 && l.startsWith("ATOM"));
}

void pdb_out(Range)(Range lines) {
	char ch = lines.front.chain;

	foreach (l; lines) {
		if (l.chain != ch) {
			writeln("TER");
			ch = l.chain;
		}
		writeln(l);
	}
	writeln("END");
}

char chain(char[] line) { return line[21]; }
void chain(char[] line, char value) { line[21] = value; }

void main(string[] args)
{
	import std.algorithm;

	pdb_in(args[1]).pdb_out;
}
