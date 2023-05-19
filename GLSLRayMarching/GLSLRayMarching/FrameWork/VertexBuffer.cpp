#include "Platform.h"
#include "VertexBuffer.h"
#include "Graphics.h"

static int vaElementSizes[] =
{
	1, 1, 2, 2, 4, 4, 2, 4, 8, 4, 4, 4, 4
};

static int vaDataTypes[] =
{
	GL_BYTE,
	GL_UNSIGNED_BYTE,
	GL_SHORT,
	GL_UNSIGNED_SHORT,
	GL_INT,
	GL_UNSIGNED_INT,
	
	GL_HALF_FLOAT,
	GL_FLOAT,
	GL_DOUBLE,
	GL_FIXED,
	GL_INT_2_10_10_10_REV,
	GL_UNSIGNED_INT_2_10_10_10_REV,
	GL_UNSIGNED_INT_10F_11F_11F_REV
};

VertexAttribute::VertexAttribute()
: index(0)
, elementCount(3)
, dataType(DataType::FLOAT)
, normalized(true)
, stride(12)
, divisor(1)
, elementSize(0)
{
}

VertexAttribute::VertexAttribute(unsigned int index_, int elementCount_, VertexAttribute::DataType dataType_, bool normalized_, unsigned int divisor_, unsigned int stride_)
: index(index_)
, elementCount(elementCount_)
, dataType(dataType_)
, normalized(normalized_)
, stride(stride_)
, divisor(divisor_)
, elementSize(0)
{
	elementSize = vaElementSizes[(int)dataType];
	if (stride)
	{
		stride = elementCount * elementSize;
	}
}

//////////////////////////////////////////////////////////////////////////////////
static int primModes[] =
{
	GL_POINTS,
	GL_LINE_STRIP,
	GL_LINE_LOOP,
	GL_LINES,
	GL_LINE_STRIP_ADJACENCY,
	GL_LINES_ADJACENCY,
	GL_TRIANGLE_STRIP,
	GL_TRIANGLE_FAN,
	GL_TRIANGLES,
	GL_TRIANGLE_STRIP_ADJACENCY,
	GL_TRIANGLES_ADJACENCY,
	GL_PATCHES
};

VertexBuffer::VertexBuffer()
: vao(0)
, vertexAttributes()
, vbos()
, ebo(0)
, verticesCount(0)
, indicesCount(0)
{
}

VertexBuffer::~VertexBuffer()
{
	Terminate();
}

VertexBuffer& VertexBuffer::Begin()
{
	Terminate();

	glGenVertexArrays(1, &vao);
	Assert(vao);

	glBindVertexArray(vao);

	return *this;	
}

VertexBuffer& VertexBuffer::FillVertices(unsigned int index_, int elementCount_, VertexAttribute::DataType type_, bool normalized_, unsigned int stride_, unsigned int divisor_, const void* vertices_, int verticesCount_)
{
	if (vbos.find(index_) != vbos.end())
	{
		vbos.erase(index_);
		vertexAttributes.erase(index_);
	}

	glGenBuffers(1, &vbos[index_]);
	Assert(vbos[index_]);
	unsigned int& vbo = vbos[index_];

	vertexAttributes[index_] = VertexAttribute(index_, elementCount_, type_, normalized_, divisor_, stride_);
	VertexAttribute& v = vertexAttributes[index_];
		
	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	glBufferData(GL_ARRAY_BUFFER, verticesCount_ * elementCount_* vaElementSizes[(int)v.dataType], vertices_, GL_STATIC_DRAW);
	glEnableVertexAttribArray(v.index);
	glVertexAttribPointer(v.index, v.elementCount, vaDataTypes[(int)v.dataType], v.normalized, v.elementCount * v.elementSize, (void*)0);
	glVertexAttribDivisor(v.index, v.divisor);

	verticesCount = verticesCount_;

	return *this;
}

VertexBuffer& VertexBuffer::FillIndices(const unsigned int* indices_, int indicesCount_)
{
	glGenBuffers(1, &ebo);
	Assert(ebo);

	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, indicesCount_ * sizeof(int), indices_, GL_STATIC_DRAW);

	indicesCount = indicesCount_;

	return *this;
}

bool VertexBuffer::End()
{
	glBindVertexArray(0);

	return vao;
}

