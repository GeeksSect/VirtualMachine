module gsvm.vm;

import gsvm.models.storage;

import std.conv;
import std.stdio;

unittest
{
	uint mem_size = 0x100000;

	auto machine = new VM();
	uint[] programm = [
		0x0000_0000,  // NOP
		0x0000_0024,  // ADD 0x00000000 0x00001111
		0x0000_0000,  // ADDR
		0x0000_1111,  // ADDR
		0x0000_0020,  // INC 0x00000000
		0x0000_0000,  // ADDR
		0x0000_0020,  // INC 0x00000000
		0x0000_0000,  // ADDR
		0x0000_0020,  // INC 0x00000000
		0x0000_0000,  // ADDR 
		0x0000_0021,  // DEC 0x00000000
		0x0000_0000,  // ADDR 
		0x0000_0021,  // DEC 0x00000000
		0x0000_0000,  // ADDR 
		0x0000_0040,  // CMP 0x00050000 0x00000000 (0x00050000 - special addr for CMP test)
		0x0005_0000,  // ADDR
		0x0000_0000,  // ADDR
		0x0000_0042,  // JE 0x00000015 (SUB)
		0x0000_0015,  // ADDR
		0x0000_0041,  // JMP 0x00000004 (first INC)
		0x0000_0004,  // ADDR
		0x0000_0025,  // SUB 0x00001111 0x00000003
		0x0000_1111,  // ADDR
		0x0000_0003,  // ADDR
		0x0000_0010,  // NOT 0x0001000
		0x0001_0000,  // ADDR
		0x0000_0011,  // AND 0x0002000 0x00020001
		0x0002_0000,  // ADDR
		0x0002_0001,  // ADDR
		0x0000_0012,  // OR 0x0003000 0x00030001
		0x0003_0000,  // ADDR
		0x0003_0001,  // ADDR
		0x0000_0013,  // XOR 0x0004000 0x00040001
		0x0004_0000,  // ADDR
		0x0004_0001,  // ADDR
		0x0000_008F]; // HLT
	
	uint[] some_value = [0x0000_FFFF];

  	uint[] for_bin_op = [0x0011_0101,
	                     0x1100_1111];

	uint[] for_jmp = [0x0001_0001];

	Storage ram = new Storage(mem_size);
	ram.write(0, programm);
	ram.write(0x0000_1111, some_value); // for ADD
	ram.write(0x0001_0000, for_bin_op); // for NOT
	ram.write(0x0002_0000, for_bin_op); // for AND
	ram.write(0x0003_0000, for_bin_op); // for OR
	ram.write(0x0004_0000, for_bin_op); // for XOR
	ram.write(0x0005_0000, for_jmp); // for JMP, JN, CMP

	machine.connectStorage(ram);
	machine.startExecution();

	/* TODO each command of unittest should send output in separate memory location. 
	 * 
	 * !!! 0x0 = reg_A (07.04.2015) 
	 * It is needed to implement register manager 
	 */
	auto add_check = ram.read(machine.getRegA);
	assert(0x10001 == add_check);

	auto sub_check = ram.read(0x1111);
	assert(0xEEEE == sub_check);

	auto inc_dec_check = ram.read(0x0);
	assert(0x10001 == inc_dec_check);

	auto not_check = ram.read(0x00010000);
	assert(0xFFEE_FEFE == not_check);

	auto and_check = ram.read(0x00020000);
	assert(0x0000_0101 == and_check);

	auto or_check  = ram.read(0x00030000);
	assert(0x1111_1111 == or_check);

	auto xor_check = ram.read(0x00040000);
	assert(0x1111_1010 == xor_check);
}

class VM
{
private:
	static const uint default_mem_size = 0x100000;

	/* Commands:
	 * 
	 *     NOP 0x00 empty iteration of VM
	 * 
	 *     HLT 0x1F terminate execution
	 */
	// гляньце таксама маю апошнюю ідэю наконт каманд
	enum Command
	{
		NOP     = 0x00,
		MOV     = 0x01,

		INC     = 0x20,
		DEC     = 0x21,
		ADD     = 0x24,
		SUB     = 0x25,
		UMUL    = 0x28,
		UDIV    = 0x29,
		MUL     = 0x2C,
		DIV     = 0x2D,

		NOT     = 0x10,
		AND     = 0x11,
		OR      = 0x12,
		XOR     = 0x13,
		SHL     = 0x14,
		SHR     = 0x15,
		SAL     = 0x16,
		SAR     = 0x17,
		SCL     = 0x18,
		SCR     = 0x19,

		CMP     = 0x40, // TODO case with negative result
		JMP     = 0x41,
		JE      = 0x42,
		JNE     = 0x43,
		JGR     = 0x44,
		JLS     = 0x45,
		JHG     = 0x46,
		JLW     = 0x47,

		SYSCALL = 0x81,
		INT     = 0x82,
		SLI     = 0x88,
		CLI     = 0x8C,
		HLT     = 0x8F,
	}

