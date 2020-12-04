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
	import std.array;
	import biophysics.pdb;

	bool non  = false;
	bool ins  = false;
	int  hmin = 4;
	int  min  = 4;
	int  add  = 0;
	auto opt  = getopt(
		args,
		"hetatm|n", "Use non-standard residues", &non,
		"lmin|l", "Minimum helix length, default=4", &hmin,
		"rmin|m", "Minimum loop length", &min,
		"add_helix|a", "Add this many residues of helix to loops", &add,
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
	char[][] raw  = file.byLine.map!dup.array;

	auto hs = raw.filter!(l => l.startsWith("HELIX"));
	auto as = raw.filter!(l => l.hasLength && l.isAtom && l.name == "CA");
	int length = 0;
	foreach (char[] a; as) {
		length = max(length, a.resSeq);	
	}

	string res   = "";
	int    from = 1;
	foreach (h; hs) {
		immutable hfrom = h[21 .. 25].strip.to!int;
		immutable hto   = h[33 .. 37].strip.to!int;
		immutable to    = hfrom - 1;
		if ((hto - hfrom + 1) >= hmin) {
			if (to - from >= min) {
				res ~= max(1, from - add).to!string ~ '-'
				     ~ (to + add).to!string ~ ',';
			}
			from = hto + 1;
		}
	}
	immutable to = length;
	if (to - from >= min) {
		res ~= max(1, from - add).to!string ~ '-'
			~ (to + add).to!string ~ ',';
	}
	res.writeln;
}
