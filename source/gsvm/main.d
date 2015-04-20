module main;

import std.stdio;
import std.algorithm;
import std.array;

import gsvm.vm;
import gsvm.models.storage;

void main(string[] args)
{
	try
	{
		File programFile = File(args[1],"r");
		auto memory = Storage(0xF000, TypeOfStorage.Programm);

		programFile.writeBytesIn(memory);
//		auto memory = Storage(0xF000, TypeOfStorage.RAM);
//		memory.write(0x00, 0x4730_4311u); // and
//		memory.write(0x04, 0x0000_FFFFu); // arg 1
//		memory.write(0x08, 0xFFFF_000Fu); // arg 2 
//		memory.write(0x0C, 0x0000_0000u); // arg 3
//		memory.write(0x10, 0x4730_4313u); // xor
//		memory.write(0x14, 0x0000_FFFFu); // arg 1
//		memory.write(0x18, 0xFFFF_0000u); // arg 2 
//		memory.write(0x1C, 0x0000_0004u); // arg 3
//		memory.write(0x20, 0x4710_0131u); // jmp
//		memory.write(0x24, 0x0000_0000u); // arg 1
		memory.dump(0,0x28);
//		auto vm = ProcessorCore(&memory);
//		vm.loadProgramm(0x00);
//		vm.runOneCommand();
//		vm.runOneCommand();
//		vm.runOneCommand();
//		vm.runOneCommand();
	}
	catch(Exception e)
	{
		stderr.writeln(e.msg);
	}
	stdin.readln();
}

void writeBytesIn(File sourceFile, Storage memory)
{
	auto byteFlow = cast(immutable(ubyte)[])sourceFile.byChunk(4096).joiner.array;
	memory.write(0, byteFlow);
}
