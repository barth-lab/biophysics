#!/usr/bin/env dub
/+ dub.sdl:
	name        "pdb_info"
	targetType  "executable"
	targetPath  "../bin"
	targetName  "pdb_info"
	dependency "biophysics" version="*" path=".."
+/

/* Copyright (C) 2020 Andreas Füglistaler <andreas.fueglistaler@gmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module tools.info;

immutable description=
"Print information about a protein file.";

void main(string[] args) {
	import std.getopt;
	import std.algorithm;
	import std.stdio;
	import std.array;
	import std.string;
	import biophysics.pdb;
	import biophysics.fasta;

	bool chainInfo = false;
	bool countGaps = false;
	auto opt     = getopt(
		args,
		"chains|c", "Print info per chain", &chainInfo,
		"count_gaps|g", "Count gap as residue", &countGaps);

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

	immutable hasFile = args.length == 2;
	immutable fn      = (hasFile ? args[1] : "");
	auto file = (hasFile ? File(fn) : stdin);
	auto fasta = file.parse.fasta(countGaps);

	writef("#%8s %8s ", "N_chains", "N_restot");
	int tot = 0;
	string schains = "";
	string sinfo   = "";
	foreach (ch; fasta) {
		immutable l = ch.seq.length;
		if(chainInfo) {
			schains ~= l.format!"%4u ";
			sinfo   ~= ch.name.format!"%4s ";
		}
		tot += l;
	}
	writeln(sinfo);
	writefln("%9d %8d %s", fasta.length, tot, schains);
}
