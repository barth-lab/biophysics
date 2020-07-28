#!/usr/bin/env rdmd

void main(string[] args)
{
	import pdb;
	import std.getopt;
	bool heavy = false;
	auto opt = getopt(args, "heavy|v", "Use heavy Atoms", &heavy);

	if (args.length != 2 || opt.helpWanted) {
		defaultGetoptPrinter("Usage of " ~ args[0] ~ ":", opt.options);
		return;
	}
	pdb.parse(args[1], heavy).print;
}
