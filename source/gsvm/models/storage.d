module gsvm.models.storage;

import std.conv;

unittest
{
	auto mem = new Storage(0x100);

	assert(mem.read(0x0) == to!ulong(0));
	assert(mem.read(0xFF) == to!ulong(0));

	mem.write(0xFF, ulong.max);
	assert(mem.read(0xFF) == ulong.max);

	// TODO 
	// mem.write(0xFF, to!ulong(long.min));
	// assert(mem.read(0xFF) == to!ulong(long.min));

	ulong[] data = [0x0000_0000_0000_00FF,
	                0x0000_0000_0000_0000,
	                0x1000_0000_0000_0000,
	                0x1F00_0000_0000_0000];

	mem.write(0x0, data);

	assert(data == mem.read(0x0, data.length));
	assert(!(data == mem.read(0x1, data.length)));
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

	ulong length()
	{
		return storage.length;
	}

	void write(ulong addr, ulong val)
	{
		this.storage[addr] = val;
	}

	void write(ulong start_addr, ulong[] data)
	{
		assert(start_addr + data.length <= storage.length);
		for (ulong i = start_addr; i < start_addr + data.length; ++i)
		{
			storage[i] = data[i - start_addr];
		}
	}

	ulong read(ulong addr)
	{
		return this.storage[addr];
	}

	ulong[] read(ulong start_addr, ulong count)
	{
		assert(start_addr + count < storage.length);
		ulong[] data;
		for (ulong i = start_addr; i < start_addr + count; ++i)
		{
			data ~= storage[i];
		}
		return data;
	}
}

