///////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2016, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk			 //
//																				 //
// Author : Mac Lin									                             //
// Module : Magnum Engine v1.0.0												 //
// Date   : 14/Jun/2016											                 //
//																				 //
///////////////////////////////////////////////////////////////////////////////////
#ifndef _InputStream_h_
#define _InputStream_h_

#include "Platform.h"
#include "FileIO.h"

	/**
	* InputStream. The base class of All InputStream.
	*/
class InputStream
{
public:
	/**
	* InputStream Constructor.
	* To Construct the InputStream.
	*/
	InputStream() {}

	/**
	* InputStream Destructor.
	* To Destruct the InputStream.
	*/
	virtual ~InputStream();

	/**
	* read function for bool data
	* @param data, bool, the data is read from the inputstream and return in this data
	*/
	virtual void Read(bool& data);

	/**
	* read function for char data
	* @param data, char, the data is read from the inputstream and return in this data
	*/
	virtual void Read(char& data);

	/**
	* read function for unsigned char data
	* @param data, unsigned char, the data is read from the inputstream and return in this data
	*/
	virtual void Read(unsigned char& data);

	/**
	* read function for short char data
	* @param data, short, the data is read from the inputstream and return in this data
	*/
	virtual void Read(short& data);

	/**
	* read function for unsigned short char data
	* @param data, unsigned short, the data is read from the inputstream and return in this data
	*/
	virtual void Read(unsigned short& data);

	/**
	* read function for int char data
	* @param data, int, the data is read from the inputstream and return in this data
	*/
	virtual void Read(int& data);

	/**
	* read function for unsigned int char data
	* @param data, unsigned int, the data is read from the inputstream and return in this data
	*/
	virtual void Read(unsigned int& data);

	/**
	* read function for long char data
	* @param data, long, the data is read from the inputstream and return in this data
	*/
	virtual void Read(long& data);

	/**
	* read function for unsigned long char data
	* @param data, unsigned long, the data is read from the inputstream and return in this data
	*/
	virtual void Read(unsigned long& data);

	/**
	* read function for float char data
	* @param data, float, the data is read from the inputstream and return in this data
	*/
	virtual void Read(float& data);

	/**
	* read function for double char data
	* @param data, double, the data is read from the inputstream and return in this data
	*/
	virtual void Read(double& data);

	/**
	* read function for String char data
	* @param data, String, the data is read from the inputstream and return in this data
	*/
	virtual void Read(std::string& str);

	/**
	* read function buffer data
	* @param buffer, void *, the data is read from the inputstream and fill in this buffer
	* @param size, int, the number of byte to be read from the input steam
	* @param reverseOrder, true , for big endian system
	*					   false, for little endian system
	*/
	virtual void ReadBuffer(void* buffer, int size, bool reverseOrder = false) = 0;

	/**
	* skip data from buffer
	* @param size, int, the number of byte to be skipped
	*/
	virtual void Skip(int size) = 0;

	/**
	* Get the length of buffer data
	* @return unsigned int, the length of InputStream
	*/
	virtual unsigned int GetSize() = 0;

	/**
	* Tell the current read position
	* @return unsigned int, the current read position
	*/
	virtual unsigned int Tell() = 0;

	/**
	* Check if the stream is opened
	* @return true, stream is opened, else stream is closed
	*/
	virtual bool IsOpened() = 0;

	/**
	* Rewind the stream, the stream current read position  will be reset to 0 by this function
	* @return true, stream is opened, else stream is closed
	*/
	virtual void Rewind() = 0;
private:
	InputStream(const InputStream&);
	InputStream& operator=(const InputStream&);
};	//class InputStream

/**
* InputStream. The class is an InputStream for a memory location
*/
class MemInputStream : public InputStream
{
public:
	/**
	* MemInputStream Constructor.
	* To Construct the MemInputStream.
	* @param data_, unsigned char *, a pointer to a memory chunk to read from
	* @param length_, unsigned int, the length of the data trunk
	*/
	MemInputStream(const unsigned char* data_, const unsigned int length_);

	/**
	* MemInputStream Destructor.
	* To Destruct MemInputStream
	*/
	virtual ~MemInputStream();

