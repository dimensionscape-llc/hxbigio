package hx.io;
import cpp.UInt8;
import haxe.Int64;
#if HXCPP_M64
	import haxe.extern.EitherType;
	import haxe.io.Bytes;
	import haxe.io.Encoding;
#end

/**
 * ...
 * @author Christopher Speciale
 */

@:cppFileCode('
#define _FILE_OFFSET_BITS 64
#include <stdio.h>
#include <iostream>

#ifndef HX_OS_H
	#define HX_OS_H

	// OS FLAGS
	#if defined(_WIN32)
		#define NEKO_WINDOWS
	#endif

	#if defined(__APPLE__) || defined(__MACH__) || defined(macintosh)
		#define NEKO_MAC
	#endif

	#if defined(linux) || defined(__linux__)
		#define NEKO_LINUX
	#endif

	#if defined(__FreeBSD_kernel__)
		#define NEKO_GNUKBSD
	#endif

	#if defined(__FreeBSD__) || defined(__NetBSD__) || defined(__OpenBSD__)
		#define NEKO_BSD
	#endif

	// COMPILER/PROCESSOR FLAGS
	#if defined(__GNUC__)
		#define NEKO_GCC
	#endif

	#if defined(_MSC_VER)
		#define NEKO_VCC
	#endif

	#if defined(__MINGW32__)
		#define NEKO_MINGW
	#endif

	#if defined(__i386__) || defined(_WIN32)
		#define NEKO_X86
	#endif

	#if defined(__ppc__)
		#define NEKO_PPC
	#endif

	#if defined(_64BITS)
		#define NEKO_64BITS
	#endif

	#if defined(NEKO_LINUX) || defined(NEKO_MAC) || defined(NEKO_BSD) || defined(NEKO_GNUKBSD)
		#define NEKO_POSIX
	#endif

	#if defined(NEKO_GCC)
		#define NEKO_THREADED
		#define NEKO_DIRECT_THREADED
	#endif

	#include <stddef.h>
	#ifndef NEKO_VCC
		#include <stdint.h>
	#endif

	#undef EXPORT
	#undef IMPORT
	#if defined(NEKO_VCC) || defined(NEKO_MINGW)
		#define INLINE __inline
		#define EXPORT __declspec( dllexport )
		#define IMPORT __declspec( dllimport )
	#elif defined (HX_LINUX)
		#define INLINE inline
		#define EXPORT __attribute__ ((visibility("default")))
		#define IMPORT
	#else
		#define INLINE inline
		#define EXPORT __attribute__ ((visibility("default")))
		#define IMPORT
	#endif

	#ifdef NEKO_POSIX
		#include <errno.h>
		#define POSIX_LABEL(name)	name:
		#define HANDLE_EINTR(label)	if( errno == EINTR ) goto label
		#define HANDLE_FINTR(f,label) if( ferror(f) && errno == EINTR ) goto label
	#else
		#define POSIX_LABEL(name)
		#define HANDLE_EINTR(label)
		#define HANDLE_FINTR(f,label)
	#endif

#endif

void file_error(const char *msg, String inName)
{
	hx::ExitGCFreeZone();
	Array<String> err = Array_obj<String>::__new(2, 2);
	err[0] = String(msg);
	err[1] = inName;
	hx::Throw(err);
}

Array<Array<unsigned char>> _hx_std_file_contents_big_bytes(String name)
{
	hx::strbuf buf;
	#ifdef NEKO_WINDOWS
	hx::EnterGCFreeZone();
	FILE *file = _wfopen(name.wchar_str(&buf), L"rb");
	#else
	std::cout << "err" << std::endl;
	hx::EnterGCFreeZone();
	FILE *file = fopen(name.utf8_str(&buf), "rb");
	#endif
	if (!file)
		file_error("file_contents", name);

	_fseeki64(file, 0, SEEK_END);
	long long len = _ftelli64(file);
	if (len < 0)
		file_error("file_ftell", name);

	fseek(file, 0, SEEK_SET);
	hx::ExitGCFreeZone();
	int blocks = 1;
	int remainder = 0;
	int currentLen = 0;
	int MAX_VALUE = 1073741824;

	if (len > MAX_VALUE)
	{
		blocks = len / MAX_VALUE;
		remainder = len % MAX_VALUE;
		currentLen = MAX_VALUE;
		//long long p = 0;
		////////////MORE THAN MAX VALUE///////////////
		Array<Array<unsigned char>> blocksBuffer = Array_obj<Array<unsigned char>>::__new();

		for (int i = 0; i < blocks; i++)
		{
			Array<unsigned char> buffer = Array_obj<unsigned char>::__new(currentLen, currentLen);
			blocksBuffer->push(buffer);

			/////////////DO THE MAX VALUE BUFFERS FIRST

			hx::EnterGCFreeZone();
			if (currentLen)
			{
				int p = 0;
				char *dest = reinterpret_cast<char*>(&buffer[0]);

				while (currentLen > 0)
				{
					POSIX_LABEL(file_contents1);
					int d = fread(dest + p, 1, currentLen, file);
					if (d == 0 && !feof(file))
					{
						if (ferror(file))
						{
							// Error reading file
							perror("fread error");
						}
						HANDLE_FINTR(file, file_contents1);
						fclose(file);
						file_error("file_contents", name);
					}

					p += d;
					currentLen -= d;
				}
			}
		}

		if (remainder > 0)
		{
			/////////////DO THE REMAINDER //////////////////
			currentLen = remainder;
			Array<unsigned char> buffer = Array_obj<unsigned char>::__new(currentLen, currentLen);
			blocksBuffer->push(buffer);

			hx::EnterGCFreeZone();
			if (currentLen)
			{
				int p = 0;

				char *dest = reinterpret_cast<char*>(&buffer[0]);

				while (currentLen > 0)
				{

					POSIX_LABEL(file_contents1);
					int d = fread(dest + p, 1, currentLen, file);
					if (d == 0 && !feof(file))
					{
						if (ferror(file))
						{
							// Error reading file
							perror("fread error");
						}
						HANDLE_FINTR(file, file_contents1);
						fclose(file);
						file_error("file_contents", name);
					}

					p += d;
					currentLen -= d;
				}
			}
		}

		fclose(file);
		hx::ExitGCFreeZone();
		return blocksBuffer;
	}
	else
	{
		//////////////LESS THAN MAX VALUE/////////////
		Array<unsigned char> buffer = Array_obj<unsigned char>::__new(len, len);

		hx::EnterGCFreeZone();
		if (len)
		{
			char *dest = reinterpret_cast<char*>(&buffer[0]);
			int p = 0;

			std::cout << len << std::endl;

			while (currentLen > 0)
			{

				POSIX_LABEL(file_contents1);
				int d = fread(dest + p, 1, len, file);
				if (d == 0 && !feof(file))
				{
					if (ferror(file))
					{
						// Error reading file
						perror("fread error");
					}
					HANDLE_FINTR(file, file_contents1);
					fclose(file);
					file_error("file_contents", name);
				}

				p += d;
				len -= d;
			}
		}
		fclose(file);
		hx::ExitGCFreeZone();
		return buffer;
	}
	return NULL;
}

			  ')
class BigBytes
{

	#if HXCPP_M64
	public static function fromFile(path:String):BigBytes
	{
		var data:Array<Dynamic> = untyped __cpp__('_hx_std_file_contents_big_bytes(path)');
		var bb:BigBytes = null;
		if (data[0][0] == null){
			bb = new BigBytes(data.length);
			bb._setBlockData(0, data);
		} else {
			var size:Int64 = Int64.fromFloat(((data.length - 1.0) * MAX_BYTES_VALUE) + data[data.length - 1].length);
			bb = new BigBytes(size);
			//do multi block
			for (i in 0...data.length){
				bb._setBlockData(i, data[i]);
			}			
		}
		
		return bb;
	}

	private static inline var MAX_BYTES_VALUE:Int = 1073741824;

	public var length(get, null):Int64;

	private var _length:Int64;

	private var bytesArray:Array<Bytes> = [];

	private function get_length():Int64
	{
		return _length;
	}

	public function new(size:Int64)
	{
		var len:Int = Int64.toInt(size / MAX_BYTES_VALUE);
		var rem:Int = Int64.toInt(size / MAX_BYTES_VALUE);

		for (i in 0...len)
		{
			var bytes:Bytes = Bytes.alloc(MAX_BYTES_VALUE);
			bytesArray.push(bytes);
		}

		var bytes:Bytes = Bytes.alloc(rem);
		bytesArray.push(bytes);

		_length = size;
	}

	public function blit(pos:Int64, src:EitherType<Bytes, BigBytes>, srcPos:Int64, len:Int64):Void
	{
		if (Std.isOfType(src, Bytes))
		{
			_blitBytes(pos, src, srcPos.low, len.low);
		}
		else {
			_blitBigBytes(pos, src, srcPos, len);
		}
	}

	public function fill(pos:Int64, len:Int64, value:Int):Void
	{
		var startBlockIndex:Int = _getBytesIndex(pos);
		var endPos:Int64 = pos + len;
		var endBlockIndex:Int = _getBytesIndex(endPos);

		var startBlock:Bytes = bytesArray[startBlockIndex];
		var endBlock:Bytes = bytesArray[endBlockIndex];

		var startBlockPos:Int = Int64.toInt(pos % MAX_BYTES_VALUE);
		var endBlockPos:Int = Int64.toInt(endPos % MAX_BYTES_VALUE);

		if (startBlockIndex == endBlockIndex)
		{
			startBlock.fill(startBlockPos, endBlockPos - startBlockPos, value);
		}
		else {
			startBlock.fill(startBlockPos, MAX_BYTES_VALUE - startBlockPos, value);
			for (i in startBlockIndex + 1...endBlockIndex)
			{
				bytesArray[i].fill(0, MAX_BYTES_VALUE, value);
			}
			endBlock.fill(0, endBlockPos, value);
		}
	}

	public function get(pos:Int64):Int
	{
		var blockIndex:Int = _getBytesIndex(pos);
		var blockPos:Int = Int64.toInt(pos % MAX_BYTES_VALUE);

		var bytes:Bytes = bytesArray[blockIndex];

		return bytes.get(blockPos);
	}

	public function getDouble(pos:Int64):Float
	{
		var blockIndex:Int = _getBytesIndex(pos);
		var blockPos:Int = Int64.toInt(pos % MAX_BYTES_VALUE);

		var bytes:Bytes = bytesArray[blockIndex];

		var blockBytesRemaining:Int = MAX_BYTES_VALUE - blockPos;

		if (blockBytesRemaining >= 8)
		{
			return bytes.getDouble(blockPos);
		}
		else {
			var doubleBytes:Bytes = Bytes.alloc(8);
			for (i in 0...blockBytesRemaining)
			{
				doubleBytes.set(i, bytes.get(blockPos + i));
			}

			var secondBytes:Bytes = bytesArray[blockIndex + 1];
			var doubleBytesRemaining:Int = 8 - blockBytesRemaining;
			for (i in 0...doubleBytesRemaining)
			{
				doubleBytes.set(i, secondBytes.get(i));
			}

			return doubleBytes.getDouble(0);
		}
	}

	public function getFloat(pos:Int64):Float
	{
		var blockIndex:Int = _getBytesIndex(pos);
		var blockPos:Int = Int64.toInt(pos % MAX_BYTES_VALUE);

		var bytes:Bytes = bytesArray[blockIndex];

		var blockBytesRemaining:Int = MAX_BYTES_VALUE - blockPos;

		if (blockBytesRemaining >= 4)
		{
			return bytes.getFloat(blockPos);
		}
		else {
			var floatBytes:Bytes = Bytes.alloc(4);
			for (i in 0...blockBytesRemaining)
			{
				floatBytes.set(i, bytes.get(blockPos + i));
			}

			var secondBytes:Bytes = bytesArray[blockIndex + 1];
			var floatBytesRemaining:Int = 4 - blockBytesRemaining;
			for (i in 0...floatBytesRemaining)
			{
				floatBytes.set(i, secondBytes.get(i));
			}

			return floatBytes.getFloat(0);
		}
	}

	public function getInt32(pos:Int64):Int
	{
		var blockIndex:Int = _getBytesIndex(pos);
		var blockPos:Int = Int64.toInt(pos % MAX_BYTES_VALUE);

		var bytes:Bytes = bytesArray[blockIndex];

		var blockBytesRemaining:Int = MAX_BYTES_VALUE - blockPos;

		if (blockBytesRemaining >= 4)
		{
			return bytes.getInt32(blockPos);
		}
		else {
			var intBytes:Bytes = Bytes.alloc(4);
			for (i in 0...blockBytesRemaining)
			{
				intBytes.set(i, bytes.get(blockPos + i));
			}

			var secondBytes:Bytes = bytesArray[blockIndex + 1];
			var intBytesRemaining:Int = 4 - blockBytesRemaining;
			for (i in 0...intBytesRemaining)
			{
				intBytes.set(i, secondBytes.get(i));
			}

			return intBytes.getInt32(0);
		}
	}

	public function getInt64(pos:Int64):Int64
	{
		var blockIndex:Int = _getBytesIndex(pos);
		var blockPos:Int = Int64.toInt(pos % MAX_BYTES_VALUE);

		var bytes:Bytes = bytesArray[blockIndex];

		var blockBytesRemaining:Int = MAX_BYTES_VALUE - blockPos;

		if (blockBytesRemaining >= 8)
		{
			return bytes.getInt64(blockPos);
		}
		else {
			var intBytes:Bytes = Bytes.alloc(8);
			for (i in 0...blockBytesRemaining)
			{
				intBytes.set(i, bytes.get(blockPos + i));
			}

			var secondBytes:Bytes = bytesArray[blockIndex + 1];
			var intBytesRemaining:Int = 8 - blockBytesRemaining;
			for (i in 0...intBytesRemaining)
			{
				intBytes.set(i, secondBytes.get(i));
			}

			return intBytes.getInt64(0);
		}
	}

	public function getString(pos:Int64, len:Int64, ?encoding:Encoding):String
	{
		var blockIndex:Int = _getBytesIndex(pos);
		var blockPos:Int = Int64.toInt(pos % MAX_BYTES_VALUE);

		var bytes:Bytes = bytesArray[blockIndex];

		var remainingLen:Int64 = len;
		var result:String = "";

		while (remainingLen > 0)
		{
			var bytesToRead:Int = Std.int(Math.min(Int64.toInt(remainingLen), MAX_BYTES_VALUE - blockPos));
			var substring:String = bytes.getString(blockPos, bytesToRead, encoding);
			result += substring;

			remainingLen -= bytesToRead;
			blockIndex++;
			blockPos = 0;
			bytes = bytesArray[blockIndex];
		}

		return result;
	}

	public function getUInt16(pos:Int64):Int
	{
		var blockIndex:Int = _getBytesIndex(pos);
		var blockPos:Int = Int64.toInt(pos % MAX_BYTES_VALUE);

		var bytes:Bytes = bytesArray[blockIndex];

		if (blockPos + 1 >= MAX_BYTES_VALUE)
		{
			var byte1:Int = bytes.get(blockPos) & 0xFF;

			var nextBlock:Bytes = bytesArray[blockIndex + 1];

			var byte2:Int = nextBlock.get(0) & 0xFF;

			return (byte2 << 8) | byte1;
		}
		else {
			var byte1:Int = bytes.get(blockPos) & 0xFF;
			var byte2:Int = bytes.get(blockPos + 1) & 0xFF;

			return (byte2 << 8) | byte1;
		}
	}

	public function set(pos:Int64, v:Int):Void
	{
		var blockIndex:Int = _getBytesIndex(pos);
		var blockPos:Int = Int64.toInt(pos % MAX_BYTES_VALUE);

		var bytes:Bytes = bytesArray[blockIndex];

		bytes.set(blockPos, v);
	}

	public function setDouble(pos:Int64, v:Float):Void
	{
		var blockIndex:Int = _getBytesIndex(pos);
		var blockPos:Int = Int64.toInt(pos % MAX_BYTES_VALUE);

		var bytes:Bytes = bytesArray[blockIndex];

		var blockBytesRemaining:Int = MAX_BYTES_VALUE - blockPos;

		if (blockBytesRemaining >= 8)
		{
			return bytes.setDouble(blockPos, v);
		}
		else {
			var doubleBytes:Bytes = Bytes.alloc(8);
			doubleBytes.setDouble(0, v);

			bytes.blit(blockPos, doubleBytes, 0, blockBytesRemaining);

			var doubleBytesRemaining:Int = 8 - blockBytesRemaining;
			var secondBytes:Bytes = bytesArray[blockIndex + 1];

			secondBytes.blit(0, doubleBytes, 0, doubleBytesRemaining);
		}
	}

	public function setFloat(pos:Int64, v:Float):Void
	{
		var blockIndex:Int = _getBytesIndex(pos);
		var blockPos:Int = Int64.toInt(pos % MAX_BYTES_VALUE);

		var bytes:Bytes = bytesArray[blockIndex];

		var blockBytesRemaining:Int = MAX_BYTES_VALUE - blockPos;

		if (blockBytesRemaining >= 4)
		{
			return bytes.setFloat(blockPos, v);
		}
		else {
			var floatBytes:Bytes = Bytes.alloc(4);
			floatBytes.setFloat(0, v);

			bytes.blit(blockPos, floatBytes, 0, blockBytesRemaining);

			var floatBytesRemaining:Int = 4 - blockBytesRemaining;
			var secondBytes:Bytes = bytesArray[blockIndex + 1];

			secondBytes.blit(0, floatBytes, 0, floatBytesRemaining);
		}
	}

	public function setInt32(pos:Int64, v:Int):Void
	{
		var blockIndex:Int = _getBytesIndex(pos);
		var blockPos:Int = Int64.toInt(pos % MAX_BYTES_VALUE);

		var bytes:Bytes = bytesArray[blockIndex];

		var blockBytesRemaining:Int = MAX_BYTES_VALUE - blockPos;

		if (blockBytesRemaining >= 4)
		{
			return bytes.setInt32(blockPos, v);
		}
		else {
			var intBytes:Bytes = Bytes.alloc(4);
			intBytes.setInt32(0, v);
			bytes.blit(blockPos, intBytes, 0, blockBytesRemaining);
			var intBytesRemaining:Int = 4 - blockBytesRemaining;
			var secondBytes:Bytes = bytesArray[blockIndex + 1];
			secondBytes.blit(0, intBytes, 0, intBytesRemaining);
		}
	}

	public function setInt64(pos:Int64, v:Int64):Void
	{
		var blockIndex:Int = _getBytesIndex(pos);
		var blockPos:Int = Int64.toInt(pos % MAX_BYTES_VALUE);

		var bytes:Bytes = bytesArray[blockIndex];

		var blockBytesRemaining:Int = MAX_BYTES_VALUE - blockPos;

		if (blockBytesRemaining >= 8)
		{
			return bytes.setInt64(blockPos, v);
		}
		else {
			var intBytes:Bytes = Bytes.alloc(8);
			intBytes.setInt64(0, v);

			bytes.blit(blockPos, intBytes, 0, blockBytesRemaining);

			var intBytesRemaining:Int = 8 - blockBytesRemaining;
			var secondBytes:Bytes = bytesArray[blockIndex + 1];

			secondBytes.blit(0, intBytes, 0, intBytesRemaining);
		}
	}

	public function setUInt16(pos:Int64, v:Int):Void
	{
		var blockIndex:Int = _getBytesIndex(pos);
		var blockPos:Int = Int64.toInt(pos % MAX_BYTES_VALUE);

		var bytes:Bytes = bytesArray[blockIndex];

		var blockBytesRemaining:Int = MAX_BYTES_VALUE - blockPos;

		if (blockBytesRemaining >= 2)
		{
			return bytes.setUInt16(blockPos, v);
		}
		else {
			var uIntBytes:Bytes = Bytes.alloc(2);
			uIntBytes.setUInt16(0, v);

			bytes.blit(blockPos, uIntBytes, 0, blockBytesRemaining);

			var uIntBytesRemaining:Int = 2 - blockBytesRemaining;
			var secondBytes:Bytes = bytesArray[blockIndex + 1];

			secondBytes.blit(0, uIntBytes, 0, uIntBytesRemaining);
		}
	}

	private function _blitBytes(pos:Int64, src:Bytes, srcPos:Int, len:Int):Void
	{
		var blockIndex:Int = _getBytesIndex(pos);
		var bytes:Bytes = bytesArray[blockIndex];
		var blockPos:Int = Int64.toInt(pos % MAX_BYTES_VALUE);

		var blockBytesRemaining:Int = MAX_BYTES_VALUE - blockPos;

		if (len <= blockBytesRemaining)
		{
			bytes.blit(blockPos, src, srcPos, len);
		}
		else {
			bytes.blit(blockPos, src, srcPos, blockBytesRemaining);

			var secondBytes:Bytes = bytesArray[blockIndex + 1];
			var totalBytesRemaining:Int = len - blockBytesRemaining;
			secondBytes.blit(0, src, 0, totalBytesRemaining);
		}
	}

	private function _blitBigBytes(pos:Int64, src:BigBytes, srcPos:Int64, len:Int64):Void
	{
		var destBlockIndex:Int = _getBytesIndex(pos);
		var destBlockPos:Int = Int64.toInt(pos % MAX_BYTES_VALUE);

		var srcBlockIndex:Int = src._getBytesIndex(srcPos);
		var srcBlockPos:Int = Int64.toInt(srcPos % MAX_BYTES_VALUE);

		var bytesToCopy:Int64 = len;

		while (bytesToCopy > 0)
		{
			var destBlock:Bytes = bytesArray[destBlockIndex];
			var srcBlock:Bytes = src.bytesArray[srcBlockIndex];

			var bytesInDestBlock:Int = MAX_BYTES_VALUE - destBlockPos;
			var bytesInSrcBlock:Int = MAX_BYTES_VALUE - srcBlockPos;

			var bytesToCopyInThisIteration:Int64 = bytesInDestBlock < bytesInSrcBlock ? bytesInDestBlock : bytesInSrcBlock;
			bytesToCopyInThisIteration = bytesToCopyInThisIteration < bytesToCopy ? bytesToCopyInThisIteration : bytesToCopy;

			destBlock.blit(destBlockPos, srcBlock, srcBlockPos, Int64.toInt(bytesToCopyInThisIteration));

			destBlockPos = 0;
			srcBlockPos = 0;

			destBlockIndex++;
			srcBlockIndex++;

			bytesToCopy -= bytesToCopyInThisIteration;
		}
	}

	private function _getBytesIndex(pos:Int64):Int
	{
		var blockIndex:Int = Int64.toInt(pos / MAX_BYTES_VALUE);

		if (blockIndex < 0 || blockIndex >= bytesArray.length)
		{
			throw "Index out of bounds";
		}

		return blockIndex;
	}

	private function _setBlockData(index:Int, data):Void
	{
		@:privateAccess bytesArray[index].b = cast data;
	}
	#else
	public function new(length:Int64)
	{
		throw "Not supported without the HXCPP_M64 define";
	}
	#end
}

