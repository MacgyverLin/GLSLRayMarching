#ifndef _MeshIO_h_
#define _MeshIO_h_

#include "Platform.h"

template<class T>
class MeshIO
{
public:
	MeshIO()
	{
	}

	~MeshIO()
	{
	}

	bool Load(T& mesh, const std::string& path)
	{
		return OnLoad(mesh, path);
	}

	bool Save(const T& mesh, const std::string& path)
	{
		return OnSave(mesh, path);
	}
private:
	virtual bool OnLoad(T& mesh, const std::string& path) = 0;
	
	virtual bool OnSave(const T& mesh, const std::string& path) = 0;
};


#endif