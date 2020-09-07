#!/usr/bin/env rdmd

/* Copyright (C) 2020 Andreas Füglistaler <andreas.fueglistaler@gmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module tools.parse;

import std.getopt;
string cmdLine(const Option[] opt, string fn) {
	string s = "Usage: " ~ fn;
	foreach (o; opt) {
		s ~= " [" ~ o.optShort ~ "]";
	}
	return s;
}

immutable description=
"Parse ATOM records from PDB-FILE to standard output.";

void main(string[] args) {
	import biophysics.pdb;
	import std.getopt;
	import std.stdio;
	import std.range;

	bool non = false;
	auto opt = getopt(args, "hetatm|n",
			  "Use non-standard (HETATM) residues", &non);

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
	file.parse.print;
}
