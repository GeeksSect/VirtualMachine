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

enum TypeOfStorage : ubyte {GPR = 0x1u, Programm, RAM}

/** 
 * struct for emulating cash and memory
 * 
 * N.B! Little endian
 */
struct Storage
{
public: 
	TypeOfStorage typeOfStorage;

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
	this(uint memorySize, TypeOfStorage typeOfStorage)
	in
	{
		assert(memorySize % uint.sizeof == 0, "memory isn't aliquote size of the machine word");
		assert(typeOfStorage == TypeOfStorage.Programm
			&& (memorySize >>> 1) % uint.sizeof == 0, 
			"for programm memory half of it have to be aliquote size of the machine word");
	}
	body
	{
		storage = new ubyte[memorySize];
		this.typeOfStorage = typeOfStorage;
	}

	uint length() @property pure @safe
	{
		return to!uint(storage.length);
	}

	void write(T)(uint addr, T val) pure nothrow @nogc @safe
		if(is(T == ubyte) || is(T == ushort) || is(T == uint))
	in
	{
		assert(addr <= storage.length - T.sizeof, "impossible write address");
		assert(addr % T.sizeof == 0, "impossible alligment");
	}
	body
	{
		foreach(i; 0..T.sizeof)
		{
			T mask = maskValue;
			storage[addr + i] = cast(ubyte)((val & (mask << i * bitInByte)) >>> i * bitInByte);
		}
	}

	void write(uint startAddr, immutable(ubyte)[] data)
	in
	{
		assert(typeOfStorage != TypeOfStorage.RAM, "this type of memory doesn't support range write");
		assert(startAddr + data.length < storage.length, "impossible range for write");
	}
	body
	{
		foreach(addr, sendedByte; data)
			storage[startAddr + addr] = sendedByte;
	}

	T read(T)(uint addr) pure nothrow @nogc @safe
		if(is(T == ubyte) || is(T == ushort) || is(T == uint))
	in
	{
		assert(addr <= storage.length - T.sizeof, "impossible read address");
		assert(addr % T.sizeof == 0, "impossible alligment");
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


	immutable(ubyte)[] read(uint startAddr, uint count)
	in
	{
		assert(typeOfStorage == TypeOfStorage.RAMStorage, "this type of memory doesn't support range read");
		assert(startAddr + count < storage.length, "impossible range for read");
		assert(startAddr % uint.sizeof == 0, "start address  is misalligned");
		assert(count % uint.sizeof == 0, "start address  is misalligned");
	}
	body
	{
		return storage[startAddr..startAddr+count].idup;
	}

	void shiftHalfLeft()
	in
	{
		assert(typeOfStorage == TypeOfStorage.Programm, "this type of memory doesn't half memory shift");
	}
	body
	{
		auto half = storage.length >>> 1;
		foreach(addr; 0..half)
			storage[addr] = storage[addr + half];
	}

	void shiftHalfRight()
	in
	{
		assert(typeOfStorage == TypeOfStorage.Programm, "this type of memory doesn't half memory shift");
	}
	body
	{
		auto half = storage.length >>> 1;
		foreach(addr; 0..half)
			storage[addr + half] = storage[addr];
	}
}

