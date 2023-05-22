#ifndef _Graphics_h_
#define _Graphics_h_

#include "Platform.h"

#include <glad\glad.h>
#include <GLFW\glfw3.h>

/*
////////////////////////////////////////////
Buffer
2.0
//glGenBuffers
//glBufferData
//glBufferSubData
//glBindBuffer
//glDeleteBuffers
//glIsBuffer
3.0
//glBindBufferRange
//glBindBufferBase
//glFlushMappedBufferRange
//glMapBufferRange
//glUnmapBuffer
//glCopyBufferSubData
getter
- glGetBufferParameteri64v
- glGetBufferParameteriv
- glGetBufferPointerv

////////////////////////////////////////////
Frame Buffer
2.0
// glGenFramebuffers
// glDeleteFramebuffers
// glBindFramebuffer
// glIsFramebuffer
// glCheckFramebufferStatus
// glFramebufferTexture2D
*  glBindRenderbuffer
*  glFramebufferRenderbuffer
3.0
*  glDrawBuffers
// glClearBufferfi
// glClearBufferfv
// glClearBufferiv
// glClearBufferuiv
// glFramebufferTextureLayer
// glInvalidateFramebuffer
// glInvalidateSubFramebuffer
// glBlitFramebuffer
3.1
-  glFramebufferParameteri
3.2
-  glFramebufferTexture
getter
-  glGetFramebufferAttachmentParameteriv
-  glGetFramebufferParameteriv

////////////////////////////////////////////
RenderBuffer
2.0
glGenRenderbuffers
glDeleteRenderbuffers
glRenderbufferStorage
glIsRenderbuffer
3.0
glRenderbufferStorageMultisample
getter
glGetRenderbufferParameteriv

////////////////////////////////////////////
Samplers
3.0
glGenSamplers
glDeleteSamplers
glBindSampler
glIsSampler
glSamplerParameterf
glSamplerParameteri
glSamplerParameteriv
glSamplerParameterfv
glGetSamplerParameterfv
glGetSamplerParameteriv
3.2
glSamplerParameterIiv
glSamplerParameterIuiv
glGetSamplerParameterIiv
glGetSamplerParameterIuiv

////////////////////////////////////////////
Texture
2.0
//glGenTextures
//glDeleteTextures
--glPixelStorei
//glActiveTexture
//glBindTexture
-glIsTexture
glTexParameterf
glTexParameterfv
//glTexParameteri
//glTexParameteriv
//glTexImage2D
//glTexSubImage2D
//glCopyTexImage2D
//glCopyTexSubImage2D
//glCompressedTexImage2D
//glCompressedTexSubImage2D
//glGenerateMipmap
3.0
//glTexImage3D
//glTexSubImage3D
glCopyTexSubImage3D
//glCompressedTexImage3D
//glCompressedTexSubImage3D
glTexStorage2D
glTexStorage3D
3.1
--glBindImageTexture
glTexStorage2DMultisample
glTexStorage3DMultisample
3.2
glTexBuffer
glTexBufferRange
glCopyImageSubData
glTexParameterIiv
glTexParameterIuiv
getter
glGetTexLevelParameter
glGetTexLevelParameterfv
glGetTexLevelParameteriv
glGetTexParameter
glGetTexParameterfv
glGetTexParameterIiv
glGetTexParameterIuiv
glGetTexParameteriv

///////////////////////////////////////////////////////
ShaderProgram
2.0
//glCreateProgram
//glDeleteProgram
//glLinkProgram
--glIsProgram
//glUseProgram
--glValidateProgram
//glCreateShader
//glDeleteShader
//glAttachShader
//glDetachShader
//glCompileShader
//glShaderSource
//glShaderBinary
//glIsShader
--glBindAttribLocation
//glReleaseShaderCompiler
3.0
//glProgramBinary
//glProgramParameteri
--glCreateShaderProgram
--glCreateShaderProgramv

Uniform
2.0
//glGetUniformfv
//glGetUniformiv
//glGetUniformLocation
--glGetActiveUniform
//glUniform1f
//glUniform1fv
//glUniform1i
//glUniform1iv
//glUniform1ui
//glUniform1uiv
//glUniform2f
//glUniform2fv
//glUniform2i
//glUniform2iv
//glUniform2ui
//glUniform2uiv
//glUniform3f
//glUniform3fv
//glUniform3i
//glUniform3iv
//glUniform3ui
//glUniform3uiv
//glUniform4f
//glUniform4fv
//glUniform4i
//glUniform4iv
//glUniform4ui
//glUniform4uiv
//glUniformMatrix2fv
//glUniformMatrix2x3fv
//glUniformMatrix2x4fv
//glUniformMatrix3fv
//glUniformMatrix3x2fv
//glUniformMatrix3x4fv
//glUniformMatrix4fv
//glUniformMatrix4x2fv
//glUniformMatrix4x3fv
3.0
//glShaderStorageBlockBinding
glGetUniformuiv 
glGetUniformIndices
//glUniformBlockBinding
//glGetUniformBlockIndex
--glGetActiveUniformBlockiv
--glGetActiveUniformBlockName
-glGetActiveUniformsiv
3.1
--glProgramUniform1f have binded version
--glProgramUniform1fv
--glProgramUniform1i
--glProgramUniform1iv
--glProgramUniform1ui
--glProgramUniform1uiv
--glProgramUniform2f
--glProgramUniform2fv
--glProgramUniform2i
--glProgramUniform2iv
--glProgramUniform2ui
--glProgramUniform2uiv
--glProgramUniform3f
--glProgramUniform3fv
--glProgramUniform3i
--glProgramUniform3iv
--glProgramUniform3ui
--glProgramUniform3uiv
--glProgramUniform4f
--glProgramUniform4fv
--glProgramUniform4i
--glProgramUniform4iv
--glProgramUniform4ui
--glProgramUniform4uiv
--glProgramUniformMatrix2fv
--glProgramUniformMatrix2x3fv
--glProgramUniformMatrix2x4fv
--glProgramUniformMatrix3fv
--glProgramUniformMatrix3x2fv
--glProgramUniformMatrix3x4fv
--glProgramUniformMatrix4fv
--glProgramUniformMatrix4x2fv
--glProgramUniformMatrix4x3fv
3.2
glGetnUniformfv
glGetnUniformiv
glGetnUniformuiv
getter
glGetPointerv
glGetProgramBinary
glGetProgramInfoLog
glGetProgramInterface
glGetProgramInterfaceiv
glGetProgramiv
glGetProgramResource
glGetProgramResourceIndex
glGetProgramResourceiv
glGetProgramResourceLocation
glGetProgramResourceName
glGetShaderInfoLog
glGetShaderiv
glGetShaderPrecisionFormat
glGetShaderSource
glGetAttachedShaders

////////////////////////////////////////////
Vertex Array
2.0
//glGenVertexArrays
//glDeleteVertexArrays
//glBindVertexArray
//glIsVertexArray
//glEnableVertexAttribArray
//glDisableVertexAttribArray
--glVertexAttrib1f
--glVertexAttrib2f
--glVertexAttrib3f
--glVertexAttrib4f
--glVertexAttrib1fv
--glVertexAttrib2fv
--glVertexAttrib3fv
--glVertexAttrib4fv
//glVertexAttribPointer
--glGetVertexAttribfv
--glGetVertexAttribiv
--glGetVertexAttribPointerv
3.0
--glVertexAttribI4i
--glVertexAttribI4iv
--glVertexAttribI4ui
--glVertexAttribI4uiv
--glVertexAttribIPointer
--glGetVertexAttribIiv
--glGetVertexAttribIuiv
--glVertexAttribBinding
//glVertexAttribDivisor
3.1
glVertexAttribFormat
glVertexAttribIFormat
glVertexBindingDivisor
//glBindVertexBuffer
getter
--glGetActiveAttrib
--glGetAttribLocation

////////////////////////////////////////////
RenderStates
2.0
//glDisable
//glEnable
//glIsEnabled
//glDisablei
//glEnablei
//glIsEnabledi
Stencil
2.0
//glStencilFunc
//glStencilMask
//glStencilOp
//glStencilFuncSeparate
//glStencilMaskSeparate
//glStencilOpSeparate
Cull Face
2.0
//glCullFace
//glFrontFace
Blend State
2.0
//glBlendColor
//glBlendEquation
//glBlendFunc
//glBlendEquationSeparate
//glBlendFuncSeparate
3.2
//glBlendEquationi
//glBlendFunci
//glBlendEquationSeparatei
//glBlendFuncSeparatei
--glBlendBarrier
Clear State
2.0
//glClear
//glClearColor
//glClearDepthf
//glClearStencil
Color Mask
2.0
glColorMask
3.2
glColorMaski
Depth State
2.0
//glDepthFunc
//glDepthMask
//glDepthRangef
Misc
2.0
glSampleCoverage
glLineWidth
//glPolygonOffset
//glScissor
//glViewport
glMinSampleShading
3.1
glSampleMaski

////////////////////////////////////////////
Draw
glDrawArrays
glDrawArraysIndirect
glDrawArraysInstanced
glDrawElements
glDrawElementsInstanced
glDrawElementsIndirect
glDrawElementsBaseVertex
glDrawElementsInstancedBaseVertex
glDrawRangeElements
glDrawRangeElementsBaseVertex

////////////////////////////////////////////
Compute
3.1
glDispatchCompute
glDispatchComputeIndirect

////////////////////////////////////////////
PipeLine
3.1
glGenProgramPipelines
glGetProgramPipeline
glGetProgramPipelineInfoLog
glGetProgramPipelineiv
glBindProgramPipeline
glDeleteProgramPipelines
glIsProgramPipeline
glValidateProgramPipeline
glActiveShaderProgram
glUseProgramStages

///////////////////////////////////////////////////
Pixel ReadBack
2.0
glReadPixels
3.0
glReadBuffer
3.2
glReadnPixels

///////////////////////////////////////////////////
TransformFeedback
3.0
glGenTransformFeedbacks
glDeleteTransformFeedbacks
glIsTransformFeedback
glBindTransformFeedback
glBeginTransformFeedback
glEndTransformFeedback
glPauseTransformFeedback
glResumeTransformFeedback
glGetTransformFeedbackVarying
glTransformFeedbackVaryings

////////////////////////////////////////////
Query 3.0
GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN
GL_PRIMITIVES_GENERATED
GL_ANY_SAMPLES_PASSED_CONSERVATIVE
GL_ANY_SAMPLES_PASSED
glGenQueries
glDeleteQueries
glBeginQuery
glEndQuery
glGetQueryiv
glGetQueryObjectuiv
glIsQuery

////////////////////////////////////////////
Sync
3.0
glFenceSync
glDeleteSync
glIsSync
glGetSynciv
glWaitSync
glClientWaitSync

Memory Barrier
glMemoryBarrier
glMemoryBarrierByRegion

DebugGroup, Message
3.2
glPopDebugGroup
glPushDebugGroup
glDebugMessageCallback
glDebugMessageControl
glDebugMessageInsert
glGetDebugMessageLog
glObjectLabel
glObjectPtrLabel
glGetObjectLabel
glGetObjectPtrLabel

////////////////////////////////////////////////////////
Getter
glGetFragDataLocation
glGetGraphicsResetStatus
glGetError
glGetBooleani_v
glGetBooleanv
glGetFloatv
glGetInteger64i_v
glGetInteger64v
glGetIntegeri_v
glGetIntegerv
glGetInternalformativ
glGetMultisamplefv
glGetString
glGetStringi

////////////////////////////////////////////////
misc
glFinish
glFlush
glHint
glPatchParameteri
glPrimitiveBoundingBox
*/

