#!/usr/bin/env rdmd

void main(string[] args) {
	import std.getopt;
	import std.algorithm;
	import std.stdio;
	import std.array;
	import std.string;
	import pdb;

	bool   non     = false;
	bool   rechain = false;
	string chain   = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	auto opt       = getopt(args,
				"non_standard|n", "Use non-standard residued", &non,
				"rechain|r", "Renumber chains A through Z", &rechain,
				"chains|c", "Chains to translate, default = all", &chain);

	if (args.length != 2 || opt.helpWanted) {
		defaultGetoptPrinter("Usage of " ~ __FILE__ ~ ":", opt.options);
		return;
	}

	auto a = pdb.parse(args[1], non)
		       .filter!(a => chain.canFind(a.chainID))
		       .map!dup
		       .array;

	auto pout = chain.map!(c => a.filter!(a => a.chainID == c)).joiner;

	if (rechain) pout.map!((a) {
		a.chainID = cast(char)('A' + chain.indexOf(a.chainID));
		return a;}).print;
	else pout.print;
}
