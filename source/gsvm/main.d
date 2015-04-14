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
		memory.write(0x00, 0x0000_0011u);
		memory.write(0x04, 0x0000_FFFFu);
		memory.write(0x08, 0xFFFF_000Fu);
		writeln(memory.read(0x00, 16));
		auto vm = ProcessorCore(&memory);
		vm.loadProgramm(0x00);
		vm.runOneCommand();
	}
	catch(Exception e)
	{
		stderr.writeln(e.msg);
	}
	stdin.readln();
}

