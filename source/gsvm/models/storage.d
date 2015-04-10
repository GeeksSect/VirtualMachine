module gsvm.models.storage;

import std.conv;

unittest
{
	// Functional test
	auto mem = new Storage(0x100);
	assert(mem.storage !is null);

	assert(mem.length == 0x100); 

	assert(mem.read!ubyte(0x0) == 0u);
	assert(mem.read!ushort(0x0) == 0u);
	assert(mem.read!uint(0x0) == 0u);
	assert(mem.read!ubyte(0xFF) == 0u);
	assert(mem.read!ushort(0xFE) == 0u);
	assert(mem.read!uint(0xFC) == 0u);

	mem.write(0x00u, 0x1234_ABCDu);
	assert(mem.read!uint(0x00) == 0x1234_ABCDu);
	assert(mem.read!ushort(0x00) == 0xABCDu);
	assert(mem.read!ushort(0x02) == 0x1234u);
	assert(mem.read!ubyte(0x00) == 0xCDu);
	assert(mem.read!ubyte(0x01) == 0xABu);
	assert(mem.read!ubyte(0x02) == 0x34u);
	assert(mem.read!ubyte(0x03) == 0x12u);

	mem.write(0x02u, cast(ushort)0xFEDC);
	assert(mem.read!uint(0x00) == 0xFEDC_ABCDu);
	assert(mem.read!ushort(0x00) == 0xABCDu);
	assert(mem.read!ushort(0x02) == 0xFEDCu);
	assert(mem.read!ubyte(0x00) == 0xCDu);
	assert(mem.read!ubyte(0x01) == 0xABu);
	assert(mem.read!ubyte(0x02) == 0xDCu);
	assert(mem.read!ubyte(0x03) == 0xFEu);

	mem.write(0x03u, cast(ubyte)0x78);
	assert(mem.read!uint(0x00) == 0x78DC_ABCDu);
	assert(mem.read!ushort(0x00) == 0xABCDu);
	assert(mem.read!ushort(0x02) == 0x78DCu);
	assert(mem.read!ubyte(0x00) == 0xCDu);
	assert(mem.read!ubyte(0x01) == 0xABu);
	assert(mem.read!ubyte(0x02) == 0xDCu);
	assert(mem.read!ubyte(0x03) == 0x78u);
}

unittest
{
	// Contract test
	import core.exception;
	
	try
	{
		auto mem = Storage(0x10);
		mem.write(0x10, cast(ubyte)0x1u);
	}
	catch(AssertError ae)
	{
		assert(ae.msg == "imposible write address");
	}

	try
	{
		auto mem = Storage(0x10);
		mem.write(0xF, cast(ushort)0x1u);
	}
	catch(AssertError ae)
	{
		assert(ae.msg == "imposible write address");
	}

	try
	{
		auto mem = Storage(0x10);
		mem.write(0xD, cast(uint)0x1u);
	}
	catch(AssertError ae)
	{
		assert(ae.msg == "imposible write address");
	}

	try
	{
		auto mem = Storage(0x10);
		mem.write(0x2, cast(uint)0x1u);
	}
	catch(AssertError ae)
	{
		assert(ae.msg == "imposible alligment");
	}

	try
	{
		auto mem = Storage(0x10);
		mem.write(0x1, cast(ushort)0x1u);
	}
	catch(AssertError ae)
	{
		assert(ae.msg == "imposible alligment");
	}

	try
	{
		auto mem = Storage(0x10);
		mem.read!ubyte(0x10);
	}
	catch(AssertError ae)
	{
		assert(ae.msg == "imposible read address");
	}

	try
	{
		auto mem = Storage(0x10);
		mem.read!ushort(0xF);
	}
	catch(AssertError ae)
	{
		assert(ae.msg == "imposible read address");
	}

	try
	{
		auto mem = Storage(0x10);
		mem.read!uint(0xD);
	}
	catch(AssertError ae)
	{
		assert(ae.msg == "imposible read address");
	}

	try
	{
		auto mem = Storage(0x10);
		mem.read!uint(0x2);
	}
	catch(AssertError ae)
	{
		assert(ae.msg == "imposible alligment");
	}

	try
	{
		auto mem = Storage(0x10);
		mem.read!ushort(0x1);
	}
	catch(AssertError ae)
	{
		assert(ae.msg == "imposible alligment");
	}
}

