module main;

import std.stdio;
import std.conv;

import gsvm.vm;

void main(string[] args)
{
	ulong mem_size = 0x100000;

	auto machine = new VM();
	ulong[] programm = [0x0000_0000_0000_00FF,
	                    0x0000_0000_0000_0000,
	                    0x1000_0000_0000_0000,
	                    0x1F00_0000_0000_0000];

	ulong[] some_value = [0x0000_0000_0000_FF00];

	machine.loadToMemory(to!ulong(0), programm);
	machine.loadToMemory(mem_size - 1, some_value);

	machine.startExecution(1);
	
	// Lets the user press <Return> before program returns
	stdin.readln();
}

