#!/usr/bin/env dub
/+ dub.sdl:
	name        "contacts"
	targetType  "executable"
	targetPath  "../bin"
	targetName  "contacts"
	dependency "biophysics" version="*" path=".."
+/

/* Copyright (C) 2020 Andreas Füglistaler <andreas.fueglistaler@gmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module tools.contacts;

import biophysics.pdb;

/**
   Contacts between residues within `cut_off`. One of the reisudes
   must lied within `residues` And the minimal residue-number distance
   must be `offset`.
 */
double[string] contacts(R)(R atoms, double cut_off, int[] residues, int offset) {
	import std.algorithm;
	import std.range;
	import std.format;
	import std.conv;
	import std.string;

	double[string] contacts;
	double[3][] coords;
	int[] resSeqs;
	char[] chains;
	bool[] isWanted;
	
	foreach (a; atoms) {
		coords  ~= [a.x, a.y, a.z];
		resSeqs ~= a.resSeq;
		chains  ~= a.chainID;
		if (residues.canFind(resSeqs[$ -1])) isWanted ~= true;
		else isWanted ~= false;
	}
	foreach (i; 0 .. coords.length - 1) {
		immutable double[3] ci = coords[i];

		immutable resSeqi = resSeqs[i];
		immutable keyi    = format("%c%04d",chains[i], resSeqi);
		int       resSkip = 0;
		foreach (j; i .. coords.length) {
			if (resSeqs[j] <= resSeqi + offset) continue;
			if (resSeqs[j] == resSkip) continue;
			if (!isWanted[i] && !isWanted[j]) continue;

			immutable d = distance(ci, coords[j]);
			if (d > cut_off + 15) {
				resSkip = resSeqs[j];
				continue;
			}
			if (d > cut_off) continue;
			immutable key = format("%s-%c%04d", keyi, chains[j],
			                       resSeqs[j]);

			auto dh = contacts.require(key, d);
			if (dh > d) contacts[key] = d;
		}
	}
	return contacts;
}

/// Contacts between residues `from` and `to` within `cut_off`.
double[string] contacts(R1, R2)(R1 from, R2 to, double cut_off, bool polar=false) {
	import std.range;
	import std.format;
	import std.conv;
	import std.string;

	double[string] contacts;
	double[3][] coords2;
	int[] resSeq2;
	char[] chain2;
	
	foreach (a; to) {
		if (polar && a.isC) continue;

		coords2  ~= [a.x, a.y, a.z];
		resSeq2  ~= a.resSeq;
		chain2   ~= a.chainID;
	}
	foreach (a; from) {
		if (polar && (a.isNonPolar || a.isBB || a.isC)) continue;

		immutable key1 = format("%c%04d", a.chainID, a.resSeq);

		immutable double[3] ci = [a.x, a.y, a.z];
		int resSkip            = 0;
		foreach (j; 0..coords2.length) {
			if (resSeq2[j] == resSkip) continue;

			immutable d = distance(ci, coords2[j]);
			if (d > cut_off + 15) {
				resSkip = resSeq2[j];
				continue;
			}
			if (d > cut_off) continue;

			immutable key = format("%s-%c%04d", key1, chain2[j],
			                       resSeq2[j]);
			auto dh = contacts.require(key, d);
			if (dh > d) {
				contacts[key] = d;
			}
		}
	}
	return contacts;
}

immutable description=
"Find residue-contacts in PDB-FILE1 or between PDB-FILE1 and 2 to standard output.";

void main(string[] args) {
	import std.getopt;
	import std.algorithm;
	import std.stdio;
	import std.array;
	import biophysics.util;

	bool   non      = false;
	bool   rmSim    = false;
	bool   polar    = false;
	double cutoff   = 4.;
	int    offset   = 1;
	string residues = "1-9999";
	string chains   = "";

	auto opt = getopt(
		args,
		"hetatm|n",
		"Use non-standard (HETATM) residues",
		&non,

		"polar|p",
		"Only consider polar (hydrogen bond) contacts",
		&polar,

		"chains|c",
		"contacts from this CHAINS, default = all",
		&chains,

		"offset|o",
		"Minimum residue-number difference",
		&offset,

		"residues|r",
		"Contact must include this residue, default = all",
		&residues,

		"remove_similar|s",
		"Remove redundant contacts that are similar to a better one",
		&rmSim,

		"cutoff-distance|d",
		"Contact cutoff-distance, default = 4A",
		&cutoff);

	if (args.length > 2 || args.length == 0 || opt.helpWanted) {
		defaultGetoptPrinter(
			"Usage: " ~ args[0]
			~ " [OPTIONS]... FILE1 [FILE2]\n"
			~ description
			~ "\n\nWith no FILE2, or when FILE2 is --,"
			~ " read standard input.\n",
			opt.options);
		return;
	}

	auto file = (args.length == 2 ? File(args[1]) : stdin);
	auto pdb  = file.parse(non).filter!(a => !a.isH);

	double[string] cs = void;

	if (!chains.empty) {
		auto p    = pdb.map!(dup).array;			
		auto from = p.filter!(a => chains.canFind(a.chainID));
		auto to   = p.filter!(a => !chains.canFind(a.chainID));
		cs = contacts(from, to, cutoff, polar);
	}
	else {
		cs = contacts(pdb, cutoff, str2index(residues), offset);
	}
	string[] keys;
	if (rmSim) {
		auto redundant(string key1, string key2) {
			import std.conv;
			import std.math;
			immutable i1 = key1[1 .. 5].to!int;
			immutable j1 = key1[7 .. 11].to!int;
			immutable i2 = key2[1 .. 5].to!int;
			immutable j2 = key2[7 .. 11].to!int;
			if ((abs(i1 - i2) < 4) && (abs(j1 - j2) < 4)) {
				return true;
			}
			return false;
		}
		foreach (k; cs.keys.sort!((k1, k2) => cs[k1] < cs[k2])) {
			if (keys.any!(kn => redundant(kn, k))) continue;
			keys ~= k;
		}
	}
	else {
		keys = cs.keys;
	}
	foreach (k; keys.sort) {
		writefln("%s %5.2f", k, cs[k]);
	}
}
