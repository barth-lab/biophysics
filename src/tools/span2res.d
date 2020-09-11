#!/usr/bin/env rdmd

/* Copyright (C) 2020 Andreas Füglistaler <andreas.fueglistaler@gmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module tools.span2res;

immutable description=
"Extract residues outside of membrane from SPAN-FILE to standard output.";

void main(string[] args) {
	import std.getopt;
	import std.stdio;
	import std.range;
	import std.array;
	import std.uni;
	import std.conv;
	import std.algorithm;

	bool non = false;
	bool ins = false;
	auto opt = getopt(
		args,
		"hetatm|n", "Use non-standard residues", &non,
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

	string res;
	if (ins) {
		foreach (i, l; file.byLine.enumerate) {
			if (i < 4) continue;	

			auto sp = l.splitter;
			res ~= sp.front ~ '-';
			sp.popFront;
			res ~= sp.front ~ ','; 
		}
		res = res[0 .. $ - 1];
	}
	else {
		string start = "1";
		foreach (i, l; file.byLine.enumerate) {
			if (i < 4) continue;	

			auto sp = l.splitter;
			immutable stop = (sp.front.to!int - 1).to!string;
			res ~= start ~ '-' ~ stop ~ ','; 
			sp.popFront;
			start = (sp.front.to!int + 1).to!string;
		}
		res ~= start ~ "-9999";
		
	}
	res.writeln;
}
