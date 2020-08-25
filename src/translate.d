#!/usr/bin/env rdmd

auto translate(Range)(Range atoms, double x, double y, double z, string chain) {
	import pdb;
	import std.math;
	import std.algorithm;

	return atoms.map!((atom) {
		if (!chain.canFind(atom.chainID)) return atom;

		if (!x.isNaN) atom.x = atom.x + x;
		if (!y.isNaN) atom.y = atom.y + y;
		if (!z.isNaN) atom.z = atom.z + z;
		return atom;
	});
}

void main(string[] args) {
	import std.getopt;
	import std.algorithm;
	import pdb;

	bool non = false;
	double x,y,z;
	string chain = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	auto opt = getopt(args,
			  "non_standard|n", "Use non-standard residued", &non,
			  "x", "x-value", &x,
			  "y", "x-value", &y,
			  "z", "x-value", &z,
			  "chain|c", "Chain to translate, default = all", &chain);

	if (args.length != 2 || opt.helpWanted) {
		defaultGetoptPrinter("Usage of " ~ __FILE__ ~ ":", opt.options);
		return;
	}
	pdb.parse(args[1], non).translate(x, y, z, chain).print;

}
