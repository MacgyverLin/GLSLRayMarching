#ifndef _RHI_h_ 
#define _RHI_h_ 

#include "Platform.h"
#include "Vector2.h"
#include "Vector3.h"
#include "Vector4.h"
#include "Matrix.h"
#include "Matrix4.h"

class RHI
{
public:
	enum class Constant
	{
		TRUE = -1,
		FALSE = 0,
		DEPTH_BUFFER_BIT,
		STENCIL_BUFFER_BIT,
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
		// TIMEOUT_IGNORED,
		// MAX_CLIENT_WAIT_TIMEOUT_WEBGL,

		// https://www.khronos.org/registry/webgl/extensions/EXT_disjoint_timer_query_webgl2/
		// QUERY_COUNTER_BITS_EXT,
		TIME_ELAPSED_EXT,
		// TIMESTAMP_EXT,
		// GPU_DISJOINT_EXT,

		// https://www.khronos.org/registry/webgl/extensions/WEBcompressed_texture_s3tc/
		COMPRESSED_RGB_S3TC_DXT1_EXT,
		COMPRESSED_RGBA_S3TC_DXT1_EXT,
		COMPRESSED_RGBA_S3TC_DXT3_EXT,
		COMPRESSED_RGBA_S3TC_DXT5_EXT,

		// https://www.khronos.org/registry/webgl/extensions/WEBcompressed_texture_s3tc_srgb/
		COMPRESSED_SRGB_S3TC_DXT1_EXT,
		COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT,
		COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT,
		COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT,

		// https://www.khronos.org/registry/webgl/extensions/WEBcompressed_texture_etc/
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

		// https://www.khronos.org/registry/webgl/extensions/WEBcompressed_texture_pvrtc/
		// COMPRESSED_RGB_PVRTC_4BPPV1_IMG,
		// COMPRESSED_RGB_PVRTC_2BPPV1_IMG,
		// COMPRESSED_RGBA_PVRTC_4BPPV1_IMG,
		// COMPRESSED_RGBA_PVRTC_2BPPV1_IMG,

		// https://www.khronos.org/registry/webgl/extensions/WEBcompressed_texture_astc/
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

		COMPRESSED_TYPES
	};

	class State;
	class Program;
	class VertexBuffer;
	class VertexArray;

	class Shader
	{
		friend class Program;
	public:
		Shader(RHI::State* state, RHI::Constant type, const char* source);
		~Shader();
	private:
		RHI::State* state;
		
		unsigned int shader;
	};

	class TransformFeedback
	{
	public:
		TransformFeedback(RHI::State* state);
		~TransformFeedback();
	private:
		RHI::State* state;
		
		unsigned int transformFeedback;
	};

	class Program
	{
		class UniformClass
		{
		public:
			UniformClass(unsigned int uniformHandle, unsigned int uniformInfoType, unsigned int uniformNumElements);

			void Set(const int& value);
			void Set(const unsigned int& value);
			void Set(const float& value);
			void Set(const bool& value);

			void Set(const IVector2& value);
			void Set(const UIVector2& value);
			void Set(const Vector2& value);
			void Set(const BVector2& value);

			void Set(const IVector3& value);
			void Set(const UIVector3& value);
			void Set(const Vector3& value);
			void Set(const BVector3& value);

			void Set(const IVector4& value);
			void Set(const UIVector4& value);
			void Set(const Vector4& value);
			void Set(const BVector4& value);

			void Set(const Matrix22& value);
			void Set(const Matrix32& value);
			void Set(const Matrix42& value);

			void Set(const Matrix23& value);
			void Set(const Matrix33& value);
			void Set(const Matrix43& value);

			void Set(const Matrix24& value);
			void Set(const Matrix34& value);
			void Set(const Matrix44& value);

			void Set(const int* value, int count);
			void Set(const unsigned int* value, int count);
			void Set(const float* value, int count);
			void Set(const bool* value, int count);

			void Set(const IVector2* value, int count);
			void Set(const UIVector2* value, int count);
			void Set(const Vector2* value, int count);
			void Set(const BVector2* value, int count);

			void Set(const IVector3* value, int count);
			void Set(const UIVector3* value, int count);
			void Set(const Vector3* value, int count);
			void Set(const BVector3* value, int count);

			void Set(const IVector4* value, int count);
			void Set(const UIVector4* value, int count);
			void Set(const Vector4* value, int count);
			void Set(const BVector4* value, int count);

			void Set(const Matrix22* value, int count);
			void Set(const Matrix32* value, int count);
			void Set(const Matrix42* value, int count);
								   
			void Set(const Matrix23* value, int count);
			void Set(const Matrix33* value, int count);
			void Set(const Matrix43* value, int count);
								   
