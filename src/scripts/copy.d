#!/usr/bin/env rdmd

void main(string[] args)
{
	import biophysics.pdb;
	import std.getopt;
	import std.stdio;
	bool non = false;
	auto opt = getopt(args, "non_standard|n", "Use non-standard residues", &non);

	if (args.length > 2 || opt.helpWanted) {
		defaultGetoptPrinter("Usage of " ~ args[0] ~ ":", opt.options);
		return;
	}
	auto file = (args.length == 2 ? File(args[1]) : stdin);
	file.parse.print;
}
