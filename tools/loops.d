#!/usr/bin/env dub
/+ dub.sdl:
	name        "loops"
	targetType  "executable"
	targetPath  "../bin"
	targetName  "loops"
	dependency "biophysics" version="*" path=".."
+/

/* Copyright (C) 2020 Andreas Füglistaler <andreas.fueglistaler@gmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module tools.loops;

immutable description=
"Print loop residue numbers not in secondary structure to standard output.";

void main(string[] args) {
	import std.getopt;
	import std.stdio;
	import std.algorithm;
	import std.string;
	import std.conv;

	bool non  = false;
	bool ins  = false;
	int  lmin = 4;
	int  add  = 0;
	auto opt = getopt(
		args,
		"hetatm|n", "Use non-standard residues", &non,
		"lmin|l", "Minimum SS length, default=4", &lmin,
		"add-helix|a", "Add this many residues of helix to loops", &add,
		"inside|i", "Extract residues inside of membrane", &ins);

	if (args.length > 2 || opt.helpWanted) {
		defaultGetoptPrinter(
			"Usage: " ~ args[0]
			~ " [OPTIONS]... [FILE]\n"
			~ description
			~ "\n\nWith no FILE, or when FILE is --,"
			~ " read standard input.\n",
			opt.options);
		return;
	}
	auto file = (args.length == 2 ? File(args[1]) : stdin);

	auto hs = file.byLine.filter!(l => l.startsWith("HELIX"));

	string res = "1";
	foreach (h; hs) {
		immutable from = h[21 .. 25].strip.to!int;
		immutable to   = h[33 .. 37].strip.to!int;
		if ((to - from + 1) >= lmin) {
			res ~= '-' ~  (from - 1 + add).to!string;
			res ~= ',' ~  (to + 1 - add).to!string;
		}
	}
	res ~= "-9999";
	res.writeln;
}