			void Set(const Matrix24* value, int count);
			void Set(const Matrix34* value, int count);
			void Set(const Matrix44* value, int count);
		private:
			unsigned int uniformHandle;
			unsigned int uniformInfoType;
			unsigned int uniformNumElements;

			std::vector<unsigned char> cache;
		};
	public:
		Program(RHI::State* state, const char* vsSource, const char* fsSource, const std::vector<const char*>& xformFeebackVars);
		Program(RHI::State* state, RHI::Shader* vShader, RHI::Shader* fShader, const std::vector<const char*>& xformFeebackVars);
		~Program();

		template<class T>
		Program& Uniform(const char* name, const T& value)
		{
			uniforms[name].Set(value);

			return *this;
		}

		template<class T>
		Program& Uniform(const char* name, const T* value, int count)
		{
			uniforms[name].Set(value, count);
			
			return *this;
		}

		Program& Bind();
	private:
		void CreateProgramInternal(RHI::State* state, RHI::Shader* vShader, RHI::Shader* fShader, bool ownVertexShader, bool ownFragmentShader, const std::vector<const char*>& xformFeebackVars);
	private:
		RHI::State* state;

		unsigned int program;
		std::vector<const char*> transformFeedback;
		std::map<std::string, UniformClass* > uniforms;
		std::map<std::string, int> uniformBlocks;
		std::map<std::string, int> samplers;
	};

	class VertexArray
	{
		friend class VertexBuffer;
	public:
		VertexArray(RHI::State* state);
		virtual ~VertexArray();

		RHI::VertexArray& VertexAttributeBuffer(int attributeIndex, RHI::VertexBuffer* vertexBuffer);
		RHI::VertexArray& InstanceAttributeBuffer(int attributeIndex, RHI::VertexBuffer* vertexBuffer);
		RHI::VertexArray& VertexIntegerAttributeBuffer(int attributeIndex, RHI::VertexBuffer* vertexBuffer);
		RHI::VertexArray& InstanceIntegerAttributeBuffer(int attributeIndex, RHI::VertexBuffer* vertexBuffer);
		RHI::VertexArray& VertexNormalizedAttributeBuffer(int attributeIndex, RHI::VertexBuffer* vertexBuffer);
		RHI::VertexArray& InstanceNormalizedAttributeBuffer(int attributeIndex, RHI::VertexBuffer* vertexBuffer);
		RHI::VertexArray& IndexBuffer(RHI::VertexBuffer* vertexBuffer);

		RHI::VertexArray& Bind();
		RHI::VertexArray& AttributeBuffer(int attributeIndex, RHI::VertexBuffer* vertexBuffer, bool instanced, bool integer, bool normalized);
	private:
		RHI::State* state;

		unsigned int vertexArray;

		int numElements;
		RHI::Constant indexType;
		bool instanced;
		bool indexed;
		int numInstances;
	};

	class VertexBuffer
	{
		friend class VertexArray;
	public:
		VertexBuffer(RHI::State* state, RHI::Constant type, int itemSize, void* data, unsigned int dataLength, RHI::Constant usage, bool indexArray = false);
		VertexBuffer& Data(void* data, unsigned int dataLength);
		virtual ~VertexBuffer();
	private:
		RHI::State* state;

		unsigned int buffer;
		RHI::Constant type;
		int itemSize;
		int numItems;
		int numColumns;
		RHI::Constant usage;
		bool indexArray;
		unsigned int binding;
	};

	class UniformBuffer
	{
	public:
		UniformBuffer(RHI::State* state, const std::vector<RHI::Constant>& layout, RHI::Constant usage);
		virtual ~UniformBuffer();

		RHI::UniformBuffer& Set(int index, void* value, unsigned int dataLength);
		RHI::UniformBuffer& Update(int index);
		RHI::UniformBuffer& Bind(int base);
	private:
		RHI::State* state;

		unsigned int buffer;
		std::vector<unsigned char> data;
		std::map<RHI::Constant, unsigned char*> dataViews;
		std::vector<int> offsets;
		std::vector<int> sizes;
		std::vector<RHI::Constant> types;
		int size;
		RHI::Constant usage;

		// -1 indicates unbound
		int currentBase;
	};

	class Texture
	{
	public:
		Texture(RHI::State* state);
		virtual ~Texture();
	private:
		RHI::State* state;
	};

	class Framebuffer
	{
	public:
		Framebuffer(RHI::State* state);
		virtual ~Framebuffer();

		void BindForDraw();
		void BindForRead();
	private:
		RHI::State* state;
	};

	class DrawCall
	{
	public:
		DrawCall(RHI::State* state);
		virtual ~DrawCall();
	private:
		RHI::State* state;
	};

	class Query
	{
		friend class RHI;
	public:
		Query(RHI::State* state, RHI::Constant target);
		Query& Begin();
		Query& End();
		bool Ready();
		~Query();
	private:
		RHI::State* state;
		RHI::Constant target;
		unsigned int query;
		bool active;
		int result;
	};

