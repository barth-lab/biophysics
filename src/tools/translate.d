#!/usr/bin/env rdmd

/* Copyright (C) 2020 Andreas Füglistaler <andreas.fueglistaler@gmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module tools.translate;

import std.algorithm;
import biophysics.pdb;

auto translate(Range)(Range atoms, double x, double y, double z, string chain) {
	import std.math;

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
	import std.stdio;

	bool non = false;
	double x,y,z;
	string chain = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	auto opt = getopt(args,
			  "non_standard|n", "Use non-standard residued", &non,
			  "x", "x-value", &x,
			  "y", "x-value", &y,
			  "z", "x-value", &z,
			  "chain|c", "Chain to translate, default = all", &chain);

	if (args.length > 2 || opt.helpWanted) {
		defaultGetoptPrinter("Usage of " ~ args[0] ~ ":", opt.options);
		return;
	}
	auto file = (args.length == 2 ? File(args[1]) : stdin);

	file.parse(non).translate(x, y, z, chain).print;

}
