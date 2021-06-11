#!/usr/bin/env dub
/+ dub.sdl:
	name        "polar"
	targetType  "executable"
	targetPath  "../bin"
	targetName  "polar"
	dependency "biophysics" version="*" path=".."
+/


/* Copyright (C) 2020 Andreas Füglistaler <andreas.fueglistaler@gmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module tools.polar;

import biophysics.pdb;

bool[string] countPolarContacts(R1, R2)(R1 from, R2 to, double cut_off) {
	import std.range;
	import std.format;
	import std.conv;
	import std.string;

	bool[string] contacts;

	double[3][] coords2;
	int[] resSeq2;
	
	foreach (a; to) {
		if (a.isH || a.isC) continue;

		coords2  ~= [a.x, a.y, a.z];
		resSeq2  ~= a.resSeq;
	}
	foreach (a; from) {
		if (a.isNonPolar || a.isH || a.isBB || a.isC) continue;

		immutable key1 = format("%c%04d/%s", a.chainID, a.resSeq, a.name);
		contacts[key1] = false;

		immutable double[3] crd = [a.x, a.y, a.z];
		int resSkip             = -1;
		foreach (j; 0..coords2.length) {
			if (resSeq2[j] == resSkip) continue;

			immutable d = distance(crd, coords2[j]);
			if (d > cut_off + 15) {
				resSkip = resSeq2[j];
				continue;
			}
			if (d < cut_off) {
				contacts[key1] = true;
				break;
			}
		}
	}
	return contacts;
}

string[string] listPolarContacts(R1, R2)(R1 from, R2 to, double cut_off) {
	import std.range;
	import std.format;
	import std.conv;
	import std.string;

	string[string] contacts;

	double[3][] coords2;
	int[] resSeq2;
	char[] chainID2;
	string[] name2;
	
	foreach (a; to) {
		if (a.isH || a.isC) continue;

		coords2  ~= [a.x, a.y, a.z];
		resSeq2  ~= a.resSeq;
		chainID2 ~= a.chainID;
		name2    ~= a.name;
	}
	foreach (a; from) {
		if (a.isNonPolar || a.isH || a.isBB || a.isC) continue;

		immutable key1 = format("%c%04d/%s", a.chainID, a.resSeq, a.name);
		contacts[key1] = "";

		immutable double[3] crd = [a.x, a.y, a.z];
		int resSkip             = -1;
		foreach (j; 0..coords2.length) {
			if (resSeq2[j] == resSkip) continue;

			immutable d = distance(crd, coords2[j]);
			if (d > cut_off + 15) {
				resSkip = resSeq2[j];
				continue;
			}
			if (d < cut_off) {
				contacts[key1]  ~=
				        format("%c%04d/%s", chainID2[j],
				               resSeq2[j], name2[j])
					~ ",";
			}
		}
	}
	return contacts;
}

immutable description=
"List polar atoms of CHAINs of PDB-FILE standard output.";

immutable extra =
"First column is amino-acid/atom-name, second column is 1 if polar
atom has a hydrogen bond, 0 otherwise.";

void main(string[] args) {
	import std.getopt;
	import std.algorithm;
	import std.stdio;
	import std.array;
	import biophysics.util;

	double cutoff   = 3.5;
	string chains   = "";
	bool list = false;

	auto opt = getopt(
		args,
		"chains|c",
		"contacts to this CHAINS, default = all",
		&chains,

		"list|l",
		"list all contacts, default = all",
		&list,

		"cutoff-distance|d",
		"Contact cutoff-distance, default = 3.5A",
		&cutoff);

	if (args.length > 2 || args.length == 0 || opt.helpWanted) {
		defaultGetoptPrinter(
			"Usage: " ~ args[0]
			~ " [OPTIONS]... FILE -c CHAINS\n"
			~ description
			~ "\n\nWith no FILE2, or when FILE2 is --,"
			~ " read standard input.\n",
			opt.options);
		writeln("\n" ~ extra);
		return;
	}

	auto file = (args.length == 2 ? File(args[1]) : stdin);
	auto pdb  = file.parse.map!(dup).array;
	auto from = pdb.filter!(a => chains.canFind(a.chainID));
	auto to   = pdb.filter!(a => !chains.canFind(a.chainID));
	if (list) {
		auto cs   = listPolarContacts(from, to, cutoff);
		foreach (k; cs.keys.sort) {
			writefln("%-10s %s", k, cs[k]);
		}
		
	}
	else {
		auto cs   = countPolarContacts(from, to, cutoff);

		foreach (k; cs.keys.sort) {
			writefln("%-10s %b", k, cs[k]);
		}
	}
}
