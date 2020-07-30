#!/usr/bin/env rdmd


void main(string[] args)
{
	import std.algorithm;
	import std.stdio;
	import std.range;

	auto xs = [0, 1, 2, 3];
	auto x0 = xs.front;
	xs.map!((x) {
			writeln("in delegate: ", x);
			return 0;
		}).each!writeln;
}
