#!/usr/bin/env rdmd

void main(string[] args) {
	import std.getopt;
	import std.algorithm;
	import std.stdio;
	import std.array;
	import std.range;
	import pdb;

	bool non  = false;
	string ch = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	auto opt  = getopt(args,
			  "non_standard|n", "Use non-standard residued", &non,
			  "chains|c", "Chains to translate, default = all", &ch);

	if (args.length != 2 || opt.helpWanted) {
		defaultGetoptPrinter("Usage of " ~ __FILE__ ~ ":", opt.options);
		return;
	}

	auto a = pdb.parse(args[1], non)
		       .filter!(a => ch.canFind(a.chainID))
		       .map!dup
		       .array;

	ch.map!(c => a.filter!(a => a.chainID == c)).joiner.print;
}
