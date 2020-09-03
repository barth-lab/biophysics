#!/usr/bin/env rdmd

void main(string[] args) {
	import std.getopt;
	import std.stdio;
	import std.range;
	import std.array;
	import std.uni;
	import std.conv;
	import std.algorithm;

	bool non = false;
	bool inv = false;
	auto opt = getopt(args,
			  "non_standard|n", "Use non-standard residues", &non,
			  "inverse|i", "Print residues outside spanning region", &inv);

	if (args.length > 2 || opt.helpWanted) {
		defaultGetoptPrinter("Usage of " ~ args[0] ~ ":", opt.options);
		return;
	}
	auto file = (args.length == 2 ? File(args[1]) : stdin);

	char[] o;
	if (!inv)
		foreach (i, l; file.byLine.enumerate) {
			if (i < 4) continue;	

			auto sp = l.splitter;
			o ~= sp.front ~ '-';
			sp.popFront;
			o ~= sp.front ~ ','; 
		}
	else {
		string start = "1";
		foreach (i, l; file.byLine.enumerate) {
			if (i < 4) continue;	

			auto sp = l.splitter;
			immutable stop = (sp.front.to!int - 1).to!string;
			o ~= start ~ '-' ~ stop ~ ','; 
			sp.popFront;
			start = (sp.front.to!int + 1).to!string;
		}
		o ~= start ~ "-9999,";
		
	}
	o[0 .. $-1].writeln;
}
