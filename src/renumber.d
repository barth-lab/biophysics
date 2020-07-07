#!/usr/bin/env rdmd

int resSeq(T)(T line)
{
	return line[23 .. 26].to!int;
}

void main(string[] args)
{
	import std.stdio;
	import std.algorithm;

	uint oldRes = 0;
	uint resSeq = 1;
	File(args[1])
		.byLine
		.filter!(l => l.length == 80 && (l.startsWith("ATOM")
						 || l.startsWith("TER")))
		.map!(l => (l.startsWith("TER")? "TER" : l))
		.each!writeln;
	writeln("END");
}
