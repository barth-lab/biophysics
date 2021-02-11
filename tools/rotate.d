#!/usr/bin/env dub
/+ dub.sdl:
	name        "rotate"
	targetType  "executable"
	targetPath  "../bin"
	targetName  "rotate"
	dependency "biophysics" version="*" path=".."
	dependency "lubeck" version="~>1.1"
+/

/* Copyright (C) 2020 Andreas Füglistaler <andreas.fueglistaler@gmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module tools.rotate;

import std.algorithm;
import biophysics.pdb;

double[4] quat_mul(double[4] q, double[4] r) {
	return [
		r[0]*q[0] - r[1]*q[1] - r[2]*q[2] - r[3]*q[3],
		r[0]*q[1] + r[1]*q[0] - r[2]*q[3] + r[3]*q[2],
		r[0]*q[2] + r[1]*q[3] + r[2]*q[0] - r[3]*q[1],
		r[0]*q[3] - r[1]*q[2] + r[2]*q[1] + r[3]*q[0]
		];
}

auto rotate(Range)(Range atoms, double[3] angles, string chains) {
	import std.math;
	import std.array;
	import std.range;
	import mir.ndslice;
	import kaleidic.lubeck;
	import mir.math.sum;

	auto all = atoms.map!dup.array;
	auto chs = all.filter!(a => chains.canFind(a.chainID));
	auto com = [0., 0., 0.].sliced;
	double[] raw;
	foreach (i, a; chs.enumerate) {
		immutable x = a.x;
		immutable y = a.y;
		immutable z = a.z;
		raw   ~= [x, y, z];
		com[] += [x, y, z];
	}
	auto crds = raw.sliced(raw.length/3, 3);
	com[]    /= (crds.length);
	auto pca  = crds.pca;

	double[4][3] qs;
	double[4][3] q_1s;
	ulong[] js;
	foreach (j, ang; angles[].enumerate) {
		if (ang.isNaN) continue;
		js     ~= j;
		auto vj = pca.coeff[j][] * sin(ang / 2);
		qs[j]   = [cos(ang / 2), vj[0], vj[1], vj[2]];
		q_1s[j] = [cos(ang / 2), -vj[0], -vj[1], -vj[2]];
	}
	foreach(i, a; chs.enumerate) {
		double[4] p = [0,
			      crds[i][0] - com[0],
			      crds[i][1] - com[1],
			      crds[i][2] - com[2]];
		foreach (j; js) {
			p    = quat_mul(quat_mul(qs[j], p), q_1s[j]);
			p[0] = 0;
		}
		a.x = p[1] + com[0];
		a.y = p[2] + com[1];
		a.z = p[3] + com[2];
	}
	return all;
}

immutable description=
"Rotate chains of PDB-FILE around three major axis and write to standard output.";

void main(string[] args) {
	import std.getopt;
	import std.stdio;
	import std.math;

	bool non = false;
	double a1, a2, a3;
	string chains = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	auto opt = getopt(
		args,
		"hetatm|n", "Use non-standard (HETATM) residues", &non,
		"1", "angle 1 [°]", &a1,
		"2", "angle 2 [°]", &a2,
		"3", "angle 3 [°]", &a3,
		"chains|c", "Chains to rotate, default = all", &chains);

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

	file.parse(non).rotate([a1/180*PI, a2/180*PI, a3/180*PI], chains).print;
}