	/**
	* read function buffer data
	* @param buffer, void *, the data is read from the inputstream and fill in this buffer
	* @param size, int, the number of byte to be read from the input steam
	* @param reverseOrder, true , for big endian system
	*					   false, for little endian system
	*/
	virtual void ReadBuffer(void* buffer, int size, bool reverseOrder = false) override;

	/**
	* skip data from buffer
	* @param size, int, the number of byte to be skipped
	*/
	virtual void Skip(int size) override;

	/**
	* Get the length of buffer data
	* @return unsigned int, the length of InputStream
	*/
	virtual unsigned int GetSize() override;

	/**
	* Tell the current read position
	* @return unsigned int, the current read position
	*/
	virtual unsigned int Tell();

	/**
	* Check if the stream is opened
	* @return true, stream is opened, else stream is closed
	*/
	virtual bool IsOpened();

	/**
	* Rewind the stream, the stream current read position  will be reset to 0 by this function
	* @return true, stream is opened, else stream is closed
	*/
	virtual void Rewind();
private:
	MemInputStream(const MemInputStream&);
	MemInputStream& operator=(const MemInputStream&);

	const unsigned char* data_head;
	unsigned int len;

	const unsigned char* data_ptr;
	unsigned int current;
};

/**
* FileInputStream. The class is an InputStream for a file stream
*/
class FileInputStream : public InputStream
{
public:
	/**
	* FileInputStream Constructor.
	* To Construct the FileInputStream.
	* @param path_ , filename for the file of FileInputStream
	*/
	FileInputStream(const std::string& path_);

	/**
	* FileInputStream Destructor.
	* To Destruct FileInputStream and close the file
	*/
	virtual ~FileInputStream();

	/**
	* read function buffer data
	* @param buffer, void *, the data is read from the inputstream and fill in this buffer
	* @param size, int, the number of byte to be read from the input steam
	* @param reverseOrder, true , for big endian system
	*					   false, for little endian system
	*/
	virtual void ReadBuffer(void* buffer, int size, bool reverseOrder = false) override;

	/**
	* skip data from buffer
	* @param size, int, the number of byte to be skipped
	*/
	virtual void Skip(int size) override;

	/**
	* Get the length of buffer data
	* @return unsigned int, the length of InputStream
	*/
	virtual unsigned int GetSize() override;

	/**
	* Tell the current read position
	* @return unsigned int, the current read position
	*/
	virtual unsigned int Tell() override;

	/**
	* Check if the stream is opened
	* @return true, stream is opened, else stream is closed
	*/
	virtual bool IsOpened() override;

	/**
	* Rewind the stream, the stream current read position  will be reset to 0 by this function
	* @return true, stream is opened, else stream is closed
	*/
	virtual void Rewind() override;
private:
	FileInputStream(const FileInputStream&);
	FileInputStream& operator=(const FileInputStream&);

	FileIO file;
};

#if 0
#include "GZFileIO.h"

class GZMemInputStream : public InputStream
{
public:
	GZMemInputStream(const unsigned char* data_, const unsigned int length_);
	virtual ~GZMemInputStream();

	/**
	* read function buffer data
	* @param buffer, void *, the data is read from the inputstream and fill in this buffer
	* @param size, int, the number of byte to be read from the input steam
	* @param reverseOrder, true , for big endian system
	*					   false, for little endian system
	*/
	/**
	* skip data from buffer
	* @param size, int, the number of byte to be skipped
	*/
	/**
	* Get the length of buffer data
	* @return unsigned int, the length of InputStream
	*/
	/**
	* Tell the current read position
	* @return unsigned int, the current read position
	*/
	/**
	* Check if the stream is opened
	* @return true, stream is opened, else stream is closed
	*/
	/**
	* Rewind the stream, the stream current read position  will be reset to 0 by this function
	* @return true, stream is opened, else stream is closed
	*/
	virtual void readX(void* buffer, int size, bool reverseOrder = false);
	virtual void skip(int size);
	virtual unsigned int length();
	virtual unsigned int tell();
	virtual bool opened();
	virtual void rewind();
private:
	GZMemInputStream(const GZMemInputStream&);
	GZMemInputStream& operator=(const GZMemInputStream&);

