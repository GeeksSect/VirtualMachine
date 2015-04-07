module gsvm.vm;

import gsvm.models.storage;

import std.conv;

unittest
{
	uint mem_size = 0x100000;

	auto machine = new VM();
	uint[] programm = [0x0000_00FF,  // NOP
	                   0x0010_0000,  // SUM 0x00000000 0x00001111
	                   0x0000_0000,  // ADDR
	                   0x0000_1111,  // ADDR
		               0x0008_0000,  // INC 0x00000000
		               0x0000_0000,  // ADDR
		               0x0008_0000,  // INC 0x00000000
		               0x0000_0000,  // ADDR
		               0x0008_0000,  // INC 0x00000000
		               0x0000_0000,  // ADDR 
		               0x0009_0000,  // DEC 0x00000000
		               0x0000_0000,  // ADDR 
		               0x0009_0000,  // DEC 0x00000000
		               0x0000_0000,  // ADDR 
	                   0x001E_0000]; // HLT
	
	uint[] some_value = [0x0000_FF00];

	Storage ram = new Storage(mem_size);
	ram.write(0, programm);
	ram.write(0x0000_1111, some_value);

	machine.connectStorage(ram);
	machine.startExecution();

	/* TODO each command of unittest should send output in separate memory location. 
	 * 
	 * !!! 0x0 = reg_A (07.04.2015) 
	 * It is needed to implement register manager 
	 */
	auto sum_check = ram.read(machine.getRegA);
	auto inc_dec_check = ram.read(0x0);

	assert(0x10000 == sum_check);
	assert(0x10000 == inc_dec_check);
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
	enum Command
	{
		NOP     = 0x00,
		MOV     = 0x01,
		ADD     = 0x10,
		SUB     = 0x03,
		MUL     = 0x04,
		UMUL    = 0x05,
		DIV     = 0x06,
		UDIV    = 0x07,
		INC     = 0x08,
		DEC     = 0x09,
		AND     = 0x0A,
		OR      = 0x0B,
		XOR     = 0x0C,
		NOT     = 0x0D,
		SHL     = 0x0E,
		SHR     = 0x0F,
		SAR     = 0x10,
		SAL     = 0x11,
		// SCL  = 0xXX,
		// SCR  = 0xXX,
		JMP     = 0x12,
		CMP     = 0x13,
		JE      = 0x14,
		JNE     = 0x15,
		JGR     = 0x16,
		JLS     = 0x17,
		JHG     = 0x18,
		JLW     = 0x19,
		INT     = 0x1A,
		SYSCALL = 0x1B,
		CLI     = 0x1C,
		SLI     = 0x1D,
		HLT     = 0x1E,
	}

	// memory
	uint mem_size = this.default_mem_size;
	Storage memory = null;
	// instruction register
	uint reg_I = 0;
	// address register
	uint reg_A = 0;

public:
	this(uint mem_size = this.default_mem_size)
	{
		this.mem_size = mem_size;
		this.memory = new Storage(mem_size);

		// Registers initialization
		reg_I = 0;
		reg_A = 0; 

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

		while (reg_I != mem_size)
		{
			auto cur_word = memory.read(reg_I);
			auto cur_cmd = cur_word >> 16;

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
					
					auto temp = to!int(memory.read(addr_1));
					temp -= to!int(memory.read(addr_2));
					memory.write(addr_1, to!uint(temp));
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
				case Command.NOT:
					++reg_I;
					auto addr = memory.read(reg_I);
					
					auto temp = ~(memory.read(addr));
					memory.write(addr, temp);
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

