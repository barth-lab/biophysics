#!/usr/bin/env rdmd

/* Copyright (C) 2020 Andreas Füglistaler <andreas.fueglistaler@gmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module scripts.split;

import biophysics.pdb;

auto splitChains(Range)(lazy Range atoms, double dist = 4) {
	import std.algorithm;

	char[80] old;
	old.x = 1e6;
	old.y = 1e6;
	old.z = 1e6;
	char chain = 'A' - 1;
	uint old_number = 0;

	return atoms.map!((atom) {

		if (atom.resSeq != old_number) {
			if (distance(atom, old) > dist) chain++;

			old_number = atom.resSeq;
			old        = atom;
		}
		atom.chainID = (chain < 'A' ? 'A' : chain);

		return atom;
	});
}

void main(string[] args)
{
	import std.getopt;
	import std.stdio;
	bool non = false;
	auto opt = getopt(args, "non_standard|n", "Use non-standard residues", &non);

	if (args.length > 2 || opt.helpWanted) {
		defaultGetoptPrinter("Usage of " ~ args[0] ~ ":", opt.options);
		return;
	}
	auto file = (args.length == 2 ? File(args[1]) : stdin);

	file.parse(non)
	    .splitChains
	    .print;

}
