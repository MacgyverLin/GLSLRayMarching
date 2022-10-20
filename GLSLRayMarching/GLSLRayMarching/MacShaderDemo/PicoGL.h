#ifndef _PICOGL_h_ 
#define _PICOGL_h_ 

#include "Platform.h"
#include "Vector2.h"
#include "Vector3.h"
#include "Vector4.h"
#include "Matrix.h"
#include "Matrix4.h"

namespace PicoGL
{
	enum class Constant
	{
		TRUE = -1,
		FALSE = 0,
		STENCIL_BUFFER_BIT = 1,
		COLOR_BUFFER_BIT,
		POINTS,
		LINES,
		LINE_LOOP,
		LINE_STRIP,
		TRIANGLES,
		TRIANGLE_STRIP,
		TRIANGLE_FAN,
		ZERO,
		ONE,
		SRC_COLOR,
		ONE_MINUS_SRC_COLOR,
		SRC_ALPHA,
		ONE_MINUS_SRC_ALPHA,
		DST_ALPHA,
		ONE_MINUS_DST_ALPHA,
		DST_COLOR,
		ONE_MINUS_DST_COLOR,
		SRC_ALPHA_SATURATE,
		FUNC_ADD,
		BLEND_EQUATION,
		BLEND_EQUATION_RGB,
		BLEND_EQUATION_ALPHA,
		FUNC_SUBTRACT,
		FUNC_REVERSE_SUBTRACT,
		BLEND_DST_RGB,
		BLEND_SRC_RGB,
		BLEND_DST_ALPHA,
		BLEND_SRC_ALPHA,
		CONSTANT_COLOR,
		ONE_MINUS_CONSTANT_COLOR,
		CONSTANT_ALPHA,
		ONE_MINUS_CONSTANT_ALPHA,
		BLEND_COLOR,
		ARRAY_BUFFER,
		ELEMENT_ARRAY_BUFFER,
		ARRAY_BUFFER_BINDING,
		ELEMENT_ARRAY_BUFFER_BINDING,
		STREAM_DRAW,
		STATIC_DRAW,
		DYNAMIC_DRAW,
		BUFFER_SIZE,
		BUFFER_USAGE,
		CURRENT_VERTEX_ATTRIB,
		FRONT,
		BACK,
		FRONT_AND_BACK,
		CULL_FACE,
		BLEND,
		DITHER,
		STENCIL_TEST,
		DEPTH_TEST,
		SCISSOR_TEST,
		POLYGON_OFFSET_FILL,
		SAMPLE_ALPHA_TO_COVERAGE,
		SAMPLE_COVERAGE,
		NO_ERROR,
		INVALID_ENUM,
		INVALID_VALUE,
		INVALID_OPERATION,
		OUT_OF_MEMORY,
		CW,
		CCW,
		LINE_WIDTH,
		ALIASED_POINT_SIZE_RANGE,
		ALIASED_LINE_WIDTH_RANGE,
		CULL_FACE_MODE,
		FRONT_FACE,
		DEPTH_RANGE,
		DEPTH_WRITEMASK,
		DEPTH_CLEAR_VALUE,
		DEPTH_FUNC,
		STENCIL_CLEAR_VALUE,
		STENCIL_FUNC,
		STENCIL_FAIL,
		STENCIL_PASS_DEPTH_FAIL,
		STENCIL_PASS_DEPTH_PASS,
		STENCIL_REF,
		STENCIL_VALUE_MASK,
		STENCIL_WRITEMASK,
		STENCIL_BACK_FUNC,
		STENCIL_BACK_FAIL,
		STENCIL_BACK_PASS_DEPTH_FAIL,
		STENCIL_BACK_PASS_DEPTH_PASS,
		STENCIL_BACK_REF,
		STENCIL_BACK_VALUE_MASK,
		STENCIL_BACK_WRITEMASK,
		VIEWPORT,
		SCISSOR_BOX,
		COLOR_CLEAR_VALUE,
		COLOR_WRITEMASK,
		UNPACK_ALIGNMENT,
		PACK_ALIGNMENT,
		MAX_TEXTURE_SIZE,
		MAX_VIEWPORT_DIMS,
		SUBPIXEL_BITS,
		RED_BITS,
		GREEN_BITS,
		BLUE_BITS,
		ALPHA_BITS,
		DEPTH_BITS,
		STENCIL_BITS,
		POLYGON_OFFSET_UNITS,
		POLYGON_OFFSET_FACTOR,
		TEXTURE_BINDING_2D,
		SAMPLE_BUFFERS,
		SAMPLES,
		SAMPLE_COVERAGE_VALUE,
		SAMPLE_COVERAGE_INVERT,
		COMPRESSED_TEXTURE_FORMATS,
		DONT_CARE,
		FASTEST,
		NICEST,
		GENERATE_MIPMAP_HINT,
		BYTE,
		UNSIGNED_BYTE,
		SHORT,
		UNSIGNED_SHORT,
		INT,
		UNSIGNED_INT,
		FLOAT,
		DEPTH_COMPONENT,
		ALPHA,
		RGB,
		RGBA,
		LUMINANCE,
		LUMINANCE_ALPHA,
		UNSIGNED_SHORT_4_4_4_4,
		UNSIGNED_SHORT_5_5_5_1,
		UNSIGNED_SHORT_5_6_5,
		FRAGMENT_SHADER,
		VERTEX_SHADER,
		MAX_VERTEX_ATTRIBS,
		MAX_VERTEX_UNIFORM_VECTORS,
		MAX_VARYING_VECTORS,
		MAX_COMBINED_TEXTURE_IMAGE_UNITS,
		MAX_VERTEX_TEXTURE_IMAGE_UNITS,
		MAX_TEXTURE_IMAGE_UNITS,
		MAX_FRAGMENT_UNIFORM_VECTORS,
		SHADER_TYPE,
		DELETE_STATUS,
		LINK_STATUS,
		VALIDATE_STATUS,
		ATTACHED_SHADERS,
		ACTIVE_UNIFORMS,
		ACTIVE_ATTRIBUTES,
		SHADING_LANGUAGE_VERSION,
		CURRENT_PROGRAM,
		NEVER,
		LESS,
		EQUAL,
		LEQUAL,
		GREATER,
		NOTEQUAL,
		GEQUAL,
		ALWAYS,
		KEEP,
		REPLACE,
		INCR,
		DECR,
		INVERT,
		INCR_WRAP,
		DECR_WRAP,
		VENDOR,
		RENDERER,
		VERSION,
		NEAREST,
		LINEAR,
		NEAREST_MIPMAP_NEAREST,
		LINEAR_MIPMAP_NEAREST,
		NEAREST_MIPMAP_LINEAR,
		LINEAR_MIPMAP_LINEAR,
		TEXTURE_MAG_FILTER,
		TEXTURE_MIN_FILTER,
		TEXTURE_WRAP_S,
		TEXTURE_WRAP_T,
		TEXTURE_2D,
		TEXTURE,
		TEXTURE_CUBE_MAP,
		TEXTURE_BINDING_CUBE_MAP,
		TEXTURE_CUBE_MAP_POSITIVE_X,
		TEXTURE_CUBE_MAP_NEGATIVE_X,
		TEXTURE_CUBE_MAP_POSITIVE_Y,
		TEXTURE_CUBE_MAP_NEGATIVE_Y,
		TEXTURE_CUBE_MAP_POSITIVE_Z,
		TEXTURE_CUBE_MAP_NEGATIVE_Z,
		MAX_CUBE_MAP_TEXTURE_SIZE,
		TEXTURE0,
		TEXTURE1,
		TEXTURE2,
		TEXTURE3,
		TEXTURE4,
		TEXTURE5,
		TEXTURE6,
		TEXTURE7,
		TEXTURE8,
		TEXTURE9,
		TEXTURE10,
		TEXTURE11,
		TEXTURE12,
		TEXTURE13,
		TEXTURE14,
		TEXTURE15,
		TEXTURE16,
		TEXTURE17,
		TEXTURE18,
		TEXTURE19,
		TEXTURE20,
		TEXTURE21,
		TEXTURE22,
		TEXTURE23,
		TEXTURE24,
		TEXTURE25,
		TEXTURE26,
		TEXTURE27,
		TEXTURE28,
		TEXTURE29,
		TEXTURE30,
		TEXTURE31,
		ACTIVE_TEXTURE,
		REPEAT,
		CLAMP_TO_EDGE,
		MIRRORED_REPEAT,
		FLOAT_VEC2,
		FLOAT_VEC3,
		FLOAT_VEC4,
		INT_VEC2,
		INT_VEC3,
		INT_VEC4,
		BOOL,
		BOOL_VEC2,
		BOOL_VEC3,
		BOOL_VEC4,
		FLOAT_MAT2,
		FLOAT_MAT3,
		FLOAT_MAT4,
		SAMPLER_2D,
		SAMPLER_CUBE,
		VERTEX_ATTRIB_ARRAY_ENABLED,
		VERTEX_ATTRIB_ARRAY_SIZE,
		VERTEX_ATTRIB_ARRAY_STRIDE,
		VERTEX_ATTRIB_ARRAY_TYPE,
		VERTEX_ATTRIB_ARRAY_NORMALIZED,
		VERTEX_ATTRIB_ARRAY_POINTER,
		VERTEX_ATTRIB_ARRAY_BUFFER_BINDING,
		IMPLEMENTATION_COLOR_READ_TYPE,
		IMPLEMENTATION_COLOR_READ_FORMAT,
		COMPILE_STATUS,
		LOW_FLOAT,
		MEDIUM_FLOAT,
		HIGH_FLOAT,
		LOW_INT,
		MEDIUM_INT,
		HIGH_INT,
		FRAMEBUFFER,
		RENDERBUFFER,
		RGBA4,
		RGB5_A1,
		RGB565,
		DEPTH_COMPONENT16,
		STENCIL_INDEX,
		STENCIL_INDEX8,
		DEPTH_STENCIL,
		RENDERBUFFER_WIDTH,
		RENDERBUFFER_HEIGHT,
		RENDERBUFFER_INTERNAL_FORMAT,
		RENDERBUFFER_RED_SIZE,
		RENDERBUFFER_GREEN_SIZE,
		RENDERBUFFER_BLUE_SIZE,
		RENDERBUFFER_ALPHA_SIZE,
		RENDERBUFFER_DEPTH_SIZE,
		RENDERBUFFER_STENCIL_SIZE,
		FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE,
		FRAMEBUFFER_ATTACHMENT_OBJECT_NAME,
		FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL,
		FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE,
		COLOR_ATTACHMENT0,
		DEPTH_ATTACHMENT,
		STENCIL_ATTACHMENT,
		DEPTH_STENCIL_ATTACHMENT,
		NONE,
		FRAMEBUFFER_COMPLETE,
		FRAMEBUFFER_INCOMPLETE_ATTACHMENT,
		FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT,
		// FRAMEBUFFER_INCOMPLETE_DIMENSIONS,
		FRAMEBUFFER_UNSUPPORTED,
		FRAMEBUFFER_BINDING,
		RENDERBUFFER_BINDING,
		MAX_RENDERBUFFER_SIZE,
		INVALID_FRAMEBUFFER_OPERATION,
		// UNPACK_FLIP_Y_WEBGL,
		// UNPACK_PREMULTIPLY_ALPHA_WEBGL,
		// CONTEXT_LOST_WEBGL,
		// UNPACK_COLORSPACE_CONVERSION_WEBGL,
		// BROWSER_DEFAULT_WEBGL,
		READ_BUFFER,
		UNPACK_ROW_LENGTH,
		UNPACK_SKIP_ROWS,
		UNPACK_SKIP_PIXELS,
		PACK_ROW_LENGTH,
		PACK_SKIP_ROWS,
		PACK_SKIP_PIXELS,
		COLOR,
		DEPTH,
		STENCIL,
		RED,
		RGB8,
		RGBA8,
		RGB10_A2,
		TEXTURE_BINDING_3D,
		UNPACK_SKIP_IMAGES,
		UNPACK_IMAGE_HEIGHT,
		TEXTURE_3D,
		TEXTURE_WRAP_R,
		MAX_3D_TEXTURE_SIZE,
		UNSIGNED_INT_2_10_10_10_REV,
		MAX_ELEMENTS_VERTICES,
		MAX_ELEMENTS_INDICES,
		TEXTURE_MIN_LOD,
		TEXTURE_MAX_LOD,
		TEXTURE_BASE_LEVEL,
		TEXTURE_MAX_LEVEL,
		MIN,
		MAX,
		DEPTH_COMPONENT24,
		MAX_TEXTURE_LOD_BIAS,
		TEXTURE_COMPARE_MODE,
		TEXTURE_COMPARE_FUNC,
		CURRENT_QUERY,
		QUERY_RESULT,
		QUERY_RESULT_AVAILABLE,
		STREAM_READ,
		STREAM_COPY,
		STATIC_READ,
		STATIC_COPY,
		DYNAMIC_READ,
		DYNAMIC_COPY,
		MAX_DRAW_BUFFERS,
		DRAW_BUFFER0,
		DRAW_BUFFER1,
		DRAW_BUFFER2,
		DRAW_BUFFER3,
		DRAW_BUFFER4,
		DRAW_BUFFER5,
		DRAW_BUFFER6,
		DRAW_BUFFER7,
		DRAW_BUFFER8,
		DRAW_BUFFER9,
		DRAW_BUFFER10,
		DRAW_BUFFER11,
		DRAW_BUFFER12,
		DRAW_BUFFER13,
		DRAW_BUFFER14,
		DRAW_BUFFER15,
		MAX_FRAGMENT_UNIFORM_COMPONENTS,
		MAX_VERTEX_UNIFORM_COMPONENTS,
		SAMPLER_3D,
		SAMPLER_2D_SHADOW,
		FRAGMENT_SHADER_DERIVATIVE_HINT,
		PIXEL_PACK_BUFFER,
		PIXEL_UNPACK_BUFFER,
		PIXEL_PACK_BUFFER_BINDING,
		PIXEL_UNPACK_BUFFER_BINDING,
		FLOAT_MAT2x3,
		FLOAT_MAT2x4,
		FLOAT_MAT3x2,
		FLOAT_MAT3x4,
		FLOAT_MAT4x2,
		FLOAT_MAT4x3,
		SRGB,
		SRGB8,
		SRGB8_ALPHA8,
		COMPARE_REF_TO_TEXTURE,
		RGBA32F,
		RGB32F,
		RGBA16F,
		RGB16F,
		VERTEX_ATTRIB_ARRAY_INTEGER,
		MAX_ARRAY_TEXTURE_LAYERS,
		MIN_PROGRAM_TEXEL_OFFSET,
		MAX_PROGRAM_TEXEL_OFFSET,
		MAX_VARYING_COMPONENTS,
		TEXTURE_2D_ARRAY,
		TEXTURE_BINDING_2D_ARRAY,
		R11F_G11F_B10F,
		UNSIGNED_INT_10F_11F_11F_REV,
		RGB9_E5,
		UNSIGNED_INT_5_9_9_9_REV,
		TRANSFORM_FEEDBACK_BUFFER_MODE,
		MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS,
		TRANSFORM_FEEDBACK_VARYINGS,
		TRANSFORM_FEEDBACK_BUFFER_START,
		TRANSFORM_FEEDBACK_BUFFER_SIZE,
		TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN,
		RASTERIZER_DISCARD,
		MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS,
		MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS,
		INTERLEAVED_ATTRIBS,
		SEPARATE_ATTRIBS,
		TRANSFORM_FEEDBACK_BUFFER,
		TRANSFORM_FEEDBACK_BUFFER_BINDING,
		RGBA32UI,
		RGB32UI,
		RGBA16UI,
		RGB16UI,
		RGBA8UI,
		RGB8UI,
		RGBA32I,
		RGB32I,
		RGBA16I,
		RGB16I,
		RGBA8I,
		RGB8I,
		RED_INTEGER,
		RGB_INTEGER,
		RGBA_INTEGER,
		SAMPLER_2D_ARRAY,
		SAMPLER_2D_ARRAY_SHADOW,
		SAMPLER_CUBE_SHADOW,
		UNSIGNED_INT_VEC2,
		UNSIGNED_INT_VEC3,
		UNSIGNED_INT_VEC4,
		INT_SAMPLER_2D,
		INT_SAMPLER_3D,
		INT_SAMPLER_CUBE,
		INT_SAMPLER_2D_ARRAY,
		UNSIGNED_INT_SAMPLER_2D,
		UNSIGNED_INT_SAMPLER_3D,
		UNSIGNED_INT_SAMPLER_CUBE,
		UNSIGNED_INT_SAMPLER_2D_ARRAY,
		DEPTH_COMPONENT32F,
		DEPTH32F_STENCIL8,
		FLOAT_32_UNSIGNED_INT_24_8_REV,
		FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING,
		FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE,
		FRAMEBUFFER_ATTACHMENT_RED_SIZE,
		FRAMEBUFFER_ATTACHMENT_GREEN_SIZE,
		FRAMEBUFFER_ATTACHMENT_BLUE_SIZE,
		FRAMEBUFFER_ATTACHMENT_ALPHA_SIZE,
		FRAMEBUFFER_ATTACHMENT_DEPTH_SIZE,
		FRAMEBUFFER_ATTACHMENT_STENCIL_SIZE,
		FRAMEBUFFER_DEFAULT,
		UNSIGNED_INT_24_8,
		DEPTH24_STENCIL8,
		UNSIGNED_NORMALIZED,
		DRAW_FRAMEBUFFER_BINDING,
		READ_FRAMEBUFFER,
		DRAW_FRAMEBUFFER,
		READ_FRAMEBUFFER_BINDING,
		RENDERBUFFER_SAMPLES,
		FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER,
		MAX_COLOR_ATTACHMENTS,
		COLOR_ATTACHMENT1,
		COLOR_ATTACHMENT2,
		COLOR_ATTACHMENT3,
		COLOR_ATTACHMENT4,
		COLOR_ATTACHMENT5,
		COLOR_ATTACHMENT6,
		COLOR_ATTACHMENT7,
		COLOR_ATTACHMENT8,
		COLOR_ATTACHMENT9,
		COLOR_ATTACHMENT10,
		COLOR_ATTACHMENT11,
		COLOR_ATTACHMENT12,
		COLOR_ATTACHMENT13,
		COLOR_ATTACHMENT14,
		COLOR_ATTACHMENT15,
		FRAMEBUFFER_INCOMPLETE_MULTISAMPLE,
		MAX_SAMPLES,
		HALF_FLOAT,
		RG,
		RG_INTEGER,
		R8,
		RG8,
		R16F,
		R32F,
		RG16F,
		RG32F,
		R8I,
		R8UI,
		R16I,
		R16UI,
		R32I,
		R32UI,
		RG8I,
		RG8UI,
		RG16I,
		RG16UI,
		RG32I,
		RG32UI,
		VERTEX_ARRAY_BINDING,
		R8_SNORM,
		RG8_SNORM,
		RGB8_SNORM,
		RGBA8_SNORM,
		SIGNED_NORMALIZED,
		COPY_READ_BUFFER,
		COPY_WRITE_BUFFER,
		COPY_READ_BUFFER_BINDING,
		COPY_WRITE_BUFFER_BINDING,
		UNIFORM_BUFFER,
		UNIFORM_BUFFER_BINDING,
		UNIFORM_BUFFER_START,
		UNIFORM_BUFFER_SIZE,
		MAX_VERTEX_UNIFORM_BLOCKS,
		MAX_FRAGMENT_UNIFORM_BLOCKS,
		MAX_COMBINED_UNIFORM_BLOCKS,
		MAX_UNIFORM_BUFFER_BINDINGS,
		MAX_UNIFORM_BLOCK_SIZE,
		MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS,
		MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS,
		UNIFORM_BUFFER_OFFSET_ALIGNMENT,
		ACTIVE_UNIFORM_BLOCKS,
		UNIFORM_TYPE,
		UNIFORM_SIZE,
		UNIFORM_BLOCK_INDEX,
		UNIFORM_OFFSET,
		UNIFORM_ARRAY_STRIDE,
		UNIFORM_MATRIX_STRIDE,
		UNIFORM_IS_ROW_MAJOR,
		UNIFORM_BLOCK_BINDING,
		UNIFORM_BLOCK_DATA_SIZE,
		UNIFORM_BLOCK_ACTIVE_UNIFORMS,
		UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES,
		UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER,
		UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER,
		INVALID_INDEX,
		MAX_VERTEX_OUTPUT_COMPONENTS,
		MAX_FRAGMENT_INPUT_COMPONENTS,
		MAX_SERVER_WAIT_TIMEOUT,
		OBJECT_TYPE,
		SYNC_CONDITION,
		SYNC_STATUS,
		SYNC_FLAGS,
		SYNC_FENCE,
		SYNC_GPU_COMMANDS_COMPLETE,
		UNSIGNALED,
		SIGNALED,
		ALREADY_SIGNALED,
		TIMEOUT_EXPIRED,
		CONDITION_SATISFIED,
		WAIT_FAILED,
		SYNC_FLUSH_COMMANDS_BIT,
		VERTEX_ATTRIB_ARRAY_DIVISOR,
		ANY_SAMPLES_PASSED,
		ANY_SAMPLES_PASSED_CONSERVATIVE,
		SAMPLER_BINDING,
		RGB10_A2UI,
		INT_2_10_10_10_REV,
		TRANSFORM_FEEDBACK,
		TRANSFORM_FEEDBACK_PAUSED,
		TRANSFORM_FEEDBACK_ACTIVE,
		TRANSFORM_FEEDBACK_BINDING,
		TEXTURE_IMMUTABLE_FORMAT,
		MAX_ELEMENT_INDEX,
		TEXTURE_IMMUTABLE_LEVELS,
		//TIMEOUT_IGNORED,
		// MAX_CLIENT_WAIT_TIMEOUT_WEBGL,

