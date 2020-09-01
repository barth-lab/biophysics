#!/usr/bin/env rdmd

auto str2index(string s) {
	import std.array;
	import std.conv;

	int[] index;
	immutable csplits = s.split(',');
	foreach (csp; csplits) {
		immutable dsplits = csp.split('-');	
		if (dsplits.length == 1) index ~= dsplits[0].to!int;
		else {
			immutable from = dsplits[0].to!int;
			immutable to   = dsplits[1].to!int + 1;
			foreach (i; from .. to) index ~= i;
		}
	}
	return index;
}

void main(string[] args) {
	import std.getopt;
	import std.algorithm;
	import std.stdio;
	import std.array;
	import std.string;
	import biophysics.pdb;

	bool   non      = false;
	string ids      = "";
	string chains   = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	string residues = "1-9999";
	auto opt        = getopt(args,
				"non_standard|n",
				"Use non-standard residued",
				&non,
				"chainIDs|i",
				"Use these chainIDs instead of the original one",
				&ids,
				"chains|c",
				"Chains to extract, default = all",
				&chains,
				"residues|r",
				"Residues to extract, default = 1-9999",
				&residues);

	if (args.length != 2 || opt.helpWanted) {
		defaultGetoptPrinter("Usage of " ~ __FILE__ ~ ":", opt.options);
		return;
	}
	if (ids.empty) ids=chains;

	immutable resSeqs = str2index(residues);
	auto as = parse(args[1], non)
		       .filter!(a => chains.canFind(a.chainID))
		       .filter!(a => resSeqs.canFind(a.resSeq))
		       .map!dup
		       .array;

	if (as.empty) return;

	chains.map!(c => as.filter!(a => a.chainID == c))
	      .joiner
	      .map!((a) {
		 a.chainID = cast(char)(ids[chains.indexOf(a.chainID)]);
		 return a;})
	      .print;
}