void VertexBuffer::Terminate()
{
	vertexAttributes.clear();

	if (vao)
	{
		for (auto& vbo : vbos)
		{
			if (vbo.second)
			{
				glDeleteBuffers(1, &vbo.second);
				vbo.second = 0;
			}
		}

		if (ebo)
		{
			glDeleteBuffers(1, &ebo);
			ebo = 0;
		}

		glDeleteVertexArrays(1, &vao);
		vao = 0;
	}
}

void VertexBuffer::Bind()
{
	if (vao)
	{
		glBindVertexArray(vao);
	}
}

void VertexBuffer::Unbind()
{
	glBindVertexArray(0);
}

void VertexBuffer::DrawArray(VertexBuffer::Mode mode_, int first_, int count_)
{
	glDrawArrays(primModes[(int)mode_], first_, count_);
}

void VertexBuffer::DrawArrayInstanced(VertexBuffer::Mode mode_, int first_, int count_, int instancedCount_)
{
	/*
	if ( mode or count is invalid )
	{
		generate appropriate error
	}
	else
	{
		for (int i = 0; i < instancecount ; i++)
		{
			instanceID = i;
			glDrawArrays(mode, first, count);
		}
		instanceID = 0;
	}
	*/
	glDrawArraysInstanced(primModes[(int)mode_], first_, count_, instancedCount_);
}

void VertexBuffer::DrawArrayInstancedBaseInstance(VertexBuffer::Mode mode_, int first_, int count_, int instancedCount_, int baseInstance_)
{
	/*
	if ( mode or count is invalid )
	{
		generate appropriate error
	}
	else
	{
		for (int i = 0; i < instancecount ; i++)
		{
			instanceID = i;
			glDrawArrays(mode, first, count);
		}
		instanceID = 0;
	}
	*/
	glDrawArraysInstancedBaseInstance(primModes[(int)mode_], first_, count_, instancedCount_, baseInstance_);
}

////////////////////////////////////////////////////////////////////////////////////
void VertexBuffer::DrawIndices(VertexBuffer::Mode mode_, void* indices_, int count_)
{
	assert((ebo && indices_==0) || !indices_);

	glDrawElements(primModes[(int)mode_], count_, GL_UNSIGNED_INT, indices_);
}

void VertexBuffer::DrawIndicesBaseVertex(VertexBuffer::Mode mode_, void* indices_, int count_, int baseVertex_)
{
	assert((ebo && indices_ == 0) || !indices_);

	glDrawElementsBaseVertex(primModes[(int)mode_], count_, GL_UNSIGNED_INT, indices_, baseVertex_);
}

void VertexBuffer::DrawIndicesInstanced(VertexBuffer::Mode mode_, const void* indices_, int count_, int instancedCount_)
{
	assert((ebo && indices_ == 0) || !indices_);
		
	glDrawElementsInstanced(primModes[(int)mode_], count_, GL_UNSIGNED_INT, indices_, instancedCount_);
}

void VertexBuffer::DrawIndicesInstancedBaseVertex(VertexBuffer::Mode mode_, const void* indices_, int count_, int instancedCount_, int baseVertex_)
{
	/*
	if ( mode or count is invalid )
	{
		generate appropriate error
	}
	else
	{
		for (int i = 0; i < instancecount ; i++)
		{
			instanceID = i;
			glDrawArrays(mode, first, count);
		}
		instanceID = 0;
	}
	*/
	assert((ebo && indices_ == 0) || !indices_);

	glDrawElementsInstancedBaseVertex(primModes[(int)mode_], count_, GL_UNSIGNED_INT, indices_, instancedCount_, baseVertex_);
}

void VertexBuffer::DrawIndicesInstancedBaseInstance(VertexBuffer::Mode mode_, const void* indices_, int count_, int instancedCount_, int baseInstance_)
{
	/*
	if (mode, count, or type is invalid )
	{
		generate appropriate error
	}
	else 
	{
		for (int i = 0; i < instancecount ; i++) 
		{
			instanceID = i;
			glDrawElements(mode, count, type, indices);
		}
		instanceID = 0;
	}
	*/
	assert((ebo && indices_ == 0) || !indices_);

	glDrawElementsInstancedBaseInstance(primModes[(int)mode_], count_, GL_UNSIGNED_INT, indices_, instancedCount_, baseInstance_);
}

void VertexBuffer::DrawIndicesInstancedBaseVertexBaseInstance(VertexBuffer::Mode mode_, const void* indices_, int count_, int instancedCount_, int baseVertex_, int baseInstance_)
{
	/*
	if ( mode or count is invalid )
	{
		generate appropriate error
	}
	else
	{
		for (int i = 0; i < instancecount ; i++)
		{
			instanceID = i;
			glDrawArrays(mode, first, count);
		}
		instanceID = 0;
	}
	*/
	assert((ebo && indices_ == 0) || !indices_);

	glDrawElementsInstancedBaseVertexBaseInstance(primModes[(int)mode_], count_, GL_UNSIGNED_INT, indices_, instancedCount_, baseVertex_, baseInstance_);
}