		// QUERY_COUNTER_BITS_EXT,
		TIME_ELAPSED_EXT,
		// TIMESTAMP_EXT,
		// GPU_DISJOINT_EXT,

		COMPRESSED_RGB_S3TC_DXT1_EXT,
		COMPRESSED_RGBA_S3TC_DXT1_EXT,
		COMPRESSED_RGBA_S3TC_DXT3_EXT,
		COMPRESSED_RGBA_S3TC_DXT5_EXT,

		COMPRESSED_SRGB_S3TC_DXT1_EXT,
		COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT,
		COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT,
		COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT,

		COMPRESSED_R11_EAC,
		COMPRESSED_SIGNED_R11_EAC,
		COMPRESSED_RG11_EAC,
		COMPRESSED_SIGNED_RG11_EAC,
		COMPRESSED_RGB8_ETC2,
		COMPRESSED_SRGB8_ETC2,
		COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2,
		COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2,
		COMPRESSED_RGBA8_ETC2_EAC,
		COMPRESSED_SRGB8_ALPHA8_ETC2_EAC,

		// COMPRESSED_RGB_PVRTC_4BPPV1_IMG,
		// COMPRESSED_RGB_PVRTC_2BPPV1_IMG,
		// COMPRESSED_RGBA_PVRTC_4BPPV1_IMG,
		// COMPRESSED_RGBA_PVRTC_2BPPV1_IMG,