	const unsigned char* data_head;
	const unsigned char* data;
	unsigned int current;
	unsigned int len;
};

class GZFileInputStream : public InputStream
{
public:
	/**
	* FileInputStream Constructor.
	* To Construct the FileInputStream.
	* @param path_ , filename for the file of FileInputStream
	*/
	GZFileInputStream(const std::string& path_);

	/**
	* FileInputStream Destructor.
	* To Destruct FileInputStream and close the file
	*/
	virtual ~GZFileInputStream();

	/**
	* read function buffer data
	* @param buffer, void *, the data is read from the inputstream and fill in this buffer
	* @param size, int, the number of byte to be read from the input steam
	* @param reverseOrder, true , for big endian system
	*					   false, for little endian system
	*/
	virtual void ReadBuffer(void* buffer, int size, bool reverseOrder = false) override;

	/**
	* skip data from buffer
	* @param size, int, the number of byte to be skipped
	*/
	virtual void Skip(int size) override;

	/**
	* Get the length of buffer data
	* @return unsigned int, the length of InputStream
	*/
	virtual unsigned int GetSize() override;

	/**
	* Tell the current read position
	* @return unsigned int, the current read position
	*/
	virtual unsigned int Tell() override;

	/**
	* Check if the stream is opened
	* @return true, stream is opened, else stream is closed
	*/
	virtual bool IsOpened() override;

	/**
	* Rewind the stream, the stream current read position  will be reset to 0 by this function
	* @return true, stream is opened, else stream is closed
	*/
	virtual void Rewind() override;
private:
	GZFileInputStream(const GZFileInputStream&);
	GZFileInputStream& operator=(const GZFileInputStream&);

	GZFileIO file;
};
#endif

template<class T> inline InputStream& operator>>(InputStream& is, T& data)
{
	data.Read(is);
	return is;
}

inline InputStream& operator>>(InputStream& is, bool& data)
{
	is.Read(data);
	return is;
}

inline InputStream& operator>>(InputStream& is, char& data)
{
	is.Read(data);
	return is;
}

inline InputStream& operator>>(InputStream& is, unsigned char& data)
{
	is.Read(data);
	return is;
}

inline InputStream& operator>>(InputStream& is, short& data)
{
	is.Read(data);
	return is;
}

inline InputStream& operator>>(InputStream& is, unsigned short& data)
{
	is.Read(data);
	return is;
}

inline InputStream& operator>>(InputStream& is, int& data)
{
	is.Read(data);
	return is;
}

inline InputStream& operator>>(InputStream& is, unsigned int& data)
{
	is.Read(data);
	return is;
}

inline InputStream& operator>>(InputStream& is, long& data)
{
	is.Read(data);
	return is;
}

inline InputStream& operator>>(InputStream& is, unsigned long& data)
{
	is.Read(data);
	return is;
}

inline InputStream& operator>>(InputStream& is, float& data)
{
	is.Read(data);
	return is;
}

inline InputStream& operator>>(InputStream& is, double& data)
{
	is.Read(data);
	return is;
}

inline InputStream& operator>>(InputStream& is, std::string& data)
{
	is.Read(data);
	return is;
}

template<class T> inline InputStream& operator>>(InputStream& is, std::vector<T>& values)
{
	int len;
	is >> len;
	values.resize(len);

	for (int i = 0; i < len; i++)
		is >> values[i];

	return is;
}

template<class Key, class Value> inline InputStream& operator>>(InputStream& is, std::map<Key, Value>& values)
{
	int len = values.size();
	is >> len;

	for (int i = 0; i < len; i++)
	{
		Key k;
		Value v;
		is >> k >> v;

		values[k] = v;
	}

	return is;
}

template<class Key> inline InputStream& operator>>(InputStream& is, std::set<Key>& values)
{
	int len = values.size();
	is >> len;

	for (int i = 0; i < len; i++)
	{
		Key k;
		is >> k;

		values.insert(k);
	}

	return is;
}

#endif