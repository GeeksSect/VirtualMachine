module gsvm.models.storage;

import std.conv;

unittest
{
	auto mem = new Storage(0x100);

	assert(mem.read(0x0) == 0);
	assert(mem.read(0xFF) == 0);

	mem.write(0xFF, uint.max);
	assert(mem.read(0xFF) == uint.max);

	mem.write(0xFF, int.min);
	assert(to!int(mem.read(0xFF)) == int.min);
}

class Storage
{
private:
	ulong[] storage = null;

public:
	this(ulong mem_size)
	{
		this.storage = new ulong[mem_size];
	}

	void write(ulong addr, ulong val)
	{
		this.storage[addr] = val;
	}

	ulong read(ulong addr)
	{
		return this.storage[addr];
	}
}