		COMPRESSED_RGBA_ASTC_4x4_KHR,
		COMPRESSED_RGBA_ASTC_5x4_KHR,
		COMPRESSED_RGBA_ASTC_5x5_KHR,
		COMPRESSED_RGBA_ASTC_6x5_KHR,
		COMPRESSED_RGBA_ASTC_6x6_KHR,
		COMPRESSED_RGBA_ASTC_8x5_KHR,
		COMPRESSED_RGBA_ASTC_8x6_KHR,
		COMPRESSED_RGBA_ASTC_8x8_KHR,
		COMPRESSED_RGBA_ASTC_10x5_KHR,
		COMPRESSED_RGBA_ASTC_10x6_KHR,
		COMPRESSED_RGBA_ASTC_10x8_KHR,
		COMPRESSED_RGBA_ASTC_10x10_KHR,
		COMPRESSED_RGBA_ASTC_12x10_KHR,
		COMPRESSED_RGBA_ASTC_12x12_KHR,
		COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR,
		COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR,
		COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR,
		COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR,
		COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR,
		COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR,
		COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR,
		COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR,
		COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR,
		COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR,
		COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR,
		COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR,
		COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR,
		COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR,

		MAX_TEXTURE_UNITS,
		MAX_UNIFORM_BUFFERS,
		COMPRESSED_TYPES
	};

	typedef std::map<const char*, PicoGL::Constant> Options;

	static std::map<PicoGL::Constant, int> WEBGL_INFO =
	{
		{ PicoGL::Constant::MAX_TEXTURE_UNITS		, -1},
		{ PicoGL::Constant::MAX_UNIFORM_BUFFERS	, -1}
	};

	static Options DUMMY_OBJECT =
	{
	};

	class Shader;
	class Query;
	class App;
	class Cubemap;
	class DrawCall;
	class Framebuffer;
	class Program;
	class Texture;
	class Timer;
	class TransformFeedback;
	class UniformBuffer;
	class VertexArray;
	class VertexBuffer;
	class State;

	/**
		Shader.

		@class
		@prop {WebGLShader} shader The shader.
	*/
	class Shader
	{
	public:
		Shader(PicoGL::Constant type, const char* source, int sourceLength);

		/**
			Delete this shader.

			@method
			@return {Shader} The Shader object.
		*/
		~Shader();
	private:
		unsigned int shader;
	};

	/**
		Generic query object.

		@class
		@prop {WebGLRenderingContext} gl The WebGL context.
		@prop {WebGLQuery} query Query object.
		@prop {GLEnum} target The type of information being queried.
		@prop {boolean} active Whether or not a query is currently in progress.
		@prop {Any} result The result of the query (only available after a call to ready() returns true).
	*/
	class Query
	{
	private:
		PicoGL::Constant target;
		unsigned int query;
		bool active;
		int result;
	public:
		Query(PicoGL::Constant target);

		/**
			Begin a query.

			@method
			@return {Query} The Query object.
		*/
		Query* Begin();
		/**
			End a query.

			@method
			@return {Query} The Query object.
		*/
		Query* End();

		/**
			Check if query result is available.

			@method
			@return {boolean} If results are available.
		*/
		bool Ready();

		/**
			Delete this query.

			@method
			@return {Query} The Query object.
		*/
		~Query();
	};


	/**
		Cubemap for environment mapping.

		@class
		@prop {WebGLRenderingContext} gl The WebGL context.
		@prop {WebGLTexture} texture Handle to the texture.
		@prop {GLEnum} type Type of data stored in the texture.
		@prop {GLEnum} format Layout of texture data.
		@prop {GLEnum} internalFormat Internal arrangement of the texture data.
		@prop {Number} currentUnit The current texture unit this cubemap is bound to.
		@prop {Object} appState Tracked GL state.
	*/
	class Cubemap
	{
	public:
		Cubemap(State* state, const Options& options);
		~Cubemap();

		/**
			Bind this cubemap to a texture unit.

			@method
			@ignore
			@return {Cubemap} The Cubemap object.
		*/
		Cubemap* Bind(int unit);
	private:
		State* state;
	};

	/**
		A DrawCall represents the program and values of associated
		attributes, uniforms and textures for a single draw call.

		@class
		@prop {WebGLRenderingContext} gl The WebGL context.
		@prop {Program} currentProgram The program to use for this draw call.
		@prop {VertexArray} currentVertexArray Vertex array to use for this draw call.
		@prop {TransformFeedback} currentTransformFeedback Transform feedback to use for this draw call.
		@prop {Array} uniformBuffers Ordered list of active uniform buffers.
		@prop {Array} uniformBlockNames Ordered list of uniform block names.
		@prop {Object} uniformBlockBases Map of uniform blocks to uniform buffer bases.
		@prop {Number} uniformBlockCount Number of active uniform blocks for this draw call.
		@prop {Object} uniformIndices Map of uniform names to indices in the uniform arrays.
		@prop {Array} uniformNames Ordered list of uniform names.
		@prop {Array} uniformValue Ordered list of uniform values.
		@prop {number} uniformCount The number of active uniforms for this draw call.
		@prop {Array} textures Array of active textures.
		@prop {number} textureCount The number of active textures for this draw call.
		@prop {GLEnum} primitive The primitive type being drawn.
		@prop {Object} appState Tracked GL state.
		@prop {GLsizei} numElements The number of element to draw.
		@prop {GLsizei} numInstances The number of instances to draw.
	*/
	class DrawCall
	{
	public:
		DrawCall(State* state, Program* program, VertexArray* vertexArray, PicoGL::Constant primitive = PicoGL::Constant::TRIANGLES);

		/**
			Set the current TransformFeedback object for draw

			@method
			@param {TransformFeedback} transformFeedback Transform Feedback to set.
			@return {DrawCall} The DrawCall object.
		*/
		DrawCall* TransformFeedback(TransformFeedback* transformFeedback);

		/**
			Set the value for a uniform. Array uniforms are supported by
			using appending "[0]" to the array name and passing a flat array
			with all required values.

			@method
			@param {string} name Uniform name.
			@param {any} value Uniform value.
			@return {DrawCall} The DrawCall object.
		*/
		template<class T>
		DrawCall* Uniform(const char* name, const T& value) {
			return this;
			/*
			let index = this.uniformIndices[name];
			if (index == = undefined) {
				index = this.uniformCount++;
				this.uniformIndices[name] = index;
				this.uniformNames[index] = name;
			}
			this.uniformValues[index] = value;

			return this;
			*/
		}

		/**
		Set texture to bind to a sampler uniform.

		@method
		@param {string} name Sampler uniform name.
		@param {Texture} texture Texture to bind.
		@return {DrawCall} The DrawCall object.
		*/
		DrawCall* Texture(const char* name, Texture* texture);

