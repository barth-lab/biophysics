/* Copyright (C) 2020 Andreas Füglistaler <andreas.fueglistaler@gmail.com>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

module biophysics.util;

/// Translate input-string with index-numbers to indexes
int[] str2index(const string s) pure {
	import std.array;
	import std.conv;

	int[] index;
	immutable csplits = s.split(',');
	foreach (csp; csplits) {
		immutable dsplits = csp.split('-');	
		if (!dsplits.length) continue;

		if (dsplits.length == 1) {
			index ~= dsplits[0].to!int;
		}
		else {
			immutable from = dsplits[0].to!int;
			immutable to   = dsplits[1].to!int + 1;
			foreach (i; from .. to) index ~= i;
		}
	}
	return index;
}
///
unittest {
	assert(str2index("") == []);
	assert(str2index(",") == []);
	assert(str2index("1") == [1]);
	assert(str2index("1,") == [1]);
	assert(str2index("1,2-5,11,15,") == [1,2,3,4,5,11,15]);
}
