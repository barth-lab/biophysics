#!/usr/bin/env rdmd

void main(string[] args)
{
	import std.stdio;
	import std.algorithm;
	import std.array;
	File(args[1])
		.byLine
		.filter!(l => l.length == 80 && l.startsWith("ATOM"))
		.each!writeln;
	writeln("TER");
}