		/**
			Set uniform buffer to bind to a uniform block.

			@method
			@param {string} name Uniform block name.
			@param {UniformBuffer} buffer Uniform buffer to bind.
			@return {DrawCall} The DrawCall object.
		*/
		DrawCall* UniformBlock(const char* name, UniformBuffer* buffer);

		/**
			 Set numElements property to allow number of elements to be drawn

			 @method
			 @param {GLsizei} [count=0] Number of element to draw, 0 set to all.
			 @return {DrawCall} The DrawCall object.
		 */
		DrawCall* ElementCount(int count = 0);

		/**
			Set numInstances property to allow number of instances be drawn

			@method
			@param {GLsizei} [count=0] Number of instance to draw, 0 set to all.
			@return {DrawCall} The DrawCall object.
		*/
		DrawCall* InstanceCount(int count = 0);

		/**
			Draw based on current state.

			@method
			@return {DrawCall} The DrawCall object.
		*/
		DrawCall* Draw();

		~DrawCall();
	private:
		State* state;
	};

	/**
		Storage for vertex data.

		@class
		@prop {WebGLRenderingContext} gl The WebGL context.
		@prop {WebGLFramebuffer} framebuffer Handle to the framebuffer.
		@prop {Array} colorTextures Array of color texture targets.
		@prop {number} numColorTargets Number of color texture targets.
		@prop {Texture} depthTexture Depth texture target.
		@prop {Array} colorAttachments Array of color attachment enums.
		@prop {Object} appState Tracked GL state.
	*/
	class Framebuffer
	{
	public:
		Framebuffer(State* state);

		/**
			 Attach a color target to this framebuffer.

			 @method
			 @param {number} index Color attachment index.
			 @param {Texture} texture The texture to attach.
			 @param {GLEnum} [target] The texture target or layer to attach. If the texture is 3D or a texture array,
				 defaults to 0, otherwise to TEXTURE_2D.
			 @return {Framebuffer} The Framebuffer object.
		 */
		Framebuffer* ColorTarget(int index, PicoGL::Texture* texture);

		/**
			Attach a depth target to this framebuffer.

			@method
			@param {Texture} texture The texture to attach.
			@param {GLEnum} [target] The texture target or layer to attach. If the texture is 3D or a texture array,
				defaults to 0, otherwise to TEXTURE_2D.
			@return {Framebuffer} The Framebuffer object.
		*/
		Framebuffer* DepthTarget(Texture* texture);

		/**
			Resize all currently attached textures.

			@method
			@param {number} [width=app.width] New width of the framebuffer.
			@param {number} [height=app.height] New height of the framebuffer.
			@return {Framebuffer} The Framebuffer object.
		*/
		Framebuffer* Resize(int width = -1, int height = -1, int depth = -1);

		/**
			Delete this framebuffer.

			@method
			@return {Framebuffer} The Framebuffer object.
		*/
		~Framebuffer();

		/**
			Bind as the draw framebuffer

			@method
			@ignore
			@return {Framebuffer} The Framebuffer object.
		*/
		Framebuffer* BindForDraw();

		/**
			Bind as the read framebuffer

			@method
			@ignore
			@return {Framebuffer} The Framebuffer object.
		*/
		Framebuffer* BindForRead();

		/**
			Bind for a framebuffer state update.
			Capture current binding so we can restore it later.

			@method
			@ignore
			@return {Framebuffer} The Framebuffer object.
		*/
		Framebuffer* BindAndCaptureState();

		/**
			Bind restore previous binding after state update

			@method
			@ignore
			@return {Framebuffer} The Framebuffer object.
		*/
		Framebuffer* RestoreState(Framebuffer* framebuffer);

		int GetNumColorTargets() const
		{
			return numColorTargets;
		}

		const std::vector < Texture*>& GetColorTextures()
		{
			return colorTextures;
		}

		const std::vector < Texture*>& GetColorAttachments()
		{
			return  colorAttachments;
		}

		const std::vector<Texture*>& GetColorTextureTargets()
		{
			return colorTextureTargets;
		}

		Texture* DepthTexture()
		{
			return depthTexture;
		}

		Texture* DepthTextureTarget()
		{
			return depthTextureTarget;
		}
	private:
		State* state;
		unsigned int framebuffer;

		int numColorTargets;

		std::vector < Texture*> colorTextures;
		std::vector < Texture*> colorAttachments;
		std::vector<Texture*> colorTextureTargets;
		Texture* depthTexture;
		Texture* depthTextureTarget;
	};

	/**
		WebGL program consisting of compiled and linked vertex and fragment
		shaders.

		@class
		@prop {WebGLRenderingContext} gl The WebGL context.
		@prop {WebGLProgram} program The WebGL program.
		@prop {boolean} transformFeedback Whether this program is set up for transform feedback.
		@prop {Object} uniforms Map of uniform names to handles.
		@prop {Object} appState Tracked GL state.
	*/

	class Program
	{
	public:
		Program(State* state,
			const char* vsSource, int vsSourceLength,
			const char* fsSource, int fsSourceLength,
			const std::vector<const char*>& xformFeedbackVars = {});

		Program(State* state, Shader* vShader, Shader* fShader, const std::vector<const char*>& xformFeedbackVars = {});
	private:
		void CreateProgramInternal(State* state, Shader* vShader, Shader* fShader, bool ownVertexShader, bool ownFragmentShader, const std::vector<const char*>& xformFeedbackVars);
	public:
		/**
			Delete this program.

			@method
			@return {Program} The Program object.
		*/
		~Program();

		/**
			Set the value of a uniform.

			@method
			@ignore
			@return {Program} The Program object.
		*/
		template<class T>
		Program* Uniform(const char* name, const T& value) {
			return this;
			/*
			this.uniforms[name].set(value);

			return this;
			*/
		}

		// 
		/**
			Use this program.

			@method
			@ignore
			@return {Program} The Program object.
		*/
		Program* Bind();
	private:
		State* state;
	};

	/**
		General-purpose texture.

		@class
		@prop {WebGLRenderingContext} gl The WebGL context.
		@prop {WebGLTexture} texture Handle to the texture.
		@prop {WebGLSamler} sampler Sampler object.
		@prop {GLEnum} binding Binding point for the texture.
		@prop {GLEnum} type Type of data stored in the texture.
		@prop {GLEnum} format Layout of texture data.
		@prop {GLEnum} internalFormat Internal arrangement of the texture data.
		@prop {number} currentUnit The current texture unit this texture is bound to.
		@prop {boolean} is3D Whether this texture contains 3D data.
		@prop {boolean} flipY Whether the y-axis is being flipped for this texture.
		@prop {boolean} mipmaps Whether this texture is using mipmap filtering
			(and thus should have a complete mipmap chain).
		@prop {Object} appState Tracked GL state.
	*/
	class Texture
	{
	public:
		Texture(State* state, PicoGL::Constant target, const void* image, int width, int height, int depth, bool is3D, const Options& options);
		/**
			Re-allocate texture storage.

			@method
			@param {number} width Image width.
			@param {number} height Image height.
			@param {number} [depth] Image depth or number of images. Required when passing 3D or texture array data.
			@return {Texture} The Texture object.
		*/
		Texture* Resize(int width, int height, int depth);

		/**
			Set the image data for the texture. An array can be passed to manually set all levels
			of the mipmap chain. If a single level is passed and mipmap filtering is being used,
			generateMipmap() will be called to produce the remaining levels.
			NOTE: the data must fit the currently-allocated storage!

			@method
			@param {ImageElement|ArrayBufferView|Array} data Image data. If an array is passed, it will be
				used to set mip map levels.
			@return {Texture} The Texture object.
		*/
		Texture* Data(void* data, unsigned int dataLength);

		/**
			Delete this texture.

			@method
			@return {Texture} The Texture object.
		*/
		~Texture();

		/**
			Bind this texture to a texture unit.

			@method
			@ignore
			@return {Texture} The Texture object.
		*/
		Texture* Bind(int unit);
	private:
		State* state;
	};

	/**
		Rendering timer.

		@class
		@prop {WebGLRenderingContext} gl The WebGL context.
		@prop {Object} cpuTimer Timer for CPU. Will be window.performance, if available, or window.Date.
		@prop {boolean} gpuTimer Whether the gpu timing is available (EXT_disjoint_timer_query_webgl2 or
				EXT_disjoint_timer_query are supported).
		@prop {WebGLQuery} gpuTimerQuery Timer query object for GPU (if gpu timing is supported).
		@prop {boolean} gpuTimerQueryInProgress Whether a gpu timer query is currently in progress.
		@prop {number} cpuStartTime When the last CPU timing started.
		@prop {number} cpuTime Time spent on CPU during last timing. Only valid if ready() returns true.
		@prop {number} gpuTime Time spent on GPU during last timing. Only valid if ready() returns true.
				Will remain 0 if extension EXT_disjoint_timer_query_webgl2 is unavailable.
	*/
	class Timer
	{
	public:
		Timer();

		~Timer();
	};

	/**
		Tranform feedback object.

		@class
		@prop {WebGLRenderingContext} gl The WebGL context.
		@prop {WebGLTransformFeedback} transformFeedback Transform feedback object.
		@prop {Object} appState Tracked GL state.
	*/
	class TransformFeedback
	{
	public:
		TransformFeedback(State* state);

		/**
			Bind a feedback buffer to capture transform output.

			@method
			@param {number} index Index of transform feedback varying to capture.
			@param {VertexBuffer} buffer Buffer to record output into.
			@return {TransformFeedback} The TransformFeedback object.
		*/
		TransformFeedback* FeedbackBuffer(int index, VertexBuffer* buffer);

		/**
			Delete this transform feedback.

			@method
			@return {TransformFeedback} The TransformFeedback object.
		*/
		~TransformFeedback();

		/**
			Bind this transform feedback.

			@method
			@ignore
			@return {TransformFeedback} The TransformFeedback object.
		*/
		TransformFeedback* Bind();
	private:
		State* state;
	};


