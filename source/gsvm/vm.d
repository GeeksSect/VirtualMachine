module gsvm.vm;

import gsvm.models.storage;

import std.conv;

enum OperationCode : ubyte
{
	NOP = 0x00, SYSCALL = 0x01, INVALID = 0x0F,
	
	NOT = 0x10, AND = 0x11, OR = 0x12, XOR = 0x13, SHL = 0x14, SHR = 0x15, SAL = 0x16, SAR = 0x17, SCL = 0x18, SCR = 0x19,

	// IP means in place
	INC = 0x20, DEC = 0x21, IPADD = 0x22, IPSUB = 0x23, ADD = 0x24, SUB = 0x25, UMUL = 0x28, UDIV = 0x29, MUL = 0x2A, DIV = 0x2B,

	CMP = 0x30, JMP = 0x31, JE = 0x32, JNE = 0x33, JGR = 0x34, JLS = 0x35, JHG = 0x36, JLW = 0x37,

	MOV = 0x40, INT = 0x41, SLI = 0x42, CLI = 0x43, HLT = 0x4F
}

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
	ulong first, second, third, fourth;

	long localInstruction = half;
	uint globalInstruction;


	Storage* memory;

	alias HandlerType = void delegate(ubyte byteCount, 
		ref uint firstParametr,
		ref uint secondParametr,
		ref uint thirdParametr,
		ref uint fourthParametr);

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
		handlerVector = new HandlerType[0x03];
		handlerVector[OperationCode.NOP] = &this.nopHandler;
		handlerVector[0x01] = &this.invalidHandler;
		handlerVector[0x02] = &this.notHandler;
	}


	void runOneCommand()
	{
		uint[5] commandWithOperand;
		commandWithOperand[0] = localProgrammRegister.read!uint(cast(uint)localInstruction);
		//TODO calculate real count of operand
		foreach(shift; 1..5)
			commandWithOperand[shift] = generalPourposeRegisters.read!uint(cast(uint)localInstruction + shift);
		handlerVector[cast(ubyte)(commandWithOperand[0] & 0xFF)](4, commandWithOperand[1], commandWithOperand[2], 
			commandWithOperand[3], commandWithOperand[4]);
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
	void nopHandler(ubyte byteCount, 
		ref uint firstParametr,
		ref uint secondParametr,
		ref uint thirdParametr,
		ref uint fourthParametr)
	{
	}

	void invalidHandler(ubyte byteCount, 
		ref uint firstParametr,
		ref uint secondParametr,
		ref uint thirdParametr,
		ref uint fourthParametr)
	{
		throw new Exception("impossible opcode");
	}

	void notHandler(ubyte byteCount, 
		ref uint firstParametr,
		ref uint secondParametr,
		ref uint thirdParametr,
		ref uint fourthParametr)
	{
		first = firstParametr;
		second = ~first;
		secondParametr = cast(uint)second;
		subLoadProgramm();
	}
}


