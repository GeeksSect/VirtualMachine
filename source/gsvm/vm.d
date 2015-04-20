module gsvm.vm;

import gsvm.models.storage;

import spec.common;

import std.conv;
import std.traits;

enum typeof(ProcessorCore.flags) equalFlag = 1u << 0;
enum typeof(ProcessorCore.flags) greatFlag = 1u << 1;
enum typeof(ProcessorCore.flags) lessFlag = 1u << 2;
enum typeof(ProcessorCore.flags) highFlag = 1u << 3;
enum typeof(ProcessorCore.flags) lowFlag = 1u << 4;
enum typeof(ProcessorCore.flags) kernelFlag = 1u << 5;
enum typeof(ProcessorCore.flags) allowInterruptionFlag = 1u << 6;
enum typeof(ProcessorCore.flags) haltFlag = 1u << 7;

struct ProcessorCore
{
public:
	enum uint registerSize = 0x1000u;

private:
	enum int half = (cast(long)registerSize) >>> 1;
	enum int quarter = (cast(long)registerSize) >>> 2;

	auto generalPourposeRegisters = Storage(registerSize, TypeOfStorage.GPR);
	auto localProgrammRegister = Storage(registerSize, TypeOfStorage.Programm);

	ulong[4] calcRegisters;

	ubyte flags;

	long localInstruction = half;
	uint globalInstruction;

	Storage* memory;

	enum handlerVector = initializeHandlerVector();

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
	}

	void runOneCommand()
	{
		debug
		{
			import std.stdio: writeln;
			writeln("localInstruction: ", localInstruction);
			writeln("globalInstruction: ", globalInstruction);
		}
		uint comand = localProgrammRegister.read!uint(cast(uint)localInstruction);
		debug writeln("command and operand");
		auto countOfParams = paramsCount(comand);
		auto paramOrigin = localInstruction + 4;
		foreach(param; 0..countOfParams)
		{
			//TODO load according byte count
			if(comand.haveToRead(param))
			{
				auto value = localProgrammRegister.read!uint(cast(uint)(paramOrigin + 4 * param));
				if(!comand.isDirect(param))
				{
					value = generalPourposeRegisters.read!uint(value);
					if(comand.isIndirect(param))
						value = generalPourposeRegisters.read!uint(value);
				}
				calcRegisters[param] = value;
			}
		}
		auto comandDiff = uint.sizeof * (1 + countOfParams);
		localInstruction += comandDiff;
		globalInstruction += comandDiff;
		debug writeln("before:\n", comand, calcRegisters);
		handlerVector[cast(ubyte)(comand & 0xFF)](this);
		debug writeln("after:\n", comand, calcRegisters);
		foreach(param; 0..countOfParams)
		{
			if(comand.haveToWrite(param))
			{
				auto address = localProgrammRegister.read!uint(cast(uint)(paramOrigin + 4 * param));
				if(comand.isDirect(param))
					throw new Exception("Try to write in direct address");
				if(comand.isIndirect(param))
					address = generalPourposeRegisters.read!uint(address);
				generalPourposeRegisters.write(address, cast(uint)calcRegisters[param]);
			}
		}
		debug generalPourposeRegisters.dump(0,8);
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
}

private:

unittest
{
	assert(0 == byteCount(0x0000_0000));
	assert(4 == byteCount(0x4100_1110));
	assert(4 == byteCount(0x4101_1110));
	assert(4 == byteCount(0x4F28_C329));
	assert(1 == byteCount(0x1700_4324));
	assert(2 == byteCount(0x2701_4325));
	assert(4 == byteCount(0x4300_0330));
}