	/**
		Storage for uniform data. Data is stored in std140 layout.

		@class
		@prop {WebGLRenderingContext} gl The WebGL context.
		@prop {WebGLBuffer} buffer Allocated buffer storage.
		@prop {Float32Array} data Buffer data.
		@prop {Object} dataViews Map of base data types to matching ArrayBufferViews of the buffer data.
		@prop {Array} offsets Offsets into the array for each item in the buffer.
		@prop {Array} sizes Size of the item at the given offset.
		@prop {Array} types The base type of the item at the given offset (FLOAT, INT or UNSIGNED_INT).
		@prop {number} size The size of the buffer (in 4-byte items).
		@prop {GLEnum} usage Usage pattern of the buffer.
	*/

	class UniformBuffer
	{
	public:
		UniformBuffer(State* state, const std::vector<PicoGL::Constant>& layout, PicoGL::Constant usage);

		/**
			Update data for a given item in the buffer. NOTE: Data is not
			sent the the GPU until the update() method is called!

			@method
			@param {number} index Index in the layout of item to set.
			@param {ArrayBufferView} value Value to store at the layout location.
			@return {UniformBuffer} The UniformBuffer object.
		*/
		template<class T>
		UniformBuffer* Set(int index, const T& value) {
			return this;
			/*
			let view = this.dataViews[this.types[index]];

			if (this.sizes[index] == = 1) {
				view[this.offsets[index]] = value;
			}
			else {
				view.set(value, this.offsets[index]);
			}

			return this;
			*/
		}

		/**
			Send stored buffer data to the GPU.

			@method
			@param {number} [index] Index in the layout of item to send to the GPU. If ommited, entire buffer is sent.
			@return {UniformBuffer} The UniformBuffer object.
		*/
		UniformBuffer* Update(int index = -1);

		/**
			Delete this uniform buffer.

			@method
			@return {UniformBuffer} The UniformBuffer object.
		*/
		~UniformBuffer();

		/**
			Bind this uniform buffer to the given base.

			@method
			@ignore
			@return {UniformBuffer} The UniformBuffer object.
		*/
		UniformBuffer* Bind(int base);
	private:
		State* state;
	};

	/**
		Organizes vertex buffer and attribute state.

		@class
		@prop {WebGLRenderingContext} gl The WebGL context.
		@prop {WebGLVertexArrayObject} vertexArray Vertex array object.
		@prop {number} numElements Number of elements in the vertex array.
		@prop {boolean} indexed Whether this vertex array is set up for indexed drawing.
		@prop {GLenum} indexType Data type of the indices.
		@prop {boolean} instanced Whether this vertex array is set up for instanced drawing.
		@prop {number} numInstances Number of instances to draw with this vertex array.
		@prop {Object} appState Tracked GL state.
	*/
	class VertexArray
	{
	public:
		VertexArray(State* state);

		/**
			Bind an per-vertex attribute buffer to this vertex array.

			@method
			@param {number} attributeIndex The attribute location to bind to.
			@param {VertexBuffer} vertexBuffer The VertexBuffer to bind.
			@return {VertexArray} The VertexArray object.
		*/
		VertexArray* VertexAttributeBuffer(int attributeIndex, VertexBuffer* vertexBuffer);

		/**
			Bind an per-instance attribute buffer to this vertex array.

			@method
			@param {number} attributeIndex The attribute location to bind to.
			@param {VertexBuffer} vertexBuffer The VertexBuffer to bind.
			@return {VertexArray} The VertexArray object.
		*/
		VertexArray* InstanceAttributeBuffer(int attributeIndex, VertexBuffer* vertexBuffer);

		/**
			Bind an per-vertex integer attribute buffer to this vertex array.
			Note that this refers to the attribute in the shader being an integer,
			not the data stored in the vertex buffer.

			@method
			@param {number} attributeIndex The attribute location to bind to.
			@param {VertexBuffer} vertexBuffer The VertexBuffer to bind.
			@return {VertexArray} The VertexArray object.
		*/
		VertexArray* VertexIntegerAttributeBuffer(int attributeIndex, VertexBuffer* vertexBuffer);

		/**
			Bind an per-instance integer attribute buffer to this vertex array.
			Note that this refers to the attribute in the shader being an integer,
			not the data stored in the vertex buffer.

			@method
			@param {number} attributeIndex The attribute location to bind to.
			@param {VertexBuffer} vertexBuffer The VertexBuffer to bind.
			@return {VertexArray} The VertexArray object.
		*/
		VertexArray* InstanceIntegerAttributeBuffer(int attributeIndex, VertexBuffer* vertexBuffer);

		/**
			Bind an per-vertex normalized attribute buffer to this vertex array.
			Integer data in the vertex buffer will be normalized to [-1.0, 1.0] if
			signed, [0.0, 1.0] if unsigned.

			@method
			@param {number} attributeIndex The attribute location to bind to.
			@param {VertexBuffer} vertexBuffer The VertexBuffer to bind.
			@return {VertexArray} The VertexArray object.
		*/
		VertexArray* VertexNormalizedAttributeBuffer(int attributeIndex, VertexBuffer* vertexBuffer);

		/**
			Bind an per-instance normalized attribute buffer to this vertex array.
			Integer data in the vertex buffer will be normalized to [-1.0, 1.0] if
			signed, [0.0, 1.0] if unsigned.

			@method
			@param {number} attributeIndex The attribute location to bind to.
			@param {VertexBuffer} vertexBuffer The VertexBuffer to bind.
			@return {VertexArray} The VertexArray object.
		*/
		VertexArray* InstanceNormalizedAttributeBuffer(int attributeIndex, VertexBuffer* vertexBuffer);

		/**
			Bind an index buffer to this vertex array.

			@method
			@param {VertexBuffer} vertexBuffer The VertexBuffer to bind.
			@return {VertexArray} The VertexArray object.
		*/
		VertexArray* IndexBuffer(VertexBuffer* vertexBuffer);

		/**
			Delete this vertex array.

			@method
			@return {VertexArray} The VertexArray object.
		*/
		~VertexArray();

		/**
			Bind this vertex array.

			@method
			@ignore
			@return {VertexArray} The VertexArray object.
		*/
		VertexArray* Bind();

		/**
			Attach an attribute buffer

			@method
			@ignore
			@return {VertexArray} The VertexArray object.
		*/
		VertexArray* AttributeBuffer(int attributeIndex, VertexBuffer* vertexBuffer, bool instanced, bool integer, bool normalized);
	private:
		State* state;
	};

	/**
		Storage for vertex data.

		@class
		@prop {WebGLRenderingContext} gl The WebGL context.
		@prop {WebGLBuffer} buffer Allocated buffer storage.
		@prop {GLEnum} type The type of data stored in the buffer.
		@prop {number} itemSize Number of array elements per vertex.
		@prop {number} numItems Number of vertices represented.
		@prop {GLEnum} usage The usage pattern of the buffer.
		@prop {boolean} indexArray Whether this is an index array.
		@prop {GLEnum} binding GL binding point (ARRAY_BUFFER or ELEMENT_ARRAY_BUFFER).
		@prop {Object} appState Tracked GL state.
	*/
	class VertexBuffer
	{
	public:
		VertexBuffer(State* state, PicoGL::Constant type, int itemSize, const void* data, unsigned int dataLength, PicoGL::Constant usage = PicoGL::Constant::STATIC_DRAW, bool indexType = false);

		/**
			Update data in this buffer. NOTE: the data must fit
			the originally-allocated buffer!

			@method
			@param {VertexBufferView} data Data to store in the buffer.
			@return {VertexBuffer} The VertexBuffer object.
		*/
		VertexBuffer* Data(void* data, unsigned int dataLength);

		/**
			Delete this array buffer.

			@method
			@return {VertexBuffer} The VertexBuffer object.
		*/
		~VertexBuffer();
	private:
		State* state;
	};

	//////////////////////////////////////////////////////////////////////
	/**
		Primary entry point to PicoGL. An app will store all parts of the WebGL
		state.

		@class
		@prop {DOMElement} canvas The canvas on which this app drawing.
		@prop {WebGLRenderingContext} gl The WebGL context.
		@prop {number} width The width of the drawing surface.
		@prop {number} height The height of the drawing surface.
		@prop {boolean} floatRenderTargetsEnabled Whether the EXT_color_buffer_float extension is enabled.
		@prop {boolean} linearFloatTexturesEnabled Whether the OES_texture_float_linear extension is enabled.
		@prop {boolean} s3tcTexturesEnabled Whether the WEBGL_compressed_texture_s3tc extension is enabled.
		@prop {boolean} s3tcSRGBTexturesEnabled Whether the WEBGL_compressed_texture_s3tc_srgb extension is enabled.
		@prop {boolean} etcTexturesEnabled Whether the WEBGL_compressed_texture_etc extension is enabled.
		@prop {boolean} astcTexturesEnabled Whether the WEBGL_compressed_texture_astc extension is enabled.
		@prop {boolean} pvrtcTexturesEnabled Whether the WEBGL_compressed_texture_pvrtc extension is enabled.
		@prop {Object} state Tracked GL state.
		@prop {GLEnum} clearBits Current clear mask to use with clear().
	*/
	class State
	{
	public:
		State
		(
			Program* program = nullptr,
			VertexArray* vertexArray = nullptr,
			TransformFeedback* transformFeedback = nullptr,
			int activeTexture = -1,
			std::vector<Texture*> textures = std::vector<Texture*>(),
			std::vector<UniformBuffer*> uniformBuffers = std::vector<UniformBuffer*>(),
			std::vector<int> freeUniformBufferBases = std::vector<int>(),
			Framebuffer* drawFramebuffer = nullptr,
			Framebuffer* readFramebuffer = nullptr
		);

		~State();

		Program* program;
		VertexArray* vertexArray;
		TransformFeedback* transformFeedback;
		int activeTexture;
		std::vector<Texture*> textures;
		std::vector<UniformBuffer*> uniformBuffers;
		std::vector<int> freeUniformBufferBases;
		Framebuffer* drawFramebuffer;
		Framebuffer* readFramebuffer;
	};

