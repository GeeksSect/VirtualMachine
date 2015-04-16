module gsvm.vm;

import gsvm.models.storage;

import spec.common;

import std.conv;
import std.stdio;
import std.traits;

struct ProcessorCore
{
public:
	enum uint registerSize = 0x1000u;

private:
	enum int half = (cast(long)registerSize) >>> 1;
	enum int quarter = (cast(long)registerSize) >>> 2;

	auto generalPourposeRegisters = Storage(registerSize, TypeOfStorage.GPR);
	auto localProgrammRegister = Storage(registerSize, TypeOfStorage.Programm);

	// registers in which make calculation
	ulong[4] calcRegisters;
	ubyte flags;

	// register in which placed result of compare
	ulong compareRegister;

	long localInstruction = half;
	uint globalInstruction;

	Storage* memory;

	alias HandlerType = void delegate();

	HandlerType[] handlerVector;

public:
	this(Storage*  memory)
	in
	{
		assert(memory !is null, "processor core have to receive existing RAM");
		assert(memory.typeOfStorage == TypeOfStorage.RAM, "memory have to have got RAM type");
	}
	body
	{
		this.memory = memory;
		handlerVector = new HandlerType[OperationCode.max + 1];
		handlerVector[OperationCode.NOP] = &this.nopHandler;
		handlerVector[OperationCode.NOT] = &this.notHandler;
		handlerVector[OperationCode.AND] = &this.andHandler;
		handlerVector[OperationCode.OR]  = &this.orHandler;
		handlerVector[OperationCode.XOR] = &this.xorHandler;
		handlerVector[OperationCode.CMP] = &this.cmpHandler;
		handlerVector[OperationCode.JMP] = &this.jmpHandler;
		handlerVector[OperationCode.JE]  = &this.jeHandler;
		handlerVector[OperationCode.JNE] = &this.jneHandler;
		handlerVector[OperationCode.HLT] = &this.haltHandler;
		foreach(ref handler; handlerVector)
			if(handler is null)
				handler = &this.invalidHandler;
	}

	void runOneCommand()
	{
		import std.stdio: writeln;
		writeln("localInstruction: ", localInstruction);
		writeln("globalInstruction: ", globalInstruction);
		uint command = localProgrammRegister.read!uint(cast(uint)localInstruction);
		localInstruction += 4;
		globalInstruction += 4;
		//TODO calculate real count of operand
		writeln("command and operand");
		foreach(shift; 0..4)
		{
			calcRegisters[shift] = localProgrammRegister.read!uint(cast(uint)localInstruction);
			localInstruction += 4;
			globalInstruction += 4;
		}
		writeln("before:\n", command, calcRegisters);
		handlerVector[cast(ubyte)(command & 0xFF)]();
		writeln("after:\n", command, calcRegisters);
	}

	void loadProgramm(uint loadPosition)
	{
		localInstruction = half;
		globalInstruction = loadPosition;
		auto startCopy = cast(long)globalInstruction-localInstruction;
		localProgrammRegister.write(0, memory.read(startCopy, registerSize));
	}

	private void subLoadProgramm()
	{
		if(localInstruction < quarter)
		{
			if(localInstruction < 0)
			{
				localInstruction %= quarter;
				localInstruction += half;
				auto startCopy = cast(long)globalInstruction-localInstruction;
				localProgrammRegister.write(0, memory.read(startCopy, registerSize));
			}
			else
			{
				auto startCopy = cast(long)globalInstruction-localInstruction;
				localInstruction += half;
				localProgrammRegister.shiftHalfRight();
				localProgrammRegister.write(0, memory.read(startCopy, half));
			}
		}
		else if (localInstruction >= half + quarter)
		{
			if(localInstruction >= registerSize)
			{
				localInstruction %= quarter;
				localInstruction += half;
				auto startCopy = cast(long)globalInstruction-localInstruction;
				localProgrammRegister.write(0, memory.read(startCopy, registerSize));
			}
			else
			{
				localInstruction -= half;
				auto startCopy = cast(long)globalInstruction-localInstruction;
				localProgrammRegister.shiftHalfLeft();
				localProgrammRegister.write(half, memory.read(startCopy, half));
			}
		}
	}

private:
	void nopHandler()
	{
	}

	void invalidHandler()
	{
		throw new Exception("impossible opcode");
	}

	void notHandler()
	{
		calcRegisters[1] = ~calcRegisters[0];
	}

	void andHandler()
	{
		calcRegisters[2] = calcRegisters[0] & calcRegisters[1];
	}

	void orHandler()
	{
		calcRegisters[2] = calcRegisters[0] | calcRegisters[1];
	}

	void xorHandler()
	{
		calcRegisters[2] = calcRegisters[0] ^ calcRegisters[1];
	}

	void jmpHandler()
	{
		auto diff = globalInstruction - calcRegisters[0];
		localInstruction -= diff;
		globalInstruction -= diff;
	}

	void cmpHandler()
	{
		compareRegister = calcRegisters[0] - calcRegisters[1];
	}

	void jeHandler()
	{
		if (!compareRegister)
		{
			auto diff = globalInstruction - calcRegisters[0];
			localInstruction -= diff;
			globalInstruction -= diff;
		}
	}

	void jneHandler()
	{
		if (compareRegister)
		{
			auto diff = globalInstruction - calcRegisters[0];
			localInstruction -= diff;
			globalInstruction -= diff;		
		}
	}

	void haltHandler()
	{
		// TODO halt handler
	}
}

unittest
{
	assert(0 == paramsCount(0x0000_0000));
	assert(1 == paramsCount(0x4100_1110));
	assert(1 == paramsCount(0x4101_1110));
	assert(4 == paramsCount(0x4F28_C329));
	assert(3 == paramsCount(0x1700_4324));
	assert(3 == paramsCount(0x2701_4325));
	assert(2 == paramsCount(0x4300_0330));
}

private auto paramsCount(uint comand)
{
	return onesCount!(typeof(comand), 4)((comand & paramCountMask) >> paramCountShift);
}

unittest
{
	assert(5 == onesCount(0b01001_1011));
	assert(5 == onesCount(0b01001_1011u));
	assert(5 == onesCount(cast(short)0b01001_1011));
	assert(3 == onesCount!(int, 4uL)(0b01001_1011));
}

private ubyte onesCount(T, size_t bitCount = T.sizeof * 8)(T number)
	if(isIntegral!T)
{
	typeof(return) result;
	Unsigned!T zond = 1u;
	foreach(i; 0..bitCount)
	{
		result += zond & number ? 1 : 0;
		zond <<= 1;
	}
	return result;
}

