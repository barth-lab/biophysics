#!/usr/bin/env rdmd


import biophysics.pdb;

double rmsd(R1, R2)(R1 atoms1, R2 atoms2) {
	import std.range;
	import std.math;
	double s = 0;
	int    l = 0;
	foreach (a1, a2; zip(atoms1, atoms2)) {
		immutable dx = a1.x - a2.x;	
		immutable dy = a1.y - a2.y;	
		immutable dz = a1.z - a2.z;	
		s += dx*dx + dy*dy + dz*dz;
		l++;
	}
	return sqrt(s)/l;
}

void main(string[] args) {
	import std.getopt;
	import std.algorithm;
	import std.stdio;

	bool non = false;
	string chain = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	auto opt = getopt(args,
			  "non_standard|n", "Use non-standard residued", &non,
			  "chain|c", "Chain to translate, default = all", &chain);

	if (args.length != 3 || opt.helpWanted) {
		defaultGetoptPrinter("Usage of " ~ __FILE__ ~ ":", opt.options);
		return;
	}

	auto pdb1 = parse(args[1], non).filter!(a => a.name == "CA");
	auto pdb2 = parse(args[2], non).filter!(a => a.name == "CA");

	writefln("%+.3e", rmsd(pdb1, pdb2));
}
