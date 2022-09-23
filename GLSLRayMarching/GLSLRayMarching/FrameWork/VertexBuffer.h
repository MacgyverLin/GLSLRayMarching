#ifndef _Primitives_h_
#define _Primitives_h_

#include "Platform.h"
#include <map>

class VertexAttribute
{
public:
	enum class DataType
	{
		BYTE = 0,
		UNSIGNED_BYTE,
		SHORT,
		UNSIGNED_SHORT,
		INT,
		UNSIGNED_INT,

		HALF_FLOAT,
		FLOAT,
		DOUBLE,
		FIXED,
		INT_2_10_10_10_REV,
		UNSIGNED_INT_2_10_10_10_REV,
		UNSIGNED_INT_10F_11F_11F_REV
	};

	VertexAttribute();
	VertexAttribute(unsigned int index_, int elementCount_, VertexAttribute::DataType type_, bool normalized_, unsigned int divisor_ = 0, unsigned int stride_ = 0);

	unsigned int index;
	int elementCount;
	int elementSize;
	DataType dataType;
	bool normalized;
	unsigned int stride;
	unsigned int divisor;
};

class VertexBuffer
{
public:
	enum class Mode
	{
		POINTS = 0,
		LINE_STRIP,
		LINE_LOOP,
		LINES,
		LINE_STRIP_ADJACENCY,
		LINES_ADJACENCY,
		TRIANGLE_STRIP,
		TRIANGLE_FAN,
		TRIANGLES,
		TRIANGLE_STRIP_ADJACENCY,
		TRIANGLES_ADJACENCY,
		PATCHES
	};

	VertexBuffer();
	virtual ~VertexBuffer();

	VertexBuffer& Begin();
	VertexBuffer& FillVertices(unsigned int index_, int elementCount_, VertexAttribute::DataType type_, bool normalized_, unsigned int stride_, unsigned int divisor_, const void* vertices_, int verticesCount_);
	VertexBuffer& FillIndices(const unsigned int* indices_, int indicesCount_);
	bool End();
	
	void Terminate();
	void Bind();
	void Unbind();

	////////////////////////////////////////////////////////////////////////////////////
	void DrawArray(VertexBuffer::Mode mode_, int first_, int count_);
	void DrawArrayInstanced(VertexBuffer::Mode mode_, int first_, int count_, int instancedCount_);
	void DrawArrayInstancedBaseInstance(VertexBuffer::Mode mode_, int first_, int count_, int instancedCount_, int baseInstance_);

	////////////////////////////////////////////////////////////////////////////////////
	void DrawIndices(VertexBuffer::Mode mode_, void* indices_, int count_);
	void DrawIndicesBaseVertex(VertexBuffer::Mode mode_, void* indices_, int count_, int baseVertex_);
	void DrawIndicesInstanced(VertexBuffer::Mode mode_, const void* indices_, int count_, int instancedCount_);
	void DrawIndicesInstancedBaseVertex(VertexBuffer::Mode mode_, const void* indices_, int count_, int instancedCount_, int baseVertex_);
	void DrawIndicesInstancedBaseInstance(VertexBuffer::Mode mode_, const void* indices_, int count_, int instancedCount_, int baseInstance_);
	void DrawIndicesInstancedBaseVertexBaseInstance(VertexBuffer::Mode mode_, const void* indices_, int count_, int instancedCount_, int baseVertex_, int baseInstance_);
	void DrawIndicesIndirect(VertexBuffer::Mode mode_, void* indirect_);
	
	//////////////////////////////////////////////////////////////////////////
	void MultiDrawArray(VertexBuffer::Mode mode_, int* first_, int* count_, unsigned int mulitDrawCount_);
	void MultiDrawArrayIndirect(VertexBuffer::Mode mode_, const void* indirect_, int mulitDrawCount_, int stride_ = 0);
	void MultiDrawIndices(VertexBuffer::Mode mode_, const void* const* indices_, int* count_, int mulitDrawCount_);
	void MultiDrawIndicesBaseVertex(VertexBuffer::Mode mode_, const void* const* indices_, int* count_, int* baseVertex_, int mulitDrawCount_);
	void MultiDrawIndicesIndirect(VertexBuffer::Mode mode_, const void* indirect_, int mulitDrawCount_, int stride_);
	unsigned int GetCount();
private:
private:
	std::map<int, VertexAttribute> vertexAttributes;
	std::map<int, unsigned int> vbos;
	unsigned int vao;
	unsigned int ebo;
	unsigned int verticesCount;
	unsigned int indicesCount;
};

#endif