uint byteCount(uint comand)
{
	return (comand & byteCountMask) >> byteCountShift;
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

auto paramsCount(uint comand)
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

ubyte onesCount(T, size_t bitCount = T.sizeof * 8)(T number)
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

alias haveToRead = isSpecifiedBitFlagged!(readFlagsMask, readFlagsShift);
alias haveToWrite = isSpecifiedBitFlagged!(writeFlagsMask, writeFlagsShift);
alias isDirect = isSpecifiedBitFlagged!(directFlagsMask, directFlagsShift);
alias isIndirect = isSpecifiedBitFlagged!(indirectFlagsMask, indirectFlagsShift);

bool isSpecifiedBitFlagged(uint mask, uint shift)(uint comand, int operandNumer)
{
	return cast(bool)(((comand & mask) >> shift) & (1u << operandNumer));
}

alias HandlerType = void function(ref ProcessorCore);

HandlerType[OperationCode.max + 1] initializeHandlerVector()
{
	import std.traits;
	typeof(return) result;
	foreach(m; EnumMembers!OperationCode)
		result[m] = &handler!m;
	foreach(ref e; result)
		if(e is null)
			e = &handler!(OperationCode.INVALID);
	return result;
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.NOP)
{
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.INVALID)
{
	throw new Exception("impossible opcode");
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.NOT)
{
	pc.calcRegisters[1] = ~pc.calcRegisters[0];
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.SYSCALL)
{
	//TODO system call handler
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.AND)
{
	pc.calcRegisters[2] = pc.calcRegisters[0] & pc.calcRegisters[1];
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.OR)
{
	pc.calcRegisters[2] = pc.calcRegisters[0] | pc.calcRegisters[1];
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.XOR)
{
	pc.calcRegisters[2] = pc.calcRegisters[0] ^ pc.calcRegisters[1];
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.SHL)
{
	//TODO logical left shift handler
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.SHR)
{
	//TODO logical right shift handler
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.SAL)
{
	//TODO arithmetic left shift handler
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.SAR)
{
	//TODO arithmetic right shift handler
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.SCL)
{
	//TODO cyclic left shift handler
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.SCR)
{
	//TODO cyclic rigt shift handler
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.INC)
{
	//TODO increment handler
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.DEC)
{
	//TODO decrement handler
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.IPADD)
{
	//TODO inplace addition handler
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.IPSUB)
{
	//TODO inplace substraction handler
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.ADD)
{
	//TODO addition handler
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.SUB)
{
	//TODO substraction handler
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.UMUL)
{
	//TODO unsigned multiplication handler
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.UDIV)
{
	//TODO unsigned division handler
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.MUL)
{
	//TODO signed multiplication handler
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.DIV)
{
	//TODO signed division handler
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.CMP)
{
	pc.calcRegisters[2] = pc.calcRegisters[0] - pc.calcRegisters[1];
	pc.flags |= equalFlag;
	if(pc.calcRegisters[2] != 0)
		pc.flags ^= equalFlag;

	pc.flags |= greatFlag;
	if(pc.calcRegisters[2] <= 0)
		pc.flags ^= greatFlag;

	pc.flags |= lessFlag;
	if(pc.calcRegisters[2] >= 0)
		pc.flags ^= lessFlag;
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.JMP)
{
	pc.jumpImplementation();
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.JE)
{
	if (pc.flags & 1u)
		pc.jumpImplementation();
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.JNE)
{
	if (!(pc.flags & 1u))
		pc.jumpImplementation();
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.JGR)
{
	//TODO jumpIfGreat handler
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.JLS)
{
	//TODO jumpIfLess handler
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.JHG)
{
	//TODO jumpIfHigh handler
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.JLW)
{
	//TODO jumpIfLow handler
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.MOV)
{
	//TODO move handler
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.INT)
{
	//TODO iterruption handler
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.SLI)
{
	//TODO enable interruption handler
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.CLI)
{
	//TODO disable interruption handler
}

void handler(ubyte opcode)(ref ProcessorCore pc)
	if(opcode == OperationCode.HLT)
{
	// TODO halt handler
}

void jumpImplementation(ref ProcessorCore pc)
{
	auto diff = cast(long)pc.globalInstruction - cast(long)pc.calcRegisters[0];
	pc.localInstruction -= diff;
	pc.globalInstruction -= diff;
}