	class App
	{
	private:
		int width;
		int height;
		int viewportX;
		int viewportY;
		int viewportWidth;
		int viewportHeight;
		DrawCall* currentDrawCalls;
		Shader* emptyFragmentShader;

		State state;
		int clearBits;

		int cpuTime;
		int gpuTime;

		// Extensions
		bool floatRenderTargetsEnabled;
		bool linearFloatTexturesEnabled;
		bool s3tcTexturesEnabled;
		bool s3tcSRGBTexturesEnabled;
		bool etcTexturesEnabled;
		bool astcTexturesEnabled;
		bool pvrtcTexturesEnabled;

		IVector4 viewport;
	public:
		App(const Options& options);

		/**
			Set the color mask to selectively enable or disable particular
			color channels while rendering.

			@method
			@param {boolean} r Red channel.
			@param {boolean} g Green channel.
			@param {boolean} b Blue channel.
			@param {boolean} a Alpha channel.
			@return {App} The App object.
		*/
		App* ColorMask(bool r, bool g, bool b, bool a);

		/**
			Set the clear color.

			@method
			@param {number} r Red channel.
			@param {number} g Green channel.
			@param {number} b Blue channel.
			@param {number} a Alpha channel.
			@return {App} The App object.
		*/
		App* ClearColor(float r, float g, float b, float a);

		/**
			Set the clear mask bits to use when calling clear().
			E.g. app.clearMask(PicoGL.COLOR_BUFFER_BIT).

			@method
			@param {GLEnum} mask Bit mask of buffers to clear.
			@return {App} The App object.
		*/
		App* ClearMask(int mask);

		/**
			Clear the canvas

			@method
			@return {App} The App object.
		*/
		App* Clear();

		/**
			Bind a draw framebuffer to the WebGL context.

			@method
			@param {Framebuffer} framebuffer The Framebuffer object to bind.
			@see Framebuffer
			@return {App} The App object.
		*/
		App* DrawFramebuffer(Framebuffer* framebuffer);

		/**
			Bind a read framebuffer to the WebGL context.

			@method
			@param {Framebuffer} framebuffer The Framebuffer object to bind.
			@see Framebuffer
			@return {App} The App object.
		*/
		App* ReadFramebuffer(Framebuffer* framebuffer);

		/**
			Switch back to the default framebuffer for drawing (i.e. draw to the screen).
			Note that this method resets the viewport to match the default framebuffer.

			@method
			@return {App} The App object.
		*/
		App* DefaultDrawFramebuffer();

		/**
			Switch back to the default framebuffer for reading (i.e. read from the screen).

			@method
			@return {App} The App object.
		*/
		App* DefaultReadFramebuffer();

		/**
			Set the depth range.

			@method
			@param {number} near Minimum depth value.
			@param {number} far Maximum depth value.
			@return {App} The App object.
		*/
		App* DepthRange(float near, float far);

		/**
			Enable depth testing.

			@method
			@return {App} The App object.
		*/
		App* DepthTest();

		/**
			Disable depth testing.

			@method
			@return {App} The App object.
		*/
		App* NoDepthTest();

		/**
			Enable or disable writing to the depth buffer.

			@method
			@param {Boolean} mask The depth mask.
			@return {App} The App object.
		*/
		App* DepthMask(bool mask);
		/**
			Set the depth test function. E.g. app.depthFunc(PicoGL.LEQUAL).

			@method
			@param {GLEnum} func The depth testing function to use.
			@return {App} The App object.
		*/
		App* DepthFunc(PicoGL::Constant func);

		/**
			Enable blending.

			@method
			@return {App} The App object.
		*/
		App* Blend();

		/**
			Disable blending

			@method
			@return {App} The App object.
		*/
		App* NoBlend();

		/**
			Set the blend function. E.g. app.blendFunc(PicoGL.ONE, PicoGL.ONE_MINUS_SRC_ALPHA).

			@method
			@param {GLEnum} src The source blending weight.
			@param {GLEnum} dest The destination blending weight.
			@return {App} The App object.
		*/
		App* BlendFunc(PicoGL::Constant src, PicoGL::Constant dest);

		/**
			Set the blend function, with separate weighting for color and alpha channels.
			E.g. app.blendFuncSeparate(PicoGL.ONE, PicoGL.ONE_MINUS_SRC_ALPHA, PicoGL.ONE, PicoGL.ONE).

			@method
			@param {GLEnum} csrc The source blending weight for the RGB channels.
			@param {GLEnum} cdest The destination blending weight for the RGB channels.
			@param {GLEnum} asrc The source blending weight for the alpha channel.
			@param {GLEnum} adest The destination blending weight for the alpha channel.
			@return {App} The App object.
		*/
		App* BlendFuncSeparate(PicoGL::Constant csrc, PicoGL::Constant cdest, PicoGL::Constant asrc, PicoGL::Constant adest);

		/**
			Enable stencil testing.
			NOTE: Only works if { stencil: true } passed as a
			context attribute when creating the App!

			@method
			@return {App} The App object.
		*/
		App* StencilTest();

		/**
			Disable stencil testing.

			@method
			@return {App} The App object.
		*/
		App* NoStencilTest();


		/**
			Enable scissor testing.

			@method
			@return {App} The App object.
		*/
		App* scissorTest();

		/**
			Disable scissor testing.

			@method
			@return {App} The App object.
		*/
		App* NoScissorTest();

		/**
			Define the scissor box.

			@method
			@return {App} The App object.
		*/
		App* Scissor(int x, int y, int width, int height);

		/**
			Set the bitmask to use for tested stencil values.
			E.g. app.stencilMask(0xFF).
			NOTE: Only works if { stencil: true } passed as a
			context attribute when creating the App!

			@method
			@param {number} mask The mask value.
			@return {App} The App object.

		*/
		App* StencilMask(int mask);

		/**
			Set the bitmask to use for tested stencil values for a particular face orientation.
			E.g. app.stencilMaskSeparate(PicoGL.FRONT, 0xFF).
			NOTE: Only works if { stencil: true } passed as a
			context attribute when creating the App!

			@method
			@param {GLEnum} face The face orientation to apply the mask to.
			@param {number} mask The mask value.
			@return {App} The App object.
		*/
		App* StencilMaskSeparate(PicoGL::Constant face, int mask);

		/**
			Set the stencil function and reference value.
			E.g. app.stencilFunc(PicoGL.EQUAL, 1, 0xFF).
			NOTE: Only works if { stencil: true } passed as a
			context attribute when creating the App!

			@method
			@param {GLEnum} func The testing function.
			@param {number} ref The reference value.
			@param {number} mask The bitmask to use against tested values before applying
				the stencil function.
			@return {App} The App object.
		*/
		App* StencilFunc(PicoGL::Constant func, int ref, int mask);

		/**
			Set the stencil function and reference value for a particular face orientation.
			E.g. app.stencilFuncSeparate(PicoGL.FRONT, PicoGL.EQUAL, 1, 0xFF).
			NOTE: Only works if { stencil: true } passed as a
			context attribute when creating the App!

			@method
			@param {GLEnum} face The face orientation to apply the function to.
			@param {GLEnum} func The testing function.
			@param {number} ref The reference value.
			@param {number} mask The bitmask to use against tested values before applying
				the stencil function.
			@return {App} The App object.
		*/
		App* StencilFuncSeparate(PicoGL::Constant face, PicoGL::Constant func, int ref, int mask);

		/**
			Set the operations for updating stencil buffer values.
			E.g. app.stencilOp(PicoGL.KEEP, PicoGL.KEEP, PicoGL.REPLACE).
			NOTE: Only works if { stencil: true } passed as a
			context attribute when creating the App!

			@method
			@param {GLEnum} stencilFail Operation to apply if the stencil test fails.
			@param {GLEnum} depthFail Operation to apply if the depth test fails.
			@param {GLEnum} pass Operation to apply if the both the depth and stencil tests pass.
			@return {App} The App object.
		*/
		App* StencilOp(PicoGL::Constant stencilFail, PicoGL::Constant depthFail, PicoGL::Constant pass);

		/**
			Set the operations for updating stencil buffer values for a particular face orientation.
			E.g. app.stencilOpSeparate(PicoGL.FRONT, PicoGL.KEEP, PicoGL.KEEP, PicoGL.REPLACE).
			NOTE: Only works if { stencil: true } passed as a
			context attribute when creating the App!

			@method
			@param {GLEnum} face The face orientation to apply the operations to.
			@param {GLEnum} stencilFail Operation to apply if the stencil test fails.
			@param {GLEnum} depthFail Operation to apply if the depth test fails.
			@param {GLEnum} pass Operation to apply if the both the depth and stencil tests pass.
			@return {App} The App object.
		*/
		App* StencilOpSeparate(PicoGL::Constant face, PicoGL::Constant stencilFail, PicoGL::Constant depthFail, PicoGL::Constant pass);

		/**
			Enable rasterization step.

			@method
			@return {App} The App object.
		*/
		App* Rasterize();

		/**
			Disable rasterization step.

			@method
			@return {App} The App object.
		*/
		App* NoRasterize();

		/**
			Enable backface culling.

			@method
			@return {App} The App object.
		*/
		App* CullBackfaces();

		/**
			Disable backface culling.

			@method
			@return {App} The App object.
		*/
		App* NoCullBackfaces();

		/**
			Enable the EXT_color_buffer_float extension. Allows for creating float textures as
			render targets on FrameBuffer objects.

			@method
			@see Framebuffer
			@return {App} The App object.
		*/
		App* FloatRenderTargets();

		/**
			Enable the OES_texture_float_linear extension. Allows for linear blending on float textures.

			@method
			@see Framebuffer
			@return {App} The App object.
		*/
		App* LinearFloatTextures();


