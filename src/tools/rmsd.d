#!/usr/bin/env rdmd

/* Copyright (C) 2020 Andreas Füglistaler <andreas.fueglistaler@gmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module tools.rmsd;

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

	if (args.length > 3 || args.length == 0 || opt.helpWanted) {
		defaultGetoptPrinter("Usage of " ~ args[0] ~ ":", opt.options);
		return;
	}
	auto file1 = File(args[1]);
	auto file2 = (args.length == 3 ? File(args[2]) : stdin);
	auto pdb1  = file1.parse(non).filter!(a => a.name == "CA");
	auto pdb2  = file2.parse(non).filter!(a => a.name == "CA");

	writefln("%+.3e", rmsd(pdb1, pdb2));
}
