#include "DrawCall.h"

DrawCall::DrawCall()
: vertexBuffer(nullptr)
, shaderProgram(nullptr)
, buffers()
, textures()
{
}

DrawCall::~DrawCall()
{
}

DrawCall& DrawCall::SetVertexBuffer(VertexBuffer* vertexBuffer_)
{
	vertexBuffer = vertexBuffer_;

	return *this;
}

DrawCall& DrawCall::SetShaderProgram(ShaderProgram* shaderProgram_)
{
	shaderProgram = shaderProgram_;

	return *this;
}

DrawCall& DrawCall::SetBuffer(const char* name_, Buffer* buffer_)
{
	buffers[name_] = buffer_;

	return *this;
}

DrawCall& DrawCall::SetTexture(const char* name_, Texture* texture_)
{
	textures[name_] = texture_;

	return *this;
}

VertexBuffer* DrawCall::GetVertexBuffer()
{
	return vertexBuffer;
}

ShaderProgram* DrawCall::GetShaderProgram()
{
	return shaderProgram;
}

const std::map<const char*, Buffer*>& DrawCall::GetBuffers()
{
	return buffers;
}

Buffer* DrawCall::GetBuffer(const char* name_)
{
	return buffers[name_];
}

const std::map<const char*, Texture*>& DrawCall::GetTextures()
{
	return textures;
}

Texture* DrawCall::GetTexture(const char* name_)
{
	return textures[name_];
}

////////////////////////////////////////////////////////////////////////////////////
void DrawCall::DrawArray(VertexBuffer::Mode mode_, int first_, int count_)
{
	Bind();

	vertexBuffer->DrawArray(mode_, first_, count_);
}

void DrawCall::DrawArrayInstanced(VertexBuffer::Mode mode_, int first_, int count_, int instancedCount_)
{
	Bind();

	vertexBuffer->DrawArrayInstanced(mode_, first_, count_, instancedCount_);
}

void DrawCall::DrawArrayInstancedBaseInstance(VertexBuffer::Mode mode_, int first_, int count_, int instancedCount_, int baseInstance_)
{
	Bind();

	vertexBuffer->DrawArrayInstancedBaseInstance(mode_, first_, count_, instancedCount_, baseInstance_);
}

////////////////////////////////////////////////////////////////////////////////////
void DrawCall::DrawIndices(VertexBuffer::Mode mode_, void* indices_, int count_)
{
	Bind();

	vertexBuffer->DrawIndices(mode_, indices_, count_);
}

void DrawCall::DrawIndicesBaseVertex(VertexBuffer::Mode mode_, void* indices_, int count_, int baseVertex_)
{
	Bind();

	vertexBuffer->DrawIndicesBaseVertex(mode_, indices_, count_, baseVertex_);
}

void DrawCall::DrawIndicesInstanced(VertexBuffer::Mode mode_, const void* indices_, int count_, int instancedCount_)
{
	Bind();

	vertexBuffer->DrawIndicesInstanced(mode_, indices_, count_, instancedCount_);
}

void DrawCall::DrawIndicesInstancedBaseVertex(VertexBuffer::Mode mode_, const void* indices_, int count_, int instancedCount_, int baseVertex_)
{
	Bind();

	vertexBuffer->DrawIndicesInstancedBaseVertex(mode_, indices_, count_, instancedCount_, baseVertex_);
}

void DrawCall::DrawIndicesInstancedBaseInstance(VertexBuffer::Mode mode_, const void* indices_, int count_, int instancedCount_, int baseInstance_)
{
	Bind();

	vertexBuffer->DrawIndicesInstancedBaseInstance(mode_, indices_, count_, instancedCount_, baseInstance_);
}

void DrawCall::DrawIndicesInstancedBaseVertexBaseInstance(VertexBuffer::Mode mode_, const void* indices_, int count_, int instancedCount_, int baseVertex_, int baseInstance_)
{
	Bind();

	vertexBuffer->DrawIndicesInstancedBaseVertexBaseInstance(mode_, indices_, count_, instancedCount_, baseVertex_, baseInstance_);
}

void DrawCall::DrawIndicesIndirect(VertexBuffer::Mode mode_, void* indirect_)
{
	Bind();

	vertexBuffer->DrawIndicesIndirect(mode_, indirect_);
}
	
//////////////////////////////////////////////////////////////////////////
void DrawCall::MultiDrawArray(VertexBuffer::Mode mode_, int* first_, int* count_, unsigned int mulitDrawCount_)
{
	Bind();

	vertexBuffer->MultiDrawArray(mode_, first_, count_, mulitDrawCount_);
}

void DrawCall::MultiDrawArrayIndirect(VertexBuffer::Mode mode_, const void* indirect_, int mulitDrawCount_, int stride_)
{
	Bind();

	vertexBuffer->MultiDrawArrayIndirect(mode_, indirect_, mulitDrawCount_, stride_);
}

void DrawCall::MultiDrawIndices(VertexBuffer::Mode mode_, const void* const* indices_, int* count_, int mulitDrawCount_)
{
	Bind();

	vertexBuffer->MultiDrawIndices(mode_, indices_, count_,  mulitDrawCount_);
}

void DrawCall::MultiDrawIndicesBaseVertex(VertexBuffer::Mode mode_, const void* const* indices_, int* count_, int* baseVertex_, int mulitDrawCount_)
{
	Bind();

	vertexBuffer->MultiDrawIndicesBaseVertex(mode_, indices_, count_, baseVertex_, mulitDrawCount_);
}

void DrawCall::MultiDrawIndicesIndirect(VertexBuffer::Mode mode_, const void* indirect_, int mulitDrawCount_, int stride_)
{
	Bind();

	vertexBuffer->MultiDrawIndicesIndirect(mode_, indirect_, mulitDrawCount_, stride_);
}

unsigned int DrawCall::GetCount()
{
	Assert(vertexBuffer);

	return vertexBuffer->GetCount();
}

void DrawCall::Bind()
{
	if (vertexBuffer)
		vertexBuffer->Bind();

	if (shaderProgram)
		shaderProgram->Bind();

	for (auto& buffer : buffers)
	{
		if (buffer.second)
			buffer.second->Bind();
	}

	for (auto& texture : textures)
	{
		if(texture.second)
			texture.second->Bind(0);
	}
}

void DrawCall::Unbind()
{
	if (vertexBuffer)
		vertexBuffer->Unbind();

	if (shaderProgram)
		shaderProgram->Unbind();

	for (auto& buffer : buffers)
	{
		if (buffer.second)
			buffer.second->Unbind();
	}

	for (auto& texture : textures)
	{
		if (texture.second)
			texture.second->Unbind();
	}
}