module main;

import std.stdio;
import std.conv;

import gsvm.vm;
import gsvm.models.storage;

void main(string[] args)
{
	try
	{
		auto memory = Storage(0xF000, TypeOfStorage.RAM);
		memory.write(0x00, 0x00_33_FF_11u);
		memory.write(0x04, 0x10u);
		memory.write(0x08, 0x00u);
		memory.write(0x0C, 0x04u);
		writeln(memory.read(0x00, 16));
		auto vm = ProcessorCore(&memory);
		vm.loadProgramm(0x00);
		vm.runOneCommand();
		vm.runOneCommand();
		vm.runOneCommand();
		vm.runOneCommand();
	}
	catch(Exception e)
	{
		stderr.writeln(e.msg);
	}
	stdin.readln();
}

