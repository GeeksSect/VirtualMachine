module gsvm.vm;

import gsvm.models.storage;

import std.conv;

unittest
{
	ulong mem_size = 0x100000;
	
	auto machine = new VM();
	ulong[] programm = [0x0000_0000_0000_00FF,
		0x0000_0000_0000_0000,
		0x1000_0000_0000_0000,
		0x1F00_0000_0000_0000];
	
	ulong[] some_value = [0x0000_0000_0000_FF00];
	
	machine.loadToMemory(to!ulong(0), programm);
	machine.loadToMemory(mem_size - 1, some_value);
	
	machine.startExecution(1);
}

class VM
{
private:
	static const ulong default_mem_size = 0x100000;

	/* Commands:
	 *     NOP 0x00 empty iteration of VM
	 * 
	 *     HLT 0x1F terminate execution
	 */
	enum Command
	{
		NOP = 0x00,
		ADD = 0x10,
		HLT = 0x1F,
	}

	// memory
	ulong mem_size = this.default_mem_size;
	Storage memory = null;
	// instruction register
	ulong reg_I = 0;
	// address register
	ulong reg_A = 0;

public:
	this(ulong mem_size = this.default_mem_size)
	{
		this.mem_size = mem_size;
		this.memory = new Storage(mem_size);

		// Registers initialization
		reg_I = 0;
		reg_A = mem_size - 1; // temporary stub

		assert(!(this.memory is null));
	}

	void startExecution(ulong start_addr = 0)
	{
		assert(start_addr <= mem_size);
		reg_I = start_addr;

		while (reg_I != mem_size)
		{
			ulong cur_word = memory.read(reg_I);
			auto cur_cmd = cur_word >> 56;
			switch (cur_cmd)
			{
				case Command.NOP:
					++reg_I;
					break;
				case Command.ADD:
					auto addr = cur_word & (to!ulong(1) << 41);
					auto temp = memory.read(reg_A);
					temp += memory.read(addr);
					memory.write(reg_A, temp);
					++reg_I;
					break;
				case Command.HLT:
					return;
				default:
			}
		}
	}

	void loadToMemory(ulong start_pos, ulong[] data)
	{
		assert(this.mem_size >= start_pos + data.length);
		for (ulong i = start_pos; i < start_pos + data.length; ++i)
		{
			memory.write(i, data[i - start_pos]);
		}
	}
}