void VertexBuffer::DrawIndicesIndirect(VertexBuffer::Mode mode_, void* indirect_)
{
	/*
	typedef  struct 
	{
		uint  count;
		uint  instancedCount;
		uint  first;
		uint  baseVertex;
		uint  baseInstance;
	} DrawElementsIndirectCommand;
	
	const DrawElementsIndirectCommand *cmd  = (const DrawElementsIndirectCommand *)indirect;
	glDrawElementsInstancedBaseVertexBaseInstance(mode,
												  cmd->count,
												  type,
												  cmd->first * size-of-type,
												  cmd->instancedCount,
												  cmd->baseVertex,
												  cmd->baseInstance);
	*/
	glDrawElementsIndirect(primModes[(int)mode_], GL_UNSIGNED_INT, indirect_);
}

//////////////////////////////////////////////////////////////////////////
void VertexBuffer::MultiDrawArray(VertexBuffer::Mode mode_, int* first_, int* count_, unsigned int mulitDrawCount_)
{
	glMultiDrawArrays(primModes[(int)mode_], first_, count_, mulitDrawCount_);
}

void VertexBuffer::MultiDrawArrayIndirect(VertexBuffer::Mode mode_, const void* indirect_, int mulitDrawCount_, int stride_)
{
	/*
	typedef  struct
	{
		uint  count;
		uint  instanceCount;
		uint  first;
		uint  baseInstance;
	} DrawArraysIndirectCommand;
	GLsizei n;
	for (n = 0; n < drawcount; n++)
	{
		const DrawArraysIndirectCommand* cmd;
		if (stride != 0)
		{
			cmd = (const DrawArraysIndirectCommand*)((uintptr)indirect + n * stride);
		}
		else
		{
			cmd = (const DrawArraysIndirectCommand*)indirect + n;
		}

		glDrawArraysInstancedBaseInstance(mode, cmd->first, cmd->count, cmd->instanceCount, cmd->baseInstance);
	}
	*/
	glMultiDrawArraysIndirect(primModes[(int)mode_], indirect_, mulitDrawCount_, stride_);
}

void VertexBuffer::MultiDrawIndices(VertexBuffer::Mode mode_, const void* const* indices_, int* count_, int mulitDrawCount_)
{
	assert((ebo && indices_ == 0) || !indices_);

	glMultiDrawElements(primModes[(int)mode_], count_, GL_UNSIGNED_INT, indices_, mulitDrawCount_);
}

void VertexBuffer::MultiDrawIndicesBaseVertex(VertexBuffer::Mode mode_, const void* const* indices_, int* count_, int* baseVertex_, int mulitDrawCount_)
{
	assert((ebo && indices_ == 0) || !indices_);

	glMultiDrawElementsBaseVertex(primModes[(int)mode_], count_, GL_UNSIGNED_INT, indices_, mulitDrawCount_, baseVertex_);
}

void VertexBuffer::MultiDrawIndicesIndirect(VertexBuffer::Mode mode_, const void* indirect_, int mulitDrawCount_, int stride_)
{
	/*
	typedef  struct {
		uint  count;
		uint  instanceCount;
		uint  first;
		uint  baseVertex;
		uint  baseInstance;
	} DrawElementsIndirectCommand;

	GLsizei n;
	for (n = 0; n < drawcount; n++) 
	{
		const DrawElementsIndirectCommand *cmd;
		if (stride != 0) 
		{
			cmd = (const DrawElementsIndirectCommand  *)((uintptr)indirect + n * stride);
		} 
		else 
		{
			cmd = (const DrawElementsIndirectCommand  *)indirect + n;
		}

		glDrawElementsInstancedBaseVertexBaseInstance(mode,
													cmd->count,
													type,
													cmd->first * size-of-type,
													cmd->instanceCount,
													cmd->baseVertex,
													cmd->baseInstance);
	}
	*/
	glMultiDrawElementsIndirect(primModes[(int)mode_], GL_UNSIGNED_INT, indirect_, mulitDrawCount_, stride_);
}

unsigned int VertexBuffer::GetCount()
{
	if (ebo)
	{
		return indicesCount;
	}
	else
	{
		return verticesCount;
	}
}