		/**
			Enable the WEBGL_compressed_texture_s3tc and WEBGL_compressed_texture_s3tc_srgb extensions, which
			allow the following enums to be used as texture formats:

			<ul>
			  <li>PicoGL.COMPRESSED_RGB_S3TC_DXT1_EXT
			  <li>PicoGL.COMPRESSED_RGBA_S3TC_DXT1_EXT
			  <li>PicoGL.COMPRESSED_RGBA_S3TC_DXT3_EXT
			  <li>PicoGL.COMPRESSED_RGBA_S3TC_DXT5_EXT
			  <li>PicoGL.COMPRESSED_SRGB_S3TC_DXT1_EXT
			  <li>PicoGL.COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT
			  <li>PicoGL.COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT
			  <li>PicoGL.COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT
			</ul>

			@method
			@return {App} The App object.
		*/
		App* S3TCTextures();
		/**
			Enable the WEBGL_compressed_texture_etc extension, which allows the following enums to
			be used as texture formats:

			<ul>
			  <li>PicoGL.COMPRESSED_R11_EAC
			  <li>PicoGL.COMPRESSED_SIGNED_R11_EAC
			  <li>PicoGL.COMPRESSED_RG11_EAC
			  <li>PicoGL.COMPRESSED_SIGNED_RG11_EAC
			  <li>PicoGL.COMPRESSED_RGB8_ETC2
			  <li>PicoGL.COMPRESSED_SRGB8_ETC2
			  <li>PicoGL.COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2
			  <li>PicoGL.COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2
			  <li>PicoGL.COMPRESSED_RGBA8_ETC2_EAC
			  <li>PicoGL.COMPRESSED_SRGB8_ALPHA8_ETC2_EAC
			</ul>

			Note that while WEBGL_compressed_texture_etc1 is not enabled by this method,
			ETC1 textures can be loaded using COMPRESSED_RGB8_ETC2 as the format.

			@method
			@return {App} The App object.
		*/
		App* ETCTextures();

		/**
			Enable the WEBGL_compressed_texture_astc extension, which allows the following enums to
			be used as texture formats:

			<ul>
			  <li>PicoGL.COMPRESSED_RGBA_ASTC_4x4_KHR
			  <li>PicoGL.COMPRESSED_RGBA_ASTC_5x4_KHR
			  <li>PicoGL.COMPRESSED_RGBA_ASTC_5x5_KHR
			  <li>PicoGL.COMPRESSED_RGBA_ASTC_6x5_KHR
			  <li>PicoGL.COMPRESSED_RGBA_ASTC_6x6_KHR
			  <li>PicoGL.COMPRESSED_RGBA_ASTC_8x5_KHR
			  <li>PicoGL.COMPRESSED_RGBA_ASTC_8x6_KHR
			  <li>PicoGL.COMPRESSED_RGBA_ASTC_8x8_KHR
			  <li>PicoGL.COMPRESSED_RGBA_ASTC_10x5_KHR
			  <li>PicoGL.COMPRESSED_RGBA_ASTC_10x6_KHR
			  <li>PicoGL.COMPRESSED_RGBA_ASTC_10x8_KHR
			  <li>PicoGL.COMPRESSED_RGBA_ASTC_10x10_KHR
			  <li>PicoGL.COMPRESSED_RGBA_ASTC_12x10_KHR
			  <li>PicoGL.COMPRESSED_RGBA_ASTC_12x12_KHR
			  <li>PicoGL.COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR
			  <li>PicoGL.COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR
			  <li>PicoGL.COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR
			  <li>PicoGL.COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR
			  <li>PicoGL.COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR
			  <li>PicoGL.COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR
			  <li>PicoGL.COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR
			  <li>PicoGL.COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR
			  <li>PicoGL.COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR
			  <li>PicoGL.COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR
			  <li>PicoGL.COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR
			  <li>PicoGL.COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR
			  <li>PicoGL.COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR
			  <li>PicoGL.COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR
			</ul>

			@method
			@return {App} The App object.
		*/
		App* ASTCTextures();

		/**
			Enable the WEBGL_compressed_texture_pvrtc extension, which allows the following enums to
			be used as texture formats:

			<ul>
			  <li>PicoGL.COMPRESSED_RGB_PVRTC_4BPPV1_IMG
			  <li>PicoGL.COMPRESSED_RGB_PVRTC_2BPPV1_IMG
			  <li>PicoGL.COMPRESSED_RGBA_PVRTC_4BPPV1_IMG
			  <li>PicoGL.COMPRESSED_RGBA_PVRTC_2BPPV1_IMG
			</ul>
			`
			@method
			@return {App} The App object.
		*/
		/*
		App* PVRTCTextures();
		*/

		/**
			Read a pixel's color value from the currently-bound framebuffer.

			@method
			@param {number} x The x coordinate of the pixel.
			@param {number} y The y coordinate of the pixel.
			@param {ArrayBufferView} outColor Typed array to store the pixel's color.
			@param {object} [options] Options.
			@param {GLEnum} [options.type=UNSIGNED_BYTE] Type of data stored in the read framebuffer.
			@param {GLEnum} [options.format=RGBA] Read framebuffer data format.
			@return {App} The App object.
		*/

		App* ReadPixel(int x, int y, void* outColor, const Options& options = DUMMY_OBJECT);

		/**
			Set the viewport.

			@method
			@param {number} x Left bound of the viewport rectangle.
			@param {number} y Lower bound of the viewport rectangle.
			@param {number} width Width of the viewport rectangle.
			@param {number} height Height of the viewport rectangle.
			@return {App} The App object.
		*/
		App* Viewport(int x, int y, int width, int height);

		/**
			Set the viewport to the full canvas.

			@method
			@return {App} The App object.
		*/
		App* DefaultViewport();

		/**
			Resize the drawing surface.

			@method
			@param {number} width The new canvas width.
			@param {number} height The new canvas height.
			@return {App} The App object.
		*/
		App* Resize(int width, int height);

		/**
			Create a program.

			@method
			@param {Shader|string} vertexShader Vertex shader object or source code.
			@param {Shader|string} fragmentShader Fragment shader object or source code.
			@param {Array} [xformFeedbackVars] Transform feedback varyings.
			@return {Program} New Program object.
		*/
		Program* CreateProgram
		(
			const char* vsSource, unsigned int vsSourceLength,
			const char* fsSource, unsigned int fsSourceLength,
			const std::vector<const char*>& xformFeedbackVars = {});

		Program* CreateProgram(Shader* vShader, Shader* fShader, const std::vector<const char*>& xformFeedbackVars = {});

		/**
			Create a shader. Creating a shader separately from a program allows for
			shader reuse.

			@method
			@param {GLEnum} type Shader type.
			@param {string} source Shader source.
			@return {Shader} New Shader object.
		*/
		Shader* CreateShader(PicoGL::Constant type, const char* source, int sourceLength);

		/**
			Create a vertex array.

			@method
			@return {VertexArray} New VertexArray object.
		*/
		VertexArray* CreateVertexArray();

		/**
			Create a transform feedback object.

			@method
			@return {TransformFeedback} New TransformFeedback object.
		*/
		TransformFeedback* CreateTransformFeedback();

		/**
			Create a vertex buffer.

			@method
			@param {GLEnum} type The data type stored in the vertex buffer.
			@param {number} itemSize Number of elements per vertex.
			@param {ArrayBufferView} data Buffer data.
			@param {GLEnum} [usage=STATIC_DRAW] Buffer usage.
			@return {VertexBuffer} New VertexBuffer object.
		*/
		VertexBuffer* CreateVertexBuffer(PicoGL::Constant type, int itemSize, const void* data, unsigned int dataLength, PicoGL::Constant usage = PicoGL::Constant::STATIC_DRAW);

		/**
			Create a per-vertex matrix buffer. Matrix buffers ensure that columns
			are correctly split across attribute locations.

			@method
			@param {GLEnum} type The data type stored in the matrix buffer. Valid types
			are FLOAT_MAT4, FLOAT_MAT4x2, FLOAT_MAT4x3, FLOAT_MAT3, FLOAT_MAT3x2,
			FLOAT_MAT3x4, FLOAT_MAT2, FLOAT_MAT2x3, FLOAT_MAT2x4.
			@param {ArrayBufferView} data Matrix buffer data.
			@param {GLEnum} [usage=STATIC_DRAW] Buffer usage.
			@return {VertexBuffer} New VertexBuffer object.
		*/
		VertexBuffer* CreateMatrixBuffer(PicoGL::Constant type, const void* data, unsigned int dataLength, PicoGL::Constant usage = PicoGL::Constant::STATIC_DRAW);

		/**
			Create an index buffer.

			@method
			@param {GLEnum} type The data type stored in the index buffer.
			@param {number} itemSize Number of elements per primitive.
			@param {ArrayBufferView} data Index buffer data.
			@param {GLEnum} [usage=STATIC_DRAW] Buffer usage.
			@return {VertexBuffer} New VertexBuffer object.
		*/
		VertexBuffer* CreateIndexBuffer(PicoGL::Constant type, int itemSize, const void* data, unsigned int dataLength, PicoGL::Constant usage = PicoGL::Constant::STATIC_DRAW);

		/**
			Create a uniform buffer in std140 layout. NOTE: FLOAT_MAT2, FLOAT_MAT3x2, FLOAT_MAT4x2,
			FLOAT_MAT3, FLOAT_MAT2x3, FLOAT_MAT4x3 are supported, but must be manually padded to
			4-float column alignment by the application!

			@method
			@param {Array} layout Array indicating the order and types of items to
							be stored in the buffer.
			@param {GLEnum} [usage=DYNAMIC_DRAW] Buffer usage.
			@return {UniformBuffer} New UniformBuffer object.
		*/
		UniformBuffer* CreateUniformBuffer(const std::vector<PicoGL::Constant>& layout, PicoGL::Constant usage = PicoGL::Constant::DYNAMIC_DRAW);

