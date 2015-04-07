module gsvm.models.storage;

import std.conv;

unittest
{
	auto mem = new Storage(0x100);

	assert(mem.read(0x0) == 0);
	assert(mem.read(0xFF) == 0);

	mem.write(0xFF, uint.max);
	assert(mem.read(0xFF) == uint.max);

	// TODO 
	//mem.write(0xFF, to!uint(int.min));
	//assert(to!int(mem.read(0xFF)) == int.min);

	uint[] data = [0x0000_00FF,
	               0x0000_0000,
	               0x1000_0000,
	               0x1F00_0000];

	mem.write(0x0, data);

	assert(data == mem.read(0x0, to!uint(data.length)));
	assert(!(data == mem.read(0x1, to!uint(data.length))));
}

class Storage
{
private:
	uint[] storage = null;

public:
	this(uint mem_size)
	{
		this.storage = new uint[mem_size];
	}

	uint length()
	{
		return to!uint(storage.length);
	}

	void write(uint addr, uint val)
	{
		this.storage[addr] = val;
	}

	void write(uint start_addr, uint[] data)
	{
		assert(start_addr + data.length <= storage.length);
		for (uint i = start_addr; i < start_addr + data.length; ++i)
		{
			storage[i] = data[i - start_addr];
		}
	}

	uint read(uint addr)
	{
		return this.storage[addr];
	}

	uint[] read(uint start_addr, uint count)
	{
		assert(start_addr + count < storage.length);
		uint[] data;
		for (uint i = start_addr; i < start_addr + count; ++i)
		{
			data ~= storage[i];
		}
		return data;
	}
}

