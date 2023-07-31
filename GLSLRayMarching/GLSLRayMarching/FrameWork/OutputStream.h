//////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2020, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk          //
//																				//
// Author : Mac Lin																//
// Module : Magnum Engine v0.7.0												//
// Date   : 05/Nov/2020															//
//																				//
//////////////////////////////////////////////////////////////////////////////////
#ifndef _OutputStream_h_
#define _OutputStream_h_

#include "Platform.h"
#include "FileIO.h"

/**
* OutputStream. The base class of All OutputStream.
*/
class OutputStream
{
public:
	/**
	* OutputStream Constructor.
	* To Construct the OutputStream.
	*/
	OutputStream() {}

	/**
	* OutputStream Destructor.
	* To Destruct OutputStream
	*/
	virtual ~OutputStream();

	/**
	* read function for bool data
	* @param data, bool, the data is read from the inputstream and return in this data
	*/
	virtual void Write(const bool& data);

	/**
	* read function for char data
	* @param data, char, the data is read from the inputstream and return in this data
	*/
	virtual void Write(const char& data);

	/**
	* read function for unsigned char data
	* @param data, unsigned char, the data is read from the inputstream and return in this data
	*/
	virtual void Write(const unsigned char& data);

	/**
	* read function for short char data
	* @param data, short, the data is read from the inputstream and return in this data
	*/
	virtual void Write(const short& data);

	/**
	* read function for unsigned short char data
	* @param data, unsigned short, the data is read from the inputstream and return in this data
	*/
	virtual void Write(const unsigned short& data);

	/**
	* read function for int char data
	* @param data, int, the data is read from the inputstream and return in this data
	*/
	virtual void Write(const int& data);

	/**
	* read function for unsigned int char data
	* @param data, unsigned int, the data is read from the inputstream and return in this data
	*/
	virtual void Write(const unsigned int& data);

	/**
	* read function for long char data
	* @param data, long, the data is read from the inputstream and return in this data
	*/
	virtual void Write(const long& data);

	/**
	* read function for unsigned long char data
	* @param data, unsigned long, the data is read from the inputstream and return in this data
	*/
	virtual void Write(const unsigned long& data);

	/**
	* read function for float char data
	* @param data, float, the data is read from the inputstream and return in this data
	*/
	virtual void Write(const float& data);

	/**
	* read function for double char data
	* @param data, double, the data is read from the inputstream and return in this data
	*/
	virtual void Write(const double& data);

	/**
	* read function for String char data
	* @param data, String, the data is read from the inputstream and return in this data
	*/
	virtual void Write(const std::string& str);

	/**
	* Write function buffer data
	* @param buffer, void *, the data will be written to the stream.
	* @param size, int, the number of byte to be write to the stream
	* @param reverseOrder, true , for big endian system
	*					   false, for little endian system
	*/
	virtual void WriteBuffer(const void* src_, int size, bool reverseOrder = false) = 0;
	/**
	* skip data from buffer
	* @param size, int, the number of byte to be skipped
	*/
	virtual void Skip(int size) = 0;
	/**
	* Tell the current read position
	* @return unsigned int, the current read position
	*/
	virtual unsigned int Tell() const = 0;
	/**
	* Check if the stream is opened
	* @return true, stream is opened, else stream is closed
	*/
	virtual bool IsOpened() const = 0;
	/**
	* Rewind the stream, the stream current read position  will be reset to 0 by this function
	* @return true, stream is opened, else stream is closed
	*/
	virtual void Rewind() = 0;
private:
	OutputStream(const OutputStream&);
	OutputStream& operator=(const OutputStream&);
};

/**
* MemOutputStream. The class is a OutputStream for a memory location
*/
class MemOutputStream : public OutputStream
{
public:
	enum
	{
		EXPAND_SIZE = 2048
	};

	/**
	* MemOutputStream Constructor.
	* To Construct the MemOutputStream.
	* @param buffer_ a chunk of memory to be read from
	*/
	MemOutputStream(std::vector<unsigned char>& buffer_);

	/**
	* MemOutputStream Destructor.
	* To Destruct MemOutputStream
	*/
	virtual ~MemOutputStream();

	/**
	* write function buffer data
	* @param buffer, void *, the data will be written to the stream.
	* @param size, int, the number of byte to be write to the stream
	* @param reverseOrder, true , for big endian system
	*					   false, for little endian system
	*/
	virtual void WriteBuffer(const void* src_, int size, bool reverseOrder = false) override;

	/**
	* skip data from buffer
	* @param size, int, the number of byte to be skipped
	*/
	virtual unsigned int Tell() const override;

	/**
	* Tell the current read position
	* @return unsigned int, the current read position
	*/
	virtual void Skip(int size) override;

	/**
	* Check if the stream is opened
	* @return true, stream is opened, else stream is closed
	*/
	virtual bool IsOpened() const override;

	/**
	* Rewind the stream, the stream current read position  will be reset to 0 by this function
	* @return true, stream is opened, else stream is closed
	*/
	virtual void Rewind() override;
private:
	MemOutputStream(const MemOutputStream&);
	MemOutputStream& operator=(const MemOutputStream&);

