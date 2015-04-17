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
		memory.write(0x00, 0x4700_0011u); // and
		memory.write(0x04, 0x0000_FFFFu); // arg 1
		memory.write(0x08, 0xFFFF_000Fu); // arg 2 
		memory.write(0x0C, 0x0000_0000u); // arg 3
		memory.write(0x10, 0x4700_0013u); // xor
		memory.write(0x14, 0x0000_FFFFu); // arg 1
		memory.write(0x18, 0xFFFF_0000u); // arg 2 
		memory.write(0x1C, 0x0000_0000u); // arg 3
		memory.write(0x20, 0x4700_0031u); // jmp
		memory.write(0x24, 0x0000_0000u); // arg 1
		writeln(memory.read(0x00, 40));
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

