module main;

import std.stdio;
import std.algorithm;
import std.array;

import gsvm.vm;
import gsvm.models.storage;

int main(string[] args)
{
	try
	{
		if(args.length != 2)
		{
			stderr.writeln("File with program must specified");
			return 1;
		}
		File programFile = File(args[1],"r");
		auto memory = Storage(0xF000, TypeOfStorage.RAM);
		programFile.writeBytesIn(memory);
		debug memory.dump(0,0x24);

		auto vm = ProcessorCore(&memory);
		vm.loadProgramm(0x00);
		vm.runProcess();
	}
	catch(Exception e)
	{
		stderr.writeln(e.msg);
	}
	debug stdin.readln();
	return 0;
}

void writeBytesIn(File sourceFile, Storage memory)
{
	auto byteFlow = cast(immutable(ubyte)[])sourceFile.byChunk(4096).joiner.array;
	memory.write(0, byteFlow);
}