	class State
	{
		friend class RHI;
	public:
		State
		(
			Program* program = nullptr,
			VertexArray* vertexArray = nullptr,
			TransformFeedback* transformFeedback = nullptr,
			int activeTexture = 0,
			std::vector<Texture*> textures = std::vector<Texture*>(),
			std::vector<UniformBuffer*> uniformBuffers = std::vector<UniformBuffer*>(),
			//freeUniformBufferBases: [],
			Framebuffer* drawFramebuffer = nullptr,
			Framebuffer* readFramebuffer = nullptr
		);
		~State();
	private:
		Program* program;
		VertexArray* vertexArray;
		TransformFeedback* transformFeedback;
		int activeTexture;
		std::vector<Texture*> textures;
		std::vector<UniformBuffer*> uniformBuffers;
		//freeUniformBufferBases: [] ;
		Framebuffer* drawFramebuffer;
		Framebuffer* readFramebuffer;
	};

	RHI();
	virtual ~RHI();

	RHI& ColorMask(bool r, bool g, bool b, bool a);
	RHI& ClearColor(float r, float g, float b, float a);
	RHI& ClearMask(bool clearColor, bool clearDepth, bool clearStencil);
	RHI& Clear();
	RHI& DrawFramebuffer(Framebuffer* framebuffer);
	RHI& ReadFramebuffer(Framebuffer* framebuffer);
	RHI& DefaultDrawFramebuffer();
	RHI& DefaultReadFramebuffer();
	RHI& DepthRange(float near, float far);
	RHI& DepthTest();
	RHI& NoDepthTest();
	RHI& DepthMask(bool mask);
	RHI& DepthFunc(RHI::Constant func);
	RHI& Blend();
	RHI& NoBlend();
	RHI& BlendFunc(RHI::Constant src, RHI::Constant dest);
	RHI& BlendFuncSeparate(RHI::Constant csrc, RHI::Constant cdest, RHI::Constant asrc, RHI::Constant adest);
	RHI& StencilTest();
	RHI& NoStencilTest();
	RHI& ScissorTest();
	RHI& NoScissorTest();
	RHI& Scissor(int x, int y, int width, int height);
	RHI& StencilMask(unsigned int mask);
	RHI& StencilMaskSeparate(RHI::Constant face, unsigned int mask);
	RHI& StencilFunc(RHI::Constant func, unsigned int ref, unsigned int mask);
	RHI& StencilFuncSeparate(RHI::Constant face, RHI::Constant func, unsigned int ref, unsigned int mask);
	RHI& StencilOp(RHI::Constant stencilFail, RHI::Constant depthFail, RHI::Constant pass);
	RHI& StencilOpSeparate(RHI::Constant face, RHI::Constant stencilFail, RHI::Constant depthFail, RHI::Constant pass);
	RHI& Rasterize();
	RHI& NoRasterize();
	RHI& CullBackfaces();
	RHI& NoCullBackfaces();
	RHI& FrontFaceClockwise();
	RHI& FrontFaceCounterClockwise();
	RHI& FloatRenderTargets();
	RHI& LinearFloatTextures();
	RHI& S3TCTextures();
	RHI& ETCTextures();
	RHI& ASTCTextures();
	RHI& PVRTCTextures();
	RHI& ReadPixel(int x, int y, void* outColor);
	RHI& ReadPixel(int x, int y, int w, int h, void* outColor);
	RHI& Viewport(int x, int y, int width, int height);
	RHI& DefaultViewport();
	RHI& Resize(int width, int height);
	RHI::Program* CreateProgram(const char* vsSource, const char* fsSource, const std::vector<const char*>& xformFeedbackVars);
	RHI::Shader* CreateShader(RHI::Constant type, const char* source);
	RHI::VertexArray* CreateVertexArray();
	RHI::TransformFeedback* CreateTransformFeedback();
	RHI::VertexBuffer* CreateVertexBuffer(RHI::Constant type, int itemSize, void* data, unsigned int dataLength, RHI::Constant usage);
	RHI::VertexBuffer* CreateMatrixBuffer(RHI::Constant type, void* data, unsigned int dataLength, RHI::Constant usage);
	RHI::VertexBuffer* CreateIndexBuffer(RHI::Constant type, int itemSize, void* data, unsigned int dataLength, RHI::Constant usage);
	RHI::UniformBuffer* CreateUniformBuffer(const std::vector<RHI::Constant>& layout, RHI::Constant usage);
private:
private:
	int width;
	int height;
	int viewportX;
	int viewportY;
	int viewportWidth;
	int viewportHeight;
	RHI::DrawCall* currentDrawCalls;
	RHI::Shader* emptyFragmentShader;
	RHI::State state;
	unsigned int clearBits;

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
};

#endif