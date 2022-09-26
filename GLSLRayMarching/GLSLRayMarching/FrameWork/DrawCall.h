#ifndef _DrawCall_h_
#define _DrawCall_h_

#include "Platform.h"
#include "VertexBuffer.h"
#include "ShaderProgram.h"
#include "Texture.h"
#include "Buffer.h"

class DrawCall
{
public:
	DrawCall();
	virtual ~DrawCall();

	DrawCall& SetVertexBuffer(VertexBuffer* vertexBuffer_);
	DrawCall& SetShaderProgram(ShaderProgram* shaderProgram_);
	DrawCall& SetBuffer(const char* name_, Buffer* uniformBuffer_);
	DrawCall& SetTexture(const char* name_, Texture* texture_);

	VertexBuffer* GetVertexBuffer();
	ShaderProgram* GetShaderProgram();
	const std::map<const char*, Buffer*>& GetBuffers();
	Buffer* GetBuffer(const char* name_);
	const std::map<const char*, Texture*>& GetTextures();
	Texture* GetTexture(const char* name_);

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

	void Bind();
	void Unbind();
private:
	VertexBuffer* vertexBuffer;
	ShaderProgram* shaderProgram;
	std::map<const char*, Buffer*> buffers;
	std::map<const char*, Texture*> textures;
};

#endif