unittest
{
	// Constraint test
	import std.traits;
	static assert(__traits(compiles,
			{
				auto mem = Storage(0x10);
				mem.read!ubyte(0x00);
				mem.read!ushort(0x00);
				mem.read!uint(0x00);
				mem.write(0x00, cast(ubyte)0xFF);
				mem.write(0x00, cast(ushort)0xFF);
				mem.write(0x00, 0xFFu);
			}));
	static assert(!__traits(compiles,
			{
				auto mem = Storage(0x10);
				mem.read!byte(0x00);
			}));
	static assert(!__traits(compiles,
			{
				auto mem = Storage(0x10);
				mem.read!byte(0x00);
			}));
	static assert(!__traits(compiles,
			{
				auto mem = Storage(0x10);
				mem.read!int(0x00);
			}));
	static assert(!__traits(compiles,
			{
				auto mem = Storage(0x10);
				mem.read!ulong(0x00);
			}));
	static assert(!__traits(compiles,
			{
				auto mem = Storage(0x10);
				mem.write(0x00, cast(byte)0xFF);
			}));
	static assert(!__traits(compiles,
			{
				auto mem = Storage(0x10);
				mem.write(0x00, cast(int)0xFF);
			}));
	static assert(!__traits(compiles,
			{
				auto mem = Storage(0x10);
				mem.write(0x00, cast(ulong)0xFF);
			}));
}

/** 
 * struct for emulating cash and memory
 * 
 * N.B! Little endian
 */
struct Storage
{
private:
	ubyte[] storage; // null is init for arrays

	unittest
	{
		static assert(maskValue == 0xFF);
		assert(0xFF == generateMask(8));
	}

	enum ubyte bitInByte = 8;
	enum ubyte maskValue = generateMask(bitInByte);

	static ubyte generateMask(ubyte bitInByte)pure nothrow @nogc @safe
	{
		typeof(return) result;
		foreach(i; 0..bitInByte)
			result |= 1u << i;
		return result;
	}

public:
	this(uint mem_size)
	{
		this.storage = new ubyte[mem_size];
	}

	uint length() @property pure @safe
	{
		return to!uint(storage.length);
	}

	void write(T)(uint addr, T val) pure nothrow @nogc @safe
		if(is(T == ubyte) || is(T == ushort) || is(T == uint))
	in
	{
		assert(addr <= storage.length - T.sizeof, "imposible write address");
		assert(addr % T.sizeof == 0, "imposible alligment");
	}
	body
	{
		foreach(i; 0..T.sizeof)
		{
			T mask = maskValue;
			storage[addr + i] = cast(ubyte)((val & (mask << i * bitInByte)) >>> i * bitInByte);
		}
	}

	// не ўпэўнены што існуе апаратны адпаведнік
	/+void write(uint start_addr, uint[] data)
	{
		assert(start_addr + data.length <= storage.length);
		for (uint i = start_addr; i < start_addr + data.length; ++i)
		{
			storage[i] = data[i - start_addr];
		}
	}+/

	T read(T)(uint addr) pure nothrow @nogc @safe
		if(is(T == ubyte) || is(T == ushort) || is(T == uint))
	in
	{
		assert(addr <= storage.length - T.sizeof, "imposible read address");
		assert(addr % T.sizeof == 0, "imposible alligment");
	}
	body
	{
		T result;
		foreach(i; 0..T.sizeof)
		{
			T mask = maskValue;
			result |= (cast(T) storage[addr + i]) << i * bitInByte;
		}
		return result;
	}

	//тое самае
	/+uint[] read(uint start_addr, uint count)
	{
		assert(start_addr + count < storage.length);
		uint[] data;
		for (uint i = start_addr; i < start_addr + count; ++i)
		{
			data ~= storage[i];
		}
		return data;
	}+/
}