	std::vector<unsigned char>& buffer;
	int							position;
};

/**
* FileOutputStream. The class is a OutputStream for a file stream
*/
class FileOutputStream : public OutputStream
{
public:
	/**
	* FileOutputStream Constructor.
	* To Construct the FileOutputStream.
	* @param path_ , filename for the file of FileOutputStream
	*/
	FileOutputStream(const std::string& path_);

	/**
	* FileOutputStream Destructor.
	* To Destruct FileOutputStream and close the file
	*/
	virtual ~FileOutputStream();

	/**
	* write function buffer data
	* @param buffer, void *, the data will be written to the stream.
	* @param size, int, the number of byte to be write to the stream
	* @param reverseOrder, true , for big endian system
	*					   false, for little endian system
	*/
	virtual void WriteBuffer(const void* src_, int size, bool reverseOrder = false);

	/**
	* skip data from buffer
	* @param size, int, the number of byte to be skipped
	*/
	virtual unsigned int Tell() const;

	/**
	* Tell the current read position
	* @return unsigned int, the current read position
	*/
	virtual void Skip(int size);

	/**
	* Check if the stream is opened
	* @return true, stream is opened, else stream is closed
	*/
	virtual bool IsOpened() const;

	/**
	* Rewind the stream, the stream current read position  will be reset to 0 by this function
	* @return true, stream is opened, else stream is closed
	*/
	virtual void Rewind();
private:
	FileOutputStream(const FileOutputStream&);
	FileOutputStream& operator=(const FileOutputStream&);

	FileIO file;
};

#if 0
class GZMemOutputStream : public OutputStream
{
public:
	enum
	{
		EXPAND_SIZE = 2048
	};
	GZMemOutputStream(Vector<char>& buffer_);
	virtual ~GZMemOutputStream();

	virtual void writeX(const void* src_, int size, bool reverseOrder = false);
	virtual unsigned int tell() const;
	virtual void skip(int size);
	virtual bool opened() const;
	virtual void rewind();
	void setCompressionLevel(int level = -1);
	int getCompressionLevel() const;
private:
	GZMemOutputStream(const GZMemOutputStream&);
	GZMemOutputStream& operator=(const GZMemOutputStream&);

	Vector<char>& buffer;
	int				position;
	void* handle;
	int				level;
};

#include "GZFileIO.h"
class GZFileOutputStream : public OutputStream
{
public:
	GZFileOutputStream(const std::string& path_);
	virtual ~GZFileOutputStream();

	virtual void WriteBuffer(const void* src_, int size, bool reverseOrder = false);
	virtual unsigned int Tell() const;
	virtual void Skip(int size);
	virtual bool IsOpened() const;
	virtual void Rewind();
	void SetCompressionLevel(int level = -1);
	int GetCompressionLevel() const;
private:
	GZFileOutputStream(const GZFileOutputStream&);
	GZFileOutputStream& operator=(const GZFileOutputStream&);

	GZFileIO file;
};
#endif

template<class T> inline OutputStream& operator<<(OutputStream& os, const T& data)
{
	data.Write(os);
	return os;
}

inline OutputStream& operator<<(OutputStream& os, const bool& data)
{
	os.Write(data);
	return os;
}

inline OutputStream& operator<<(OutputStream& os, const char& data)
{
	os.Write(data);
	return os;
}

inline OutputStream& operator<<(OutputStream& os, const unsigned char& data)
{
	os.Write(data);
	return os;
}

inline OutputStream& operator<<(OutputStream& os, const short& data)
{
	os.Write(data);
	return os;
}

inline OutputStream& operator<<(OutputStream& os, const unsigned short& data)
{
	os.Write(data);
	return os;
}

inline OutputStream& operator<<(OutputStream& os, const int& data)
{
	os.Write(data);
	return os;
}

inline OutputStream& operator<<(OutputStream& os, const unsigned int& data)
{
	os.Write(data);
	return os;
}

inline OutputStream& operator<<(OutputStream& os, const long& data)
{
	os.Write(data);
	return os;
}

inline OutputStream& operator<<(OutputStream& os, const unsigned long& data)
{
	os.Write(data);
	return os;
}

inline OutputStream& operator<<(OutputStream& os, const float& data)
{
	os.Write(data);
	return os;
}

inline OutputStream& operator<<(OutputStream& os, const double& data)
{
	os.Write(data);
	return os;
}

inline OutputStream& operator<<(OutputStream& os, const std::string& data)
{
	os.Write(data);
	return os;
}

template<class T> inline OutputStream& operator<<(OutputStream& os, const std::vector<T>& data)
{
	int len = data.size();
	os << len;
	for (int i = 0; i < len; i++)
		os << data[i];

	return os;
}

template<class Key, class Value> inline OutputStream& operator<<(OutputStream& os, const std::map<Key, Value>& values)
{
	int len = values.size();
	os << len;

	for (auto& valueItr : values)
		os << valueItr.first << valueItr.second;

	return os;
}

template<class Key> inline OutputStream& operator<<(OutputStream& os, const std::set<Key>& values)
{
	int len = values.size();
	os << len;

	for (auto& value : values)
		os << value;

	return os;
}

#endif