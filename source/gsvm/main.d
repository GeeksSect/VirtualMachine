module main;

import std.stdio;
import std.conv;

import gsvm.vm;

void main(string[] args)
{
	auto machine = new VM(0x100000);
	// Lets the user press <Return> before program returns
	stdin.readln();
}

