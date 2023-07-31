//////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2020, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk          //
//																				//
// Author : Mac Lin																//
// Module : Magnum Engine v0.7.0												//
// Date   : 05/Nov/2020															//
//																				//
//////////////////////////////////////////////////////////////////////////////////
#include "Platform.h"
#include "InputStream.h"

InputStream::~InputStream()
{
}

void InputStream::Read(bool& data)
{
	unsigned char c;
	Read(c);
	data = (c != 0);
}

void InputStream::Read(std::string& str)
{
	int size;
	Read(size);
	//	Assert(size<512);
	if (!size)
		str = "";
	else
	{
		str.resize(size);
		ReadBuffer(&str[0], size, false);
	}
}

void InputStream::Read(char& data)
{
	ReadBuffer(&data, sizeof(char), false);
}

void InputStream::Read(unsigned char& data)
{
	ReadBuffer(&data, sizeof(unsigned char), false);
}

void InputStream::Read(short& data)
{
	ReadBuffer(&data, sizeof(short), false);
}

void InputStream::Read(unsigned short& data)
{
	ReadBuffer(&data, sizeof(unsigned short), false);
}

void InputStream::Read(int& data)
{
	ReadBuffer(&data, sizeof(int), false);
}

void InputStream::Read(unsigned int& data)
{
	ReadBuffer(&data, sizeof(unsigned int), false);
}

void InputStream::Read(long& data)
{
	ReadBuffer(&data, sizeof(long), false);
}

void InputStream::Read(unsigned long& data)
{
	ReadBuffer(&data, sizeof(unsigned long), false);
}

void InputStream::Read(float& data)
{
	ReadBuffer(&data, sizeof(float), false);
}

void InputStream::Read(double& data)
{
	ReadBuffer(&data, sizeof(double), false);
}

///////////////////////////////////////////////////////////////////////////////////////
MemInputStream::MemInputStream(const unsigned char* data_, const unsigned int len_)
	: data_head(data_)
	, len(len_)
	, data_ptr(data_)
	, current(0)
{
}

MemInputStream::~MemInputStream()
{
}

void MemInputStream::ReadBuffer(void* buffer, int size, bool reverseOrder)
{
	MemCpy(buffer, data_ptr, size);
	
	data_ptr += size;
	current += size;
}

void MemInputStream::Skip(int size)
{
	data_ptr += size;
	current += size;
}

unsigned int MemInputStream::GetSize()
{
	return len;
}

unsigned int MemInputStream::Tell()
{
	return current;
}

bool MemInputStream::IsOpened()
{
	return true;
}

void MemInputStream::Rewind()
{
	data_ptr = data_head;
	current = 0;
}

///////////////////////////////////////////////////////////////////////////////////////
FileInputStream::FileInputStream(const std::string& path_)
	: file(path_)
{
	bool success = file.Open(IO::READ);
	Assert(success && "Error: cannot open file for reading");
}

FileInputStream::~FileInputStream()
{
	file.Close();
}

void FileInputStream::ReadBuffer(void* buffer, int size, bool reverseOrder)
{
	if (reverseOrder)
	{
		char* buf = (char*)buffer;
		for (int i = 0; i < size; i++)
			file.Read(&buf[size - 1 - i], 1);
	}
	else
	{
		file.Read(buffer, size);
	}
}

void FileInputStream::Skip(int size)
{
	file.Seek(IO::CURRENT, size);
}

unsigned int FileInputStream::GetSize()
{
	return file.GetSize();
}

unsigned int FileInputStream::Tell()
{
	Assert(0 && "TODO");
	return 0;
}

bool FileInputStream::IsOpened()
{
	return file.IsOpened();
}

void FileInputStream::Rewind()
{
	file.Seek(IO::BEGIN, 0);
}

///////////////////////////////////////////////////////////////////////////////////////
#if 0
GZMemInputStream::GZMemInputStream(const unsigned char* data_, const unsigned int len_)
	: data_head(data_)
	, data(data_)
	, len(len_)
	, current(0)
{
}

GZMemInputStream::~GZMemInputStream()
{
}

void GZMemInputStream::readX(void* buffer, int size, bool reverseOrder)
{
	memcpy(buffer, data, size);
	data += size;
	current += size;
}

void GZMemInputStream::skip(int size)
{
	data += size;
	current += size;
}

unsigned int GZMemInputStream::length()
{
	return len;
}

unsigned int GZMemInputStream::tell()
{
	return current;
}

bool GZMemInputStream::opened()
{
	return true;
}

void GZMemInputStream::rewind()
{
	data = data_head;
	current = 0;
}

///////////////////////////////////////////////////////////////////////////////////////
GZFileInputStream::GZFileInputStream(const std::string& path_)
	: file(path_)
{
	Assert(file.Open(IO::READ) && "Error: cannot open file for reading");
}

GZFileInputStream::~GZFileInputStream()
{
	file.Close();
}

void GZFileInputStream::ReadBuffer(void* buffer, int size, bool reverseOrder)
{
	if (reverseOrder)
	{
		char* buf = (char*)buffer;
		for (int i = 0; i < size; i++)
			file.Read(&buf[size - 1 - i], 1);
	}
	else
	{
		file.Read(buffer, size);
	}
}

void GZFileInputStream::Skip(int size)
{
	file.Seek(IO::CURRENT, size);
}

unsigned int GZFileInputStream::GetSize()
{
	return file.GetSize();
}

unsigned int GZFileInputStream::Tell()
{
	Assert(0 && "TODO");

	return file.Tell();
}

bool GZFileInputStream::IsOpened()
{
	return file.IsOpened();
}

void GZFileInputStream::Rewind()
{
	file.Seek(IO::BEGIN, 0);
}
#endif