		/**
			Create a 2D texture. Can be used in several ways depending on the type of texture data:
			<ul>
				<li><b>app.createTexture2D(ImageElement, options)</b>: Create texture from a DOM image element.
				<li><b>app.createTexture2D(TypedArray, width, height, options)</b>: Create texture from a typed array.
				<li><b>app.createTexture2D(width, height, options)</b>: Create empty texture.
			</ul>

			@method
			@param {DOMElement|ArrayBufferView|Array} [image] Image data. An array can be passed to manually set all levels
				of the mipmap chain. If a single level is passed and mipmap filtering is being used,
				generateMipmap() will be called to produce the remaining levels.
			@param {number} [width] Texture width. Required for array or empty data.
			@param {number} [height] Texture height. Required for array or empty data.
			@param {Object} [options] Texture options.
			@param {GLEnum} [options.type] Type of data stored in the texture. Defaults to UNSIGNED_SHORT
				if format is DEPTH_COMPONENT, UNSIGNED_BYTE otherwise.
			@param {GLEnum} [options.format=RGBA] Texture data format.
			@param {GLEnum} [options.internalFormat=RGBA] Texture data internal format.
			@param {boolean} [options.flipY=false] Whether the y-axis should be flipped when unpacking the texture.
			@param {GLEnum} [options.minFilter] Minification filter. Defaults to
				LINEAR_MIPMAP_NEAREST if image data is provided, NEAREST otherwise.
			@param {GLEnum} [options.magFilter] Magnification filter. Defaults to LINEAR
				if image data is provided, NEAREST otherwise.
			@param {GLEnum} [options.wrapS=REPEAT] Horizontal wrap mode.
			@param {GLEnum} [options.wrapT=REPEAT] Vertical wrap mode.
			@param {GLEnum} [options.compareMode=NONE] Comparison mode.
			@param {GLEnum} [options.compareFunc=LEQUAL] Comparison function.
			@param {GLEnum} [options.baseLevel] Base mipmap level.
			@param {GLEnum} [options.maxLevel] Maximum mipmap level.
			@param {GLEnum} [options.minLOD] Mimimum level of detail.
			@param {GLEnum} [options.maxLOD] Maximum level of detail.
			@param {boolean} [options.generateMipmaps] Should mipmaps be generated. Defaults to generating mipmaps if
				a mipmap sampling filter is used and the mipmap levels aren't provided directly.
			@return {Texture} New Texture object.
		*/
		Texture* CreateTexture2D(const void* image, int width, int height, const Options& options);

		/**
			Create a 2D texture array.

			@method
			@param {ArrayBufferView|Array} image Pixel data. An array can be passed to manually set all levels
				of the mipmap chain. If a single level is passed and mipmap filtering is being used,
				generateMipmap() will be called to produce the remaining levels.
			@param {number} width Texture width.
			@param {number} height Texture height.
			@param {number} size Number of images in the array.
			@param {Object} [options] Texture options.
			 @param {GLEnum} [options.type] Type of data stored in the texture. Defaults to UNSIGNED_SHORT
				if format is DEPTH_COMPONENT, UNSIGNED_BYTE otherwise.
			@param {GLEnum} [options.format=RGBA] Texture data format.
			@param {GLEnum} [options.internalFormat=RGBA] Texture data internal format.
			@param {boolean} [options.flipY=false] Whether the y-axis should be flipped when unpacking the texture.
			@param {GLEnum} [options.minFilter] Minification filter. Defaults to
				LINEAR_MIPMAP_NEAREST if image data is provided, NEAREST otherwise.
			@param {GLEnum} [options.magFilter] Magnification filter. Defaults to LINEAR
				if image data is provided, NEAREST otherwise.
			@param {GLEnum} [options.wrapS=REPEAT] Horizontal wrap mode.
			@param {GLEnum} [options.wrapT=REPEAT] Vertical wrap mode.
			@param {GLEnum} [options.wrapR=REPEAT] Depth wrap mode.
			@param {GLEnum} [options.compareMode=NONE] Comparison mode.
			@param {GLEnum} [options.compareFunc=LEQUAL] Comparison function.
			@param {GLEnum} [options.baseLevel] Base mipmap level.
			@param {GLEnum} [options.maxLevel] Maximum mipmap level.
			@param {GLEnum} [options.minLOD] Mimimum level of detail.
			@param {GLEnum} [options.maxLOD] Maximum level of detail.
			@param {boolean} [options.generateMipmaps] Should mipmaps be generated. Defaults to generating mipmaps if
				a mipmap sampling filter is use and the mipmap levels aren't provided directly.
			@return {Texture} New Texture object.
		*/
		Texture* CreateTextureArray(const void* image, int width, int height, int depth, const Options& options);

		/**
			Create a 3D texture.

			@method
			@param {ArrayBufferView|Array} image Pixel data. An array can be passed to manually set all levels
				of the mipmap chain. If a single level is passed and mipmap filtering is being used,
				generateMipmap() will be called to produce the remaining levels.
			@param {number} width Texture width.
			@param {number} height Texture height.
			@param {number} depth Texture depth.
			@param {Object} [options] Texture options.
			@param {GLEnum} [options.type] Type of data stored in the texture. Defaults to UNSIGNED_SHORT
				if format is DEPTH_COMPONENT, UNSIGNED_BYTE otherwise.
			@param {GLEnum} [options.format=RGBA] Texture data format.
			@param {GLEnum} [options.internalFormat=RGBA] Texture data internal format.
			@param {boolean} [options.flipY=false] Whether the y-axis should be flipped when unpacking the texture.
			@param {GLEnum} [options.minFilter] Minification filter. Defaults to
				LINEAR_MIPMAP_NEAREST if image data is provided, NEAREST otherwise.
			@param {GLEnum} [options.magFilter] Magnification filter. Defaults to LINEAR
				if image data is provided, NEAREST otherwise.
			@param {GLEnum} [options.wrapS=REPEAT] Horizontal wrap mode.
			@param {GLEnum} [options.wrapT=REPEAT] Vertical wrap mode.
			@param {GLEnum} [options.wrapR=REPEAT] Depth wrap mode.
			@param {GLEnum} [options.compareMode=NONE] Comparison mode.
			@param {GLEnum} [options.compareFunc=LEQUAL] Comparison function.
			@param {GLEnum} [options.baseLevel] Base mipmap level.
			@param {GLEnum} [options.maxLevel] Maximum mipmap level.
			@param {GLEnum} [options.minLOD] Mimimum level of detail.
			@param {GLEnum} [options.maxLOD] Maximum level of detail.
			@param {boolean} [options.generateMipmaps] Should mipmaps be generated. Defaults to generating mipmaps if
				a mipmap sampling filter is use and the mipmap levels aren't provided directly.
			@return {Texture} New Texture object.
		*/
		Texture* CreateTexture3D(const void* image, int width, int height, int depth, const Options& options);

		/**
			Create a cubemap.

			@method
			@param {Object} options Texture options.
			@param {DOMElement|ArrayBufferView} [options.negX] The image data for the negative X direction.
					Can be any format that would be accepted by texImage2D.
			@param {DOMElement|ArrayBufferView} [options.posX] The image data for the positive X direction.
					Can be any format that would be accepted by texImage2D.
			@param {DOMElement|ArrayBufferView} [options.negY] The image data for the negative Y direction.
					Can be any format that would be accepted by texImage2D.
			@param {DOMElement|ArrayBufferView} [options.posY] The image data for the positive Y direction.
					Can be any format that would be accepted by texImage2D.
			@param {DOMElement|ArrayBufferView} [options.negZ] The image data for the negative Z direction.
					Can be any format that would be accepted by texImage2D.
			@param {DOMElement|ArrayBufferView} [options.posZ] The image data for the positive Z direction.
					Can be any format that would be accepted by texImage2D.
			@param {GLEnum} [options.type] Type of data stored in the texture. Defaults to UNSIGNED_SHORT
				if format is DEPTH_COMPONENT, UNSIGNED_BYTE otherwise.
			@param {GLEnum} [options.format=RGBA] Texture data format.
			@param {GLEnum} [options.internalFormat=RGBA] Texture data internal format.
			@param {boolean} [options.flipY=false] Whether the y-axis should be flipped when unpacking the texture.
			@param {GLEnum} [options.minFilter] Minification filter. Defaults to
				LINEAR_MIPMAP_NEAREST if image data is provided, NEAREST otherwise.
			@param {GLEnum} [options.magFilter] Magnification filter. Defaults to LINEAR
				if image data is provided, NEAREST otherwise.
			@param {GLEnum} [options.wrapS=REPEAT] Horizontal wrap mode.
			@param {GLEnum} [options.wrapT=REPEAT] Vertical wrap mode.
			@param {GLEnum} [options.compareMode=NONE] Comparison mode.
			@param {GLEnum} [options.compareFunc=LEQUAL] Comparison function.
			@param {GLEnum} [options.baseLevel] Base mipmap level.
			@param {GLEnum} [options.maxLevel] Maximum mipmap level.
			@param {GLEnum} [options.minLOD] Mimimum level of detail.
			@param {GLEnum} [options.maxLOD] Maximum level of detail.
			@param {boolean} [options.generateMipmaps] Should mipmaps be generated. Defaults to generating mipmaps if
				a mipmap sampling filter is usedd.
			@return {Cubemap} New Cubemap object.
		*/
		Cubemap* CreateCubemap(const Options& options);

		/**
			Create a framebuffer.

			@method
			@return {Framebuffer} New Framebuffer object.
		*/
		Framebuffer* CreateFramebuffer();

		/**
			Create a query.

			@method
			@param {GLEnum} target Information to query.
			@return {Query} New Query object.
		*/
		Query* CreateQuery(PicoGL::Constant target);
		/**
			Create a timer.

			@method
			@return {Timer} New Timer object.
		*/
		Timer* CreateTimer();

		/**
			Create a DrawCall. A DrawCall manages the state associated with
			a WebGL draw call including a program and associated vertex data, textures,
			uniforms and uniform blocks.

			@method
			@param {Program} program The program to use for this DrawCall.
			@param {VertexArray} vertexArray Vertex data to use for drawing.
			@param {GLEnum} [primitive=TRIANGLES] Type of primitive to draw.
			@return {DrawCall} New DrawCall object.
		*/
		DrawCall* CreateDrawCall(Program* program, VertexArray* vertexArray, PicoGL::Constant primitive = PicoGL::Constant::TRIANGLES);
	};

	App* CreateApp(const Options& options);
};

#endif