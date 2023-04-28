///////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2016, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk			 //
//																				 //
// Author : Mac Lin									                             //
// Module : Magnum Engine v0.7.0												 //
// Date   : 14/Jun/2020											                 //
//																				 //
///////////////////////////////////////////////////////////////////////////////////
#include "Platform.h"
#include "GZFileIO.h"

#if defined(_WIN32) ||  defined(_WIN64)
#include <Windows.h>
#elif defined(__ANDROID__ )
#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#elif ( defined(TARGET_OS_IPHONE) || defined(TARGET_IPHONE_SIMULATOR) )
#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#endif

#include <zlib/zlib.h>

#if 0
#include <stdio.h>

static const char hello[] = "hello, hello!";
void test_gzio(const char* fname, Byte* uncompr, uLong uncomprLen)
{
#ifdef NO_GZCOMPRESS
	fprintf(stderr, "NO_GZCOMPRESS -- gz* functions cannot compress\n");
#else
	int err;
	int len = (int)strlen(hello) + 1;
	gzFile file;
	off_t pos;

	file = gzopen(fname, "wb");
	if (file == NULL) {
		fprintf(stderr, "gzopen error\n");
		exit(1);
	}
	gzputc(file, 'h');
	if (gzputs(file, "ello") != 4) {
		fprintf(stderr, "gzputs err: %s\n", gzerror(file, &err));
		exit(1);
	}
	if (gzprintf(file, ", %s!", "hello") != 8) {
		fprintf(stderr, "gzprintf err: %s\n", gzerror(file, &err));
		exit(1);
	}
	gzseek(file, 1L, SEEK_CUR); /* add one zero byte */
	gzclose(file);

	file = gzopen(fname, "rb");
	if (file == NULL) {
		fprintf(stderr, "gzopen error\n");
		exit(1);
	}
	strcpy((char*)uncompr, "garbage");

	if (gzread(file, uncompr, (unsigned)uncomprLen) != len) {
		fprintf(stderr, "gzread err: %s\n", gzerror(file, &err));
		exit(1);
	}
	if (strcmp((char*)uncompr, hello)) {
		fprintf(stderr, "bad gzread: %s\n", (char*)uncompr);
		exit(1);
	}
	else {
		printf("gzread(): %s\n", (char*)uncompr);
	}

	pos = gzseek(file, -8L, SEEK_CUR);
	if (pos != 6 || gztell(file) != pos) {
		fprintf(stderr, "gzseek error, pos=%ld, gztell=%ld\n",
			(long)pos, (long)gztell(file));
		exit(1);
	}

	if (gzgetc(file) != ' ') {
		fprintf(stderr, "gzgetc error\n");
		exit(1);
	}

	if (gzungetc(' ', file) != ' ') {
		fprintf(stderr, "gzungetc error\n");
		exit(1);
	}

	gzgets(file, (char*)uncompr, (int)uncomprLen);
	if (strlen((char*)uncompr) != 7) { /* " hello!" */
		fprintf(stderr, "gzgets err after gzseek: %s\n", gzerror(file, &err));
		exit(1);
	}
	if (strcmp((char*)uncompr, hello + 6)) {
		fprintf(stderr, "bad gzgets after gzseek\n");
		exit(1);
	}
	else {
		printf("gzgets() after gzseek: %s\n", (char*)uncompr);
	}

	gzclose(file);
#endif
}
#endif

typedef struct
{
	gzFile handle;
	unsigned int position;
	unsigned int length;
}GZFileDesc;

GZFileIO::GZFileIO(const std::string& path_)
	: IO(path_)
	, user(0)
{
	user = (void*)(new GZFileDesc);
	Assert(user);

	GZFileDesc* fd = ((GZFileDesc*)user);

	fd->handle = 0;
	fd->position = 0;
	fd->length = 0;
}

GZFileIO::~GZFileIO()
{
	Close();

	delete ((GZFileDesc*)user);
}

bool GZFileIO::Open(AccessMode mode)
{
	IO::Open(mode);

	GZFileDesc* fd = ((GZFileDesc*)user);
	Assert(fd->handle == 0);

	if (IsReadEnabled() && !IsWriteEnabled())
		fd->handle = gzopen(path.c_str(), "rb");
	else if (!IsReadEnabled() && IsWriteEnabled())
		fd->handle = gzopen(path.c_str(), "wb");
	else if (IsReadEnabled() && IsWriteEnabled())
		fd->handle = gzopen(path.c_str(), "rb+wb");

	if (!fd->handle)
		return false;

	fd->position = 0;

	::gzseek(fd->handle, 0, SEEK_END);
	fd->length = ::gztell(fd->handle);
	::gzseek(fd->handle, 0, SEEK_SET);
	
	return IsOpened();
}

bool GZFileIO::OpenForAsync(AccessMode mode)
{
	IO::OpenForAsync(mode);

	GZFileDesc* fd = ((GZFileDesc*)user);
	Assert(fd->handle == 0);

	if (IsReadEnabled() && !IsWriteEnabled())
		fd->handle = gzopen(path.c_str(), "rb");
	else if (!IsReadEnabled() && IsWriteEnabled())
		fd->handle = gzopen(path.c_str(), "wb");
	else if (IsReadEnabled() && IsWriteEnabled())
		fd->handle = gzopen(path.c_str(), "rb+wb");

	if (!fd->handle)
		return false;

	fd->position = 0;

	::gzseek(fd->handle, 0, SEEK_END);
	fd->length = ::gztell(fd->handle);
	::gzseek(fd->handle, 0, SEEK_SET);

	return IsOpened();
}

bool GZFileIO::IsAsyncFinished()
{
	GZFileDesc* fd = ((GZFileDesc*)user);
	Assert(fd->handle != 0);

	return true;
}

void GZFileIO::WaitAsyncFinished()
{
	GZFileDesc* fd = ((GZFileDesc*)user);
	Assert(fd->handle != 0);
}

bool GZFileIO::Close()
{
	GZFileDesc* fd = ((GZFileDesc*)user);
	if (fd->handle == 0)
		return false;

	gzclose(fd->handle);
	fd->handle = 0;
	fd->position = 0;
	fd->length = 0;

	return true;
}

bool GZFileIO::IsOpened() const
{
	GZFileDesc* fd = ((GZFileDesc*)user);

	return fd->handle != 0;
}

int GZFileIO::Tell() const
{
	GZFileDesc* fd = ((GZFileDesc*)user);
	Assert(fd->handle != 0);

	return fd->position;
}

int GZFileIO::Seek(SeekDef seek, int offset)
{
	GZFileDesc* fd = ((GZFileDesc*)user);
	Assert(fd->handle != 0);

	switch (seek)
	{
		default:
		case BEGIN:
		{
			bool rval = ::gzseek(fd->handle, offset, SEEK_SET) != 0;
			if (rval)
			{
				fd->position = 0 + offset;
			}
			return rval;
		}

		case CURRENT:
		{
			bool rval = ::gzseek(fd->handle, offset, SEEK_CUR) != 0;
			if (rval)
			{
				fd->position = fd->position + offset;
			}
			return rval;
		}

		case END:
		{
			bool rval = ::gzseek(fd->handle, offset, SEEK_END) != 0;
			if (rval)
			{
				fd->position = fd->length - offset;
			}
			return rval;
		}
	};
}

int GZFileIO::Read(void* buf, int size)
{
	Assert(IsReadEnabled() && "File was not opened in read mode");

	GZFileDesc* fd = ((GZFileDesc*)user);
	Assert(fd->handle != 0);

	int rval = gzread(fd->handle, buf, size);
	fd->position = fd->position + size;
	
	return rval;
}

int GZFileIO::Read(unsigned char* uc)
{
	return Read(uc, sizeof(unsigned char));
}

int GZFileIO::Read(char* c)
{
	return Read(c, sizeof(char));
}

int GZFileIO::Read(unsigned short* us)
{
	return Read(us, sizeof(unsigned short));
}

int GZFileIO::Read(short* s)
{
	return Read(s, sizeof(short));
}

int GZFileIO::Read(unsigned int* ui)
{
	return Read(ui, sizeof(unsigned int));
}

int GZFileIO::Read(int* i)
{
	return Read(i, sizeof(int));
}

int GZFileIO::Read(unsigned long* ul)
{
	return Read(ul, sizeof(unsigned long));
}

int GZFileIO::Read(long* l)
{
	return Read(l, sizeof(long));
}

int GZFileIO::Read(float* f)
{
	return Read(f, sizeof(float));
}

int GZFileIO::Read(double* d)
{
	return Read(d, sizeof(double));
}

int GZFileIO::Write(const void* buf, int size)
{
	Assert(IsWriteEnabled() && "File was not opened in write mode");

	GZFileDesc* fd = ((GZFileDesc*)user);
	Assert(fd->handle != 0);

	int rval = gzwrite(fd->handle, buf, size);
	fd->position = fd->position + size;

	return rval;
}

int GZFileIO::Write(const unsigned char* uc)
{
	return Write(uc, sizeof(unsigned char));
}

int GZFileIO::Write(const char* c)
{
	return Write(c, sizeof(char));
}

int GZFileIO::Write(const unsigned short* us)
{
	return Write(us, sizeof(unsigned short));
}

int GZFileIO::Write(const short* s)
{
	return Write(s, sizeof(short));
}

int GZFileIO::Write(const unsigned int* ui)
{
	return Write(ui, sizeof(unsigned int));
}

int GZFileIO::Write(const int* i)
{
	return Write(i, sizeof(int));
}

int GZFileIO::Write(const unsigned long* ul)
{
	return Write(ul, sizeof(unsigned long));
}

int GZFileIO::Write(const long* l)
{
	return Write(l, sizeof(long));
}

int GZFileIO::Write(const float* f)
{
	return Write(f, sizeof(float));
}

int GZFileIO::Write(const double* d)
{
	return Write(d, sizeof(double));
}

int GZFileIO::GetSize() const
{
	GZFileDesc* fd = ((GZFileDesc*)user);
	Assert(fd->handle != 0);

	return fd->length;
}

void GZFileIO::SetCompressionLevel(int level)
{
	GZFileDesc* fd = ((GZFileDesc*)user);
	Assert(fd->handle != 0);
}

int GZFileIO::GetCompressionLevel() const
{
	return 0;
}

bool GZFileIO::Exists(const std::string& path_)
{
	GZFileIO f(path_);
	f.Open(IO::READ);

	return f.IsOpened();
}

int GZFileIO::GetSize(const std::string& path_)
{
	GZFileIO f(path_);
	f.Open(IO::READ);

	return f.GetSize();
}

bool GZFileIO::Load(const std::string& path_, void* buf, int size, int offset)
{
	GZFileIO f(path_);
	f.Open(IO::READ);
	f.Seek(IO::BEGIN, offset);

	return f.Read(buf, size);
}