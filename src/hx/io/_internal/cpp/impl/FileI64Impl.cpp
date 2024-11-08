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

Array<Dynamic> file_contents_big_bytes(String name)
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
			currentLen = MAX_VALUE;

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
		std::cout << "0" << std::endl;
		//////////////LESS THAN MAX VALUE/////////////
		Array<unsigned char> buffer = Array_obj<unsigned char>::__new(len, len);

		hx::EnterGCFreeZone();
		if (len)
		{
			std::cout << "1" << std::endl;
			char *dest = reinterpret_cast<char*>(&buffer[0]);
			int p = 0;

			std::cout << currentLen << std::endl;
			//while (currentLen > 0)
			//{
				std::cout << "2" << std::endl;
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
				//}

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