	// memory
	uint mem_size = this.default_mem_size;
	Storage memory = null;
	// instruction register
	uint reg_I = 0;
	// address register
	uint reg_A = 0;
	// compare register
	uint reg_C = 0x0009_1996; // magic number. Temporary stub for CMP 

public:
	this(uint mem_size = this.default_mem_size)
	{
		this.mem_size = mem_size;
		this.memory = new Storage(mem_size);

		// Registers initialization
		reg_I = 0;
		reg_A = 0; 
		reg_C = 0x0009_1996;

		assert(this.memory !is null);
	}

	uint getRegI()
	{
		return reg_I;
	}

	uint getRegA()
	{
		return reg_A;
	}

	uint getRegC()
	{
		return reg_C;
	}

	void connectStorage(Storage mem)
	{
		assert(mem !is null);

		this.mem_size = mem.length;
		this.memory = mem;
	}

	void startExecution(uint start_addr = 0)
	{
		assert(start_addr <= mem_size);
		reg_I = start_addr;

		// TODO case when (reg_I = mem_size - 1) and it is command which take 2 arguments
		while (reg_I != mem_size)
		{
			auto cur_word = memory.read(reg_I);
			auto cur_cmd = cur_word & 0xFF;

			/* TODO
			 * Commands should place result in registers, not in operands.
			 */
			switch (cur_cmd)
			{
				case Command.NOP:
					++reg_I;
					break;

				case Command.MOV:
					++reg_I;
					auto addr_1 = memory.read(reg_I);
					++reg_I;
					auto addr_2 = memory.read(reg_I);

					auto val_1 = memory.read(addr_1);
					auto val_2 = memory.read(addr_2);

					memory.write(addr_1, val_2);
					memory.write(addr_2, val_1);

					++reg_I;
					break;

				case Command.INC:
					++reg_I;
					auto addr = memory.read(reg_I); //TODO
					
					auto temp = memory.read(addr);
					++temp;
					memory.write(addr, temp);
					++reg_I;
					break;

				case Command.DEC:
					++reg_I;
					auto addr = memory.read(reg_I); //TODO
					
					auto temp = memory.read(addr);
					--temp;
					memory.write(addr, temp);
					++reg_I;
					break;

				case Command.ADD:
					++reg_I;
					auto addr_1 = memory.read(reg_I);
					++reg_I;
					auto addr_2 = memory.read(reg_I);

					auto temp = to!int(memory.read(addr_1));
					temp += to!int(memory.read(addr_2));
					memory.write(addr_1, to!uint(temp));
					++reg_I;
					break;

				case Command.SUB:
					++reg_I;
					auto addr_1 = memory.read(reg_I);
					++reg_I;
					auto addr_2 = memory.read(reg_I);
					
					auto temp = to!int(memory.read(addr_1)); // TODO uint to int convertion
					temp -= to!int(memory.read(addr_2));
					memory.write(addr_1, to!uint(temp));
					++reg_I;
					break;

				case Command.NOT:
					++reg_I;
					auto addr = memory.read(reg_I);
					
					auto temp = ~(memory.read(addr));
					memory.write(addr, temp);
					++reg_I;
					break;

				case Command.AND:
					++reg_I;
					auto addr_1 = memory.read(reg_I);
					++reg_I;
					auto addr_2 = memory.read(reg_I);
					
					auto temp = memory.read(addr_1);
					temp &= memory.read(addr_2);
					memory.write(addr_1, temp);
					++reg_I;
					break;

				case Command.OR:
					++reg_I;
					auto addr_1 = memory.read(reg_I);
					++reg_I;
					auto addr_2 = memory.read(reg_I);
					
					auto temp = memory.read(addr_1);
					temp |= memory.read(addr_2);
					memory.write(addr_1, temp);
					++reg_I;
					break;

				case Command.XOR:
					++reg_I;
					auto addr_1 = memory.read(reg_I);
					++reg_I;
					auto addr_2 = memory.read(reg_I);
					
					auto temp = memory.read(addr_1);
				    temp ^= memory.read(addr_2);
					memory.write(addr_1, temp);
					++reg_I;
					break;

				case Command.CMP:
					++reg_I;
					auto addr_1 = memory.read(reg_I);
					++reg_I;
					auto addr_2 = memory.read(reg_I);

					auto temp = memory.read(addr_1) - memory.read(addr_2);
					memory.write(reg_C, temp); // write answer to specified register
					++reg_I;
					break;

				case Command.JMP:
					++reg_I;
					auto addr = memory.read(reg_I);
					reg_I = addr;
					break;

				case Command.JE:
					++reg_I;
					auto addr = memory.read(reg_I);
					if (memory.read(reg_C) == 0)
						reg_I = addr;
					else
						++reg_I;
					break;

				case Command.JNE:
					++reg_I;
					auto addr = memory.read(reg_I);
					if (memory.read(reg_C) != 0)
						reg_I = addr;
					else
						++reg_I;
					break;

				case Command.HLT:
					return;

				default:
					throw new Exception("Unknown opcode");
			}
		}
	}

	void loadToMemory(uint start_pos, uint[] data)
	{
		assert(this.mem_size >= start_pos + data.length);
		for (uint i = start_pos; i < start_pos + data.length; ++i)
		{
			memory.write(i, data[i - start_pos]);
		}
	}
}