class Graphics
{
	class Impl;
public:
public:
	Graphics();

	~Graphics();

	bool Initialize(int width_, int height_, const char* appName_);

	bool PreUpdate();

	bool PostUpdate();

	bool Pause();

	void Resume();

	void Terminate();

	const std::string& GetAppName() const;
	
	int GetWidth() const;

	int GetHeight() const;

	double GetTime() const;

	double GetDeltaTime() const;

	int GetTotalFrameCounter() const;

	int GetSceneFrameCounter() const;

	void ResetSceneFrameCounter();

	int GetKeyCount() const;

	bool GetKeyDown(Platform::KeyCode code) const;

	bool GetKeyUp(Platform::KeyCode code) const;

	bool GetKeyHold(Platform::KeyCode code) const;

	bool GetKey(Platform::KeyCode code) const;

	Platform::Mouse GetMouse() const;

	float GetMouseX() const;

	float GetMouseY() const;

	float GetMouseDX() const;

	float GetMouseDY() const;

	void EnableCursor();

	void DisableCursor();

	bool IsCursorEnabled() const;

	bool IsJoyStickConnected(int i) const;

	Platform::JoyStick GetJoyStick(int i) const;

	const std::vector<std::string>& GetJoystickNames() const;

	void GetDropPaths(std::vector<std::string>& dropPaths_) const;

	bool hasDropPath() const;

	const char* GetClipBoardString() const;

	void SetClipBoard(const char* s);

	void QuitApp();

	bool ShouldAppQuit() const;

	static Graphics& GetInstance()
	{
		static Graphics instance;

		return instance;
	}
private:
	Impl *impl;
};

#endif