//////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2020, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk          //
//																				//
// Author : Mac Lin																//
// Module : Magnum Engine v0.7.0												//
// Date   : 05/Nov/2020															//
//																				//
//////////////////////////////////////////////////////////////////////////////////
#include "OutputStream.h"

OutputStream::~OutputStream()
{
}

void OutputStream::Write(const bool& data)
{
	unsigned char c;
	if (data)
		c = 1;
	else
		c = 0;
	
	Write(c);
}

void OutputStream::Write(const char& data)
{
	WriteBuffer(&data, sizeof(char), false);
}

void OutputStream::Write(const unsigned char& data)
{
	WriteBuffer(&data, sizeof(unsigned char), false);
}

void OutputStream::Write(const short& data)
{
	WriteBuffer(&data, sizeof(short), false);
}

void OutputStream::Write(const unsigned short& data)
{
	WriteBuffer(&data, sizeof(unsigned short), false);
}

void OutputStream::Write(const int& data)
{
	WriteBuffer(&data, sizeof(int), false);
}

void OutputStream::Write(const unsigned int& data)
{
	WriteBuffer(&data, sizeof(unsigned int), false);
}

void OutputStream::Write(const long& data)
{
	WriteBuffer(&data, sizeof(long), false);
}

void OutputStream::Write(const unsigned long& data)
{
	WriteBuffer(&data, sizeof(unsigned long), false);
}

void OutputStream::Write(const float& data)
{
	WriteBuffer(&data, sizeof(float), false);
}

void OutputStream::Write(const double& data)
{
	WriteBuffer(&data, sizeof(double), false);
}

void OutputStream::Write(const std::string& str)
{
	int size = str.size();
	Write(size);
	WriteBuffer(str.c_str(), size, false);
}

///////////////////////////////////////////////////////////////////////////////////////
MemOutputStream::MemOutputStream(std::vector<unsigned char>& buffer_)
	: buffer(buffer_)
	, position(0)
{
}

MemOutputStream::~MemOutputStream()
{
}

void MemOutputStream::WriteBuffer(const void* src_, int size, bool reverseOrder)
{
	if (buffer.size() - position < size)
	{
		int expandSize = EXPAND_SIZE;
		if (expandSize < size)
			expandSize = size;

		buffer.resize(buffer.size() + expandSize);
	}

	if (reverseOrder)
	{
		char* buf = (char*)src_;
		for (int i = 0; i < size; i++)
			buffer[position + i] = buf[position + (size - 1 - i)];

		position += size;
	}
	else
	{
		MemCpy(&buffer[position], src_, size);
		position += size;
	}
}

unsigned int MemOutputStream::Tell() const
{
	return position;
}

void MemOutputStream::Skip(int size)
{
	if (buffer.size() - position < size)
	{
		int expandSize = EXPAND_SIZE;
		if (expandSize < size)
			expandSize = size;

		buffer.resize(buffer.size() + expandSize);
	}

	MemSet(&buffer[position], 0, size);
	position += size;
}

bool MemOutputStream::IsOpened() const
{
	return true;
}

void MemOutputStream::Rewind()
{
	buffer.clear();
	position = 0;
}

///////////////////////////////////////////////////////////////////////////////////////
FileOutputStream::FileOutputStream(const std::string& path_)
	: file(path_)
{
	bool success = file.Open(IO::WRITE);
	Assert(success && "Error: cannot open file for writing");
}

FileOutputStream::~FileOutputStream()
{
	file.Close();
}

void FileOutputStream::WriteBuffer(const void* src_, int size, bool reverseOrder)
{
	if (reverseOrder)
	{
		char* buf = (char*)src_;
		for (int i = 0; i < size; i++)
			file.Write(&buf[size - 1 - i], 1);
	}
	else
	{
		file.Write(src_, size);
	}
}

void FileOutputStream::Skip(int size)
{
	char c = 0;
	for (int i = 0; i < size; i++)
		file.Write(&c);
}

unsigned int FileOutputStream::Tell() const
{
	return file.Tell();
}

bool FileOutputStream::IsOpened() const
{
	return file.IsOpened();
}

void FileOutputStream::Rewind()
{
	file.Seek(IO::BEGIN, 0);
}

#define CHECK_ERR(err, msg) { \
    if (err != Z_OK) { \
        Error("%s error: %d\n", msg, err); \
        exit(1); \
    } \
}

#if 0
///////////////////////////////////////////////////////////////////////////////////////
GZMemOutputStream::GZMemOutputStream(Vector<char>& buffer_)
	: buffer(buffer_)
	, position(0)
	, handle(0)
	, level(Z_DEFAULT_COMPRESSION)
{
	handle = new z_stream();
	z_stream* stream = (z_stream*)handle;
	Assert(stream);

	stream->zalloc = 0;
	stream->zfree = 0;
	stream->opaque = (voidpf)0;

	int err;
	err = deflateInit(stream, level);
	CHECK_ERR(err, "deflateInit");
	err = deflateParams(stream, level, Z_FILTERED);
	CHECK_ERR(err, "deflateParams");
}

GZMemOutputStream::~GZMemOutputStream()
{
	z_stream* stream = (z_stream*)handle;
	Assert(stream);

	int err = deflate(stream, Z_FINISH);
	if (err != Z_STREAM_END)
	{
		debug("deflate should report Z_STREAM_END\n");
		Assert(0);
	}
	err = deflateEnd(stream);

	delete stream;
	handle = 0;
}

void GZMemOutputStream::writeX(const void* src_, int size, bool reverseOrder)
{
	if (buffer.length() - position < size)
	{
		int expandSize = EXPAND_SIZE;
		if (expandSize < size)
			expandSize = size;

		buffer.resize(buffer.length() + expandSize);
	}

	z_stream* stream = (z_stream*)handle;
	Assert(stream);

	if (reverseOrder)
	{
		Assert(0);
		/*
		char *buf = (char *)src_;
		for(int i=0; i<size; i++)
			buffer[position+i] = buf[position+(size-1-i)];

		position += size;
		*/
	}
	else
	{
		stream->next_out = (unsigned char*)&buffer[position];
		stream->avail_out = buffer.length() - position;
		int err = deflate(stream, Z_FINISH);
		CHECK_ERR(err, "deflate");
		if (stream->avail_in != 0)
		{
			debug("deflate not greedy\n");
			Assert(0);
		}
	}
}

unsigned int GZMemOutputStream::tell() const
{
	return position;
}

void GZMemOutputStream::skip(int size)
{
	if (buffer.length() - position < size)
	{
		int expandSize = EXPAND_SIZE;
		if (expandSize < size)
			expandSize = size;

		buffer.resize(buffer.length() + expandSize);
	}

	Memset(&buffer[position], 0, size);
	position += size;
}

bool GZMemOutputStream::opened() const
{
	return true;
}

void GZMemOutputStream::rewind()
{
	buffer.clear();
	position = 0;
}

void GZMemOutputStream::setCompressionLevel(int level_)
{
	level = level_;
}

int GZMemOutputStream::getCompressionLevel() const
{
	return level;
}
#endif

///////////////////////////////////////////////////////////////////////////////////////
GZFileOutputStream::GZFileOutputStream(const std::string& path_)
	: file(path_)
{
	Assert(file.Open(IO::WRITE) && "Error: cannot open file for writing");
}

GZFileOutputStream::~GZFileOutputStream()
{
	file.Close();
}

void GZFileOutputStream::WriteBuffer(const void* src_, int size, bool reverseOrder)
{
	if (reverseOrder)
	{
		char* buf = (char*)src_;
		for (int i = 0; i < size; i++)
			file.Write(&buf[size - 1 - i], 1);
	}
	else
	{
		file.Write(src_, size);
	}
}

void GZFileOutputStream::Skip(int size)
{
	char c = 0;
	for (int i = 0; i < size; i++)
		file.Write(&c);
}

unsigned int GZFileOutputStream::Tell() const
{
	return file.Tell();
}

bool GZFileOutputStream::IsOpened() const
{
	return file.IsOpened();
}

void GZFileOutputStream::Rewind()
{
	file.Seek(IO::BEGIN, 0);
}

void GZFileOutputStream::SetCompressionLevel(int level)
{
	file.SetCompressionLevel(level);
}

int GZFileOutputStream::GetCompressionLevel() const
{
	return file.GetCompressionLevel();
}