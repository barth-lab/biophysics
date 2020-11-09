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

int[] str2index(string s) {
	import std.array;
	import std.conv;

	int[] index;
	immutable csplits = s.split(',');
	foreach (csp; csplits) {
		immutable dsplits = csp.split('-');	
		if (dsplits.length == 1) index ~= dsplits[0].to!int;
		else {
			immutable from = dsplits[0].to!int;
			immutable to   = dsplits[1].to!int + 1;
			foreach (i; from .. to) index ~= i;
		}
	}
	return index;
}

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
	foreach (i; 0 .. coords.length) {
		immutable double[3] ci = coords[i];
		immutable resSeqi = resSeqs[i];
		immutable keyi    =  format("%c%04d",chains[i], resSeqi);
		int       resSkip = 0;
		foreach (j; i .. coords.length) {
			if (resSeqs[j] <= resSeqi + offset) continue;
			if (resSeqs[j] == resSkip) continue;
			if (!isWanted[i] && !isWanted[j]) continue;

			immutable d = ci.distance(coords[j]);
			if (d > cut_off + 15) resSkip = resSeqs[j];
			if (d > cut_off) continue;
			immutable key = format("%s-%c%04d", keyi, chains[j],
			                       resSeqs[j]);
			auto dh = contacts.require(key, d);
			if (dh > d) contacts[key] = d;
		}
	}
	return contacts;
}

double[string] contacts(R1, R2)(R1 atoms1, R2 atoms2, double cut_off) {
	import std.range;
	import std.format;
	import std.conv;
	import std.string;

	double[string] contacts;
	double[3][] coords2;
	int[] resSeq2;
	char[] chain2;
	
	foreach (a2; atoms2) {
		coords2 ~= [a2.x, a2.y, a2.z];
		resSeq2 ~= a2.resSeq;
		chain2  ~= a2.chainID;
	}
	foreach (a1; atoms1) {
		immutable double[3] c1 = [a1.x, a1.y, a1.z];
		immutable key1    =  format("%c%04d",a1.chainID, a1.resSeq);
		int       resSkip = 0;
		foreach (j; 0 .. coords2.length) {
			if (resSeq2[j] == resSkip) continue;

			immutable d = c1.distance(coords2[j]);
			if (d > cut_off + 15) resSkip = resSeq2[j];
			if (d > cut_off) continue;
			immutable key = format("%s-%c%04d", key1, chain2[j],
			                       resSeq2[j]);
			auto dh = contacts.require(key, d);
			if (dh > d) contacts[key] = d;
		}
	}
	return contacts;
}

immutable description=
"Find residue-contacts in PDB-FILE or between PDB-FILE1 and 2 to standard output.";

void main(string[] args) {
	import std.getopt;
	import std.algorithm;
	import std.stdio;
	import std.array;

	bool   non      = false;
	bool   rmSim    = false;
	double cutoff   = 4.;
	int    offset   = 1;
	string to       = "";
	string residues = "1-9999";

	auto opt = getopt(
		args,
		"hetatm|n",
		"Use non-standard (HETATM) residues",
		&non,

		"to|t",
		"File to compare to, default = none",
		&to,

		"offset|o",
		"Minimum residue-number difference",
		&offset,

		"residues|r",
		"Contact must include this residue, default = all",
		&residues,

		"remove_similar|s",
		"Remove redundant contacts that are similar to a better one",
		&rmSim,

		"cutoff|c",
		"Contact cutoff, default = 4A",
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

	auto file1 = (args.length == 2 ? File(args[1]) : stdin);
	auto pdb1  = file1.parse(non).filter!(a => !a.isH);
	double[string] cs = void;

	if (to.empty) {
		cs = contacts(pdb1, cutoff, str2index(residues), offset);	
	}
	else {
		auto pdb2  = File(to).parse(non).filter!(a => !a.isH);

		cs = contacts(pdb1, pdb2, cutoff);
	}

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

	string[] keys;
	if (rmSim) {
		foreach (k; cs.keys.sort!((k1, k2) => cs[k1] < cs[k2])) {
			if (keys.any!(kn => redundant(kn, k))) continue;
			keys ~= k;
		}
	}
	else {
		keys = cs.keys;
	}

	foreach (k; keys.sort) {
		writefln("%s: %5.2f", k, cs[k]);
	}
}
