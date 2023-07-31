/////////////////////////////////////////////////////////////////////////////////////
// Copyright(c) 2016, Lin Koon Wing Macgyver, macgyvercct@yahoo.com.hk			 //
//																				 //
// Author : Mac Lin									                             //
// Module : Magnum Engine v0.7.0												 //
// Date   : 14/Jun/2020											                 //
//																				 //
///////////////////////////////////////////////////////////////////////////////////
#ifndef _GZFileIO_h_
#define _GZFileIO_h_

#include "Platform.h"

#include "IO.h"

#if 0
class GZFileIO : public IO
{
public:
	GZFileIO(const std::string& path_);
	virtual ~GZFileIO();

	virtual bool Open(AccessMode mode) override;
	virtual bool OpenForAsync(AccessMode mode) override;
	virtual bool IsAsyncFinished() override;
	virtual void WaitAsyncFinished() override;
	virtual bool Close() override;
	virtual bool IsOpened() const override;

	virtual int Tell() const override;
	virtual int Seek(SeekDef from, int offset = 0) override;

	virtual int Read(void* buf, int size) override;
	virtual int Read(unsigned char* uc) override;
	virtual int Read(char* c) override;
	virtual int Read(unsigned short* us) override;
	virtual int Read(short* s) override;
	virtual int Read(unsigned int* ui) override;
	virtual int Read(int* i) override;
	virtual int Read(unsigned long* ui)  override;
	virtual int Read(long* i) override;
	virtual int Read(float* f) override;
	virtual int Read(double* d) override;

	virtual int Write(const void* buf, int size) override;
	virtual int Write(const unsigned char* uc) override;
	virtual int Write(const char* c) override;
	virtual int Write(const unsigned short* us) override;
	virtual int Write(const short* s) override;
	virtual int Write(const unsigned int* ui) override;
	virtual int Write(const int* i) override;
	virtual int Write(const unsigned long* ui) override;
	virtual int Write(const long* i) override;
	virtual int Write(const float* f) override;
	virtual int Write(const double* d) override;

	virtual int GetSize() const override;

	void SetCompressionLevel(int level);
	int GetCompressionLevel() const;

	static bool Exists(const std::string& path_);
	static int GetSize(const std::string& path_);
	static bool Load(const std::string& path_, void* data, int size, int offset);
private:
	void* user;
};

#endif

#endif