#include "PicoGL.h"
#include "Graphics.h"

namespace PicoGL
{
	GLenum GetGLEnum(PicoGL::Constant picoGLConstant)
	{
		static const std::vector<GLenum> glEnums =
		{
			GL_TRUE,
			GL_FALSE,
			GL_STENCIL_BUFFER_BIT,
			GL_COLOR_BUFFER_BIT,
			GL_POINTS,
			GL_LINES,
			GL_LINE_LOOP,
			GL_LINE_STRIP,
			GL_TRIANGLES,
			GL_TRIANGLE_STRIP,
			GL_TRIANGLE_FAN,
			GL_ZERO,
			GL_ONE,
			GL_SRC_COLOR,
			GL_ONE_MINUS_SRC_COLOR,
			GL_SRC_ALPHA,
			GL_ONE_MINUS_SRC_ALPHA,
			GL_DST_ALPHA,
			GL_ONE_MINUS_DST_ALPHA,
			GL_DST_COLOR,
			GL_ONE_MINUS_DST_COLOR,
			GL_SRC_ALPHA_SATURATE,
			GL_FUNC_ADD,
			GL_BLEND_EQUATION,
			GL_BLEND_EQUATION_RGB,
			GL_BLEND_EQUATION_ALPHA,
			GL_FUNC_SUBTRACT,
			GL_FUNC_REVERSE_SUBTRACT,
			GL_BLEND_DST_RGB,
			GL_BLEND_SRC_RGB,
			GL_BLEND_DST_ALPHA,
			GL_BLEND_SRC_ALPHA,
			GL_CONSTANT_COLOR,
			GL_ONE_MINUS_CONSTANT_COLOR,
			GL_CONSTANT_ALPHA,
			GL_ONE_MINUS_CONSTANT_ALPHA,
			GL_BLEND_COLOR,
			GL_ARRAY_BUFFER,
			GL_ELEMENT_ARRAY_BUFFER,
			GL_ARRAY_BUFFER_BINDING,
			GL_ELEMENT_ARRAY_BUFFER_BINDING,
			GL_STREAM_DRAW,
			GL_STATIC_DRAW,
			GL_DYNAMIC_DRAW,
			GL_BUFFER_SIZE,
			GL_BUFFER_USAGE,
			GL_CURRENT_VERTEX_ATTRIB,
			GL_FRONT,
			GL_BACK,
			GL_FRONT_AND_BACK,
			GL_CULL_FACE,
			GL_BLEND,
			GL_DITHER,
			GL_STENCIL_TEST,
			GL_DEPTH_TEST,
			GL_SCISSOR_TEST,
			GL_POLYGON_OFFSET_FILL,
			GL_SAMPLE_ALPHA_TO_COVERAGE,
			GL_SAMPLE_COVERAGE,
			GL_NO_ERROR,
			GL_INVALID_ENUM,
			GL_INVALID_VALUE,
			GL_INVALID_OPERATION,
			GL_OUT_OF_MEMORY,
			GL_CW,
			GL_CCW,
			GL_LINE_WIDTH,
			GL_ALIASED_POINT_SIZE_RANGE,
			GL_ALIASED_LINE_WIDTH_RANGE,
			GL_CULL_FACE_MODE,
			GL_FRONT_FACE,
			GL_DEPTH_RANGE,
			GL_DEPTH_WRITEMASK,
			GL_DEPTH_CLEAR_VALUE,
			GL_DEPTH_FUNC,
			GL_STENCIL_CLEAR_VALUE,
			GL_STENCIL_FUNC,
			GL_STENCIL_FAIL,
			GL_STENCIL_PASS_DEPTH_FAIL,
			GL_STENCIL_PASS_DEPTH_PASS,
			GL_STENCIL_REF,
			GL_STENCIL_VALUE_MASK,
			GL_STENCIL_WRITEMASK,
			GL_STENCIL_BACK_FUNC,
			GL_STENCIL_BACK_FAIL,
			GL_STENCIL_BACK_PASS_DEPTH_FAIL,
			GL_STENCIL_BACK_PASS_DEPTH_PASS,
			GL_STENCIL_BACK_REF,
			GL_STENCIL_BACK_VALUE_MASK,
			GL_STENCIL_BACK_WRITEMASK,
			GL_VIEWPORT,
			GL_SCISSOR_BOX,
			GL_COLOR_CLEAR_VALUE,
			GL_COLOR_WRITEMASK,
			GL_UNPACK_ALIGNMENT,
			GL_PACK_ALIGNMENT,
			GL_MAX_TEXTURE_SIZE,
			GL_MAX_VIEWPORT_DIMS,
			GL_SUBPIXEL_BITS,
			GL_RED_BITS,
			GL_GREEN_BITS,
			GL_BLUE_BITS,
			GL_ALPHA_BITS,
			GL_DEPTH_BITS,
			GL_STENCIL_BITS,
			GL_POLYGON_OFFSET_UNITS,
			GL_POLYGON_OFFSET_FACTOR,
			GL_TEXTURE_BINDING_2D,
			GL_SAMPLE_BUFFERS,
			GL_SAMPLES,
			GL_SAMPLE_COVERAGE_VALUE,
			GL_SAMPLE_COVERAGE_INVERT,
			GL_COMPRESSED_TEXTURE_FORMATS,
			GL_DONT_CARE,
			GL_FASTEST,
			GL_NICEST,
			GL_GENERATE_MIPMAP_HINT,
			GL_BYTE,
			GL_UNSIGNED_BYTE,
			GL_SHORT,
			GL_UNSIGNED_SHORT,
			GL_INT,
			GL_UNSIGNED_INT,
			GL_FLOAT,
			GL_DEPTH_COMPONENT,
			GL_ALPHA,
			GL_RGB,
			GL_RGBA,
			GL_LUMINANCE,
			GL_LUMINANCE_ALPHA,
			GL_UNSIGNED_SHORT_4_4_4_4,
			GL_UNSIGNED_SHORT_5_5_5_1,
			GL_UNSIGNED_SHORT_5_6_5,
			GL_FRAGMENT_SHADER,
			GL_VERTEX_SHADER,
			GL_MAX_VERTEX_ATTRIBS,
			GL_MAX_VERTEX_UNIFORM_VECTORS,
			GL_MAX_VARYING_VECTORS,
			GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS,
			GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS,
			GL_MAX_TEXTURE_IMAGE_UNITS,
			GL_MAX_FRAGMENT_UNIFORM_VECTORS,
			GL_SHADER_TYPE,
			GL_DELETE_STATUS,
			GL_LINK_STATUS,
			GL_VALIDATE_STATUS,
			GL_ATTACHED_SHADERS,
			GL_ACTIVE_UNIFORMS,
			GL_ACTIVE_ATTRIBUTES,
			GL_SHADING_LANGUAGE_VERSION,
			GL_CURRENT_PROGRAM,
			GL_NEVER,
			GL_LESS,
			GL_EQUAL,
			GL_LEQUAL,
			GL_GREATER,
			GL_NOTEQUAL,
			GL_GEQUAL,
			GL_ALWAYS,
			GL_KEEP,
			GL_REPLACE,
			GL_INCR,
			GL_DECR,
			GL_INVERT,
			GL_INCR_WRAP,
			GL_DECR_WRAP,
			GL_VENDOR,
			GL_RENDERER,
			GL_VERSION,
			GL_NEAREST,
			GL_LINEAR,
			GL_NEAREST_MIPMAP_NEAREST,
			GL_LINEAR_MIPMAP_NEAREST,
			GL_NEAREST_MIPMAP_LINEAR,
			GL_LINEAR_MIPMAP_LINEAR,
			GL_TEXTURE_MAG_FILTER,
			GL_TEXTURE_MIN_FILTER,
			GL_TEXTURE_WRAP_S,
			GL_TEXTURE_WRAP_T,
			GL_TEXTURE_2D,
			GL_TEXTURE,
			GL_TEXTURE_CUBE_MAP,
			GL_TEXTURE_BINDING_CUBE_MAP,
			GL_TEXTURE_CUBE_MAP_POSITIVE_X,
			GL_TEXTURE_CUBE_MAP_NEGATIVE_X,
			GL_TEXTURE_CUBE_MAP_POSITIVE_Y,
			GL_TEXTURE_CUBE_MAP_NEGATIVE_Y,
			GL_TEXTURE_CUBE_MAP_POSITIVE_Z,
			GL_TEXTURE_CUBE_MAP_NEGATIVE_Z,
			GL_MAX_CUBE_MAP_TEXTURE_SIZE,
			GL_TEXTURE0,
			GL_TEXTURE1,
			GL_TEXTURE2,
			GL_TEXTURE3,
			GL_TEXTURE4,
			GL_TEXTURE5,
			GL_TEXTURE6,
			GL_TEXTURE7,
			GL_TEXTURE8,
			GL_TEXTURE9,
			GL_TEXTURE10,
			GL_TEXTURE11,
			GL_TEXTURE12,
			GL_TEXTURE13,
			GL_TEXTURE14,
			GL_TEXTURE15,
			GL_TEXTURE16,
			GL_TEXTURE17,
			GL_TEXTURE18,
			GL_TEXTURE19,
			GL_TEXTURE20,
			GL_TEXTURE21,
			GL_TEXTURE22,
			GL_TEXTURE23,
			GL_TEXTURE24,
			GL_TEXTURE25,
			GL_TEXTURE26,
			GL_TEXTURE27,
			GL_TEXTURE28,
			GL_TEXTURE29,
			GL_TEXTURE30,
			GL_TEXTURE31,
			GL_ACTIVE_TEXTURE,
			GL_REPEAT,
			GL_CLAMP_TO_EDGE,
			GL_MIRRORED_REPEAT,
			GL_FLOAT_VEC2,
			GL_FLOAT_VEC3,
			GL_FLOAT_VEC4,
			GL_INT_VEC2,
			GL_INT_VEC3,
			GL_INT_VEC4,
			GL_BOOL,
			GL_BOOL_VEC2,
			GL_BOOL_VEC3,
			GL_BOOL_VEC4,
			GL_FLOAT_MAT2,
			GL_FLOAT_MAT3,
			GL_FLOAT_MAT4,
			GL_SAMPLER_2D,
			GL_SAMPLER_CUBE,
			GL_VERTEX_ATTRIB_ARRAY_ENABLED,
			GL_VERTEX_ATTRIB_ARRAY_SIZE,
			GL_VERTEX_ATTRIB_ARRAY_STRIDE,
			GL_VERTEX_ATTRIB_ARRAY_TYPE,
			GL_VERTEX_ATTRIB_ARRAY_NORMALIZED,
			GL_VERTEX_ATTRIB_ARRAY_POINTER,
			GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING,
			GL_IMPLEMENTATION_COLOR_READ_TYPE,
			GL_IMPLEMENTATION_COLOR_READ_FORMAT,
			GL_COMPILE_STATUS,
			GL_LOW_FLOAT,
			GL_MEDIUM_FLOAT,
			GL_HIGH_FLOAT,
			GL_LOW_INT,
			GL_MEDIUM_INT,
			GL_HIGH_INT,
			GL_FRAMEBUFFER,
			GL_RENDERBUFFER,
			GL_RGBA4,
			GL_RGB5_A1,
			GL_RGB565,
			GL_DEPTH_COMPONENT16,
			GL_STENCIL_INDEX,
			GL_STENCIL_INDEX8,
			GL_DEPTH_STENCIL,
			GL_RENDERBUFFER_WIDTH,
			GL_RENDERBUFFER_HEIGHT,
			GL_RENDERBUFFER_INTERNAL_FORMAT,
			GL_RENDERBUFFER_RED_SIZE,
			GL_RENDERBUFFER_GREEN_SIZE,
			GL_RENDERBUFFER_BLUE_SIZE,
			GL_RENDERBUFFER_ALPHA_SIZE,
			GL_RENDERBUFFER_DEPTH_SIZE,
			GL_RENDERBUFFER_STENCIL_SIZE,
			GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE,
			GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME,
			GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL,
			GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE,
			GL_COLOR_ATTACHMENT0,
			GL_DEPTH_ATTACHMENT,
			GL_STENCIL_ATTACHMENT,
			GL_DEPTH_STENCIL_ATTACHMENT,
			GL_NONE,
			GL_FRAMEBUFFER_COMPLETE,
			GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT,
			GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT,
			// GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS,
			GL_FRAMEBUFFER_UNSUPPORTED,
			GL_FRAMEBUFFER_BINDING,
			GL_RENDERBUFFER_BINDING,
			GL_MAX_RENDERBUFFER_SIZE,
			GL_INVALID_FRAMEBUFFER_OPERATION,
			// GL_UNPACK_FLIP_Y_WEBGL,
			// GL_UNPACK_PREMULTIPLY_ALPHA_WEBGL,
			// GL_CONTEXT_LOST_WEBGL,
			// GL_UNPACK_COLORSPACE_CONVERSION_WEBGL,
			// GL_BROWSER_DEFAULT_WEBGL,
			GL_READ_BUFFER,
			GL_UNPACK_ROW_LENGTH,
			GL_UNPACK_SKIP_ROWS,
			GL_UNPACK_SKIP_PIXELS,
			GL_PACK_ROW_LENGTH,
			GL_PACK_SKIP_ROWS,
			GL_PACK_SKIP_PIXELS,
			GL_COLOR,
			GL_DEPTH,
			GL_STENCIL,
			GL_RED,
			GL_RGB8,
			GL_RGBA8,
			GL_RGB10_A2,
			GL_TEXTURE_BINDING_3D,
			GL_UNPACK_SKIP_IMAGES,
			GL_UNPACK_IMAGE_HEIGHT,
			GL_TEXTURE_3D,
			GL_TEXTURE_WRAP_R,
			GL_MAX_3D_TEXTURE_SIZE,
			GL_UNSIGNED_INT_2_10_10_10_REV,
			GL_MAX_ELEMENTS_VERTICES,
			GL_MAX_ELEMENTS_INDICES,
			GL_TEXTURE_MIN_LOD,
			GL_TEXTURE_MAX_LOD,
			GL_TEXTURE_BASE_LEVEL,
			GL_TEXTURE_MAX_LEVEL,
			GL_MIN,
			GL_MAX,
			GL_DEPTH_COMPONENT24,
			GL_MAX_TEXTURE_LOD_BIAS,
			GL_TEXTURE_COMPARE_MODE,
			GL_TEXTURE_COMPARE_FUNC,
			GL_CURRENT_QUERY,
			GL_QUERY_RESULT,
			GL_QUERY_RESULT_AVAILABLE,
			GL_STREAM_READ,
			GL_STREAM_COPY,
			GL_STATIC_READ,
			GL_STATIC_COPY,
			GL_DYNAMIC_READ,
			GL_DYNAMIC_COPY,
			GL_MAX_DRAW_BUFFERS,
			GL_DRAW_BUFFER0,
			GL_DRAW_BUFFER1,
			GL_DRAW_BUFFER2,
			GL_DRAW_BUFFER3,
			GL_DRAW_BUFFER4,
			GL_DRAW_BUFFER5,
			GL_DRAW_BUFFER6,
			GL_DRAW_BUFFER7,
			GL_DRAW_BUFFER8,
			GL_DRAW_BUFFER9,
			GL_DRAW_BUFFER10,
			GL_DRAW_BUFFER11,
			GL_DRAW_BUFFER12,
			GL_DRAW_BUFFER13,
			GL_DRAW_BUFFER14,
			GL_DRAW_BUFFER15,
			GL_MAX_FRAGMENT_UNIFORM_COMPONENTS,
			GL_MAX_VERTEX_UNIFORM_COMPONENTS,
			GL_SAMPLER_3D,
			GL_SAMPLER_2D_SHADOW,
			GL_FRAGMENT_SHADER_DERIVATIVE_HINT,
			GL_PIXEL_PACK_BUFFER,
			GL_PIXEL_UNPACK_BUFFER,
			GL_PIXEL_PACK_BUFFER_BINDING,
			GL_PIXEL_UNPACK_BUFFER_BINDING,
			GL_FLOAT_MAT2x3,
			GL_FLOAT_MAT2x4,
			GL_FLOAT_MAT3x2,
			GL_FLOAT_MAT3x4,
			GL_FLOAT_MAT4x2,
			GL_FLOAT_MAT4x3,
			GL_SRGB,
			GL_SRGB8,
			GL_SRGB8_ALPHA8,
			GL_COMPARE_REF_TO_TEXTURE,
			GL_RGBA32F,
			GL_RGB32F,
			GL_RGBA16F,
			GL_RGB16F,
			GL_VERTEX_ATTRIB_ARRAY_INTEGER,
			GL_MAX_ARRAY_TEXTURE_LAYERS,
			GL_MIN_PROGRAM_TEXEL_OFFSET,
			GL_MAX_PROGRAM_TEXEL_OFFSET,
			GL_MAX_VARYING_COMPONENTS,
			GL_TEXTURE_2D_ARRAY,
			GL_TEXTURE_BINDING_2D_ARRAY,
			GL_R11F_G11F_B10F,
			GL_UNSIGNED_INT_10F_11F_11F_REV,
			GL_RGB9_E5,
			GL_UNSIGNED_INT_5_9_9_9_REV,
			GL_TRANSFORM_FEEDBACK_BUFFER_MODE,
			GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS,
			GL_TRANSFORM_FEEDBACK_VARYINGS,
			GL_TRANSFORM_FEEDBACK_BUFFER_START,
			GL_TRANSFORM_FEEDBACK_BUFFER_SIZE,
			GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN,
			GL_RASTERIZER_DISCARD,
			GL_MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS,
			GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS,
			GL_INTERLEAVED_ATTRIBS,
			GL_SEPARATE_ATTRIBS,
			GL_TRANSFORM_FEEDBACK_BUFFER,
			GL_TRANSFORM_FEEDBACK_BUFFER_BINDING,
			GL_RGBA32UI,
			GL_RGB32UI,
			GL_RGBA16UI,
			GL_RGB16UI,
			GL_RGBA8UI,
			GL_RGB8UI,
			GL_RGBA32I,
			GL_RGB32I,
			GL_RGBA16I,
			GL_RGB16I,
			GL_RGBA8I,
			GL_RGB8I,
			GL_RED_INTEGER,
			GL_RGB_INTEGER,
			GL_RGBA_INTEGER,
			GL_SAMPLER_2D_ARRAY,
			GL_SAMPLER_2D_ARRAY_SHADOW,
			GL_SAMPLER_CUBE_SHADOW,
			GL_UNSIGNED_INT_VEC2,
			GL_UNSIGNED_INT_VEC3,
			GL_UNSIGNED_INT_VEC4,
			GL_INT_SAMPLER_2D,
			GL_INT_SAMPLER_3D,
			GL_INT_SAMPLER_CUBE,
			GL_INT_SAMPLER_2D_ARRAY,
			GL_UNSIGNED_INT_SAMPLER_2D,
			GL_UNSIGNED_INT_SAMPLER_3D,
			GL_UNSIGNED_INT_SAMPLER_CUBE,
			GL_UNSIGNED_INT_SAMPLER_2D_ARRAY,
			GL_DEPTH_COMPONENT32F,
			GL_DEPTH32F_STENCIL8,
			GL_FLOAT_32_UNSIGNED_INT_24_8_REV,
			GL_FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING,
			GL_FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE,
			GL_FRAMEBUFFER_ATTACHMENT_RED_SIZE,
			GL_FRAMEBUFFER_ATTACHMENT_GREEN_SIZE,
			GL_FRAMEBUFFER_ATTACHMENT_BLUE_SIZE,
			GL_FRAMEBUFFER_ATTACHMENT_ALPHA_SIZE,
			GL_FRAMEBUFFER_ATTACHMENT_DEPTH_SIZE,
			GL_FRAMEBUFFER_ATTACHMENT_STENCIL_SIZE,
			GL_FRAMEBUFFER_DEFAULT,
			GL_UNSIGNED_INT_24_8,
			GL_DEPTH24_STENCIL8,
			GL_UNSIGNED_NORMALIZED,
			GL_DRAW_FRAMEBUFFER_BINDING,
			GL_READ_FRAMEBUFFER,
			GL_DRAW_FRAMEBUFFER,
			GL_READ_FRAMEBUFFER_BINDING,
			GL_RENDERBUFFER_SAMPLES,
			GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER,
			GL_MAX_COLOR_ATTACHMENTS,
			GL_COLOR_ATTACHMENT1,
			GL_COLOR_ATTACHMENT2,
			GL_COLOR_ATTACHMENT3,
			GL_COLOR_ATTACHMENT4,
			GL_COLOR_ATTACHMENT5,
			GL_COLOR_ATTACHMENT6,
			GL_COLOR_ATTACHMENT7,
			GL_COLOR_ATTACHMENT8,
			GL_COLOR_ATTACHMENT9,
			GL_COLOR_ATTACHMENT10,
			GL_COLOR_ATTACHMENT11,
			GL_COLOR_ATTACHMENT12,
			GL_COLOR_ATTACHMENT13,
			GL_COLOR_ATTACHMENT14,
			GL_COLOR_ATTACHMENT15,
			GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE,
			GL_MAX_SAMPLES,
			GL_HALF_FLOAT,
			GL_RG,
			GL_RG_INTEGER,
			GL_R8,
			GL_RG8,
			GL_R16F,
			GL_R32F,
			GL_RG16F,
			GL_RG32F,
			GL_R8I,
			GL_R8UI,
			GL_R16I,
			GL_R16UI,
			GL_R32I,
			GL_R32UI,
			GL_RG8I,
			GL_RG8UI,
			GL_RG16I,
			GL_RG16UI,
			GL_RG32I,
			GL_RG32UI,
			GL_VERTEX_ARRAY_BINDING,
			GL_R8_SNORM,
			GL_RG8_SNORM,
			GL_RGB8_SNORM,
			GL_RGBA8_SNORM,
			GL_SIGNED_NORMALIZED,
			GL_COPY_READ_BUFFER,
			GL_COPY_WRITE_BUFFER,
			GL_COPY_READ_BUFFER_BINDING,
			GL_COPY_WRITE_BUFFER_BINDING,
			GL_UNIFORM_BUFFER,
			GL_UNIFORM_BUFFER_BINDING,
			GL_UNIFORM_BUFFER_START,
			GL_UNIFORM_BUFFER_SIZE,
			GL_MAX_VERTEX_UNIFORM_BLOCKS,
			GL_MAX_FRAGMENT_UNIFORM_BLOCKS,
			GL_MAX_COMBINED_UNIFORM_BLOCKS,
			GL_MAX_UNIFORM_BUFFER_BINDINGS,
			GL_MAX_UNIFORM_BLOCK_SIZE,
			GL_MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS,
			GL_MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS,
			GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT,
			GL_ACTIVE_UNIFORM_BLOCKS,
			GL_UNIFORM_TYPE,
			GL_UNIFORM_SIZE,
			GL_UNIFORM_BLOCK_INDEX,
			GL_UNIFORM_OFFSET,
			GL_UNIFORM_ARRAY_STRIDE,
			GL_UNIFORM_MATRIX_STRIDE,
			GL_UNIFORM_IS_ROW_MAJOR,
			GL_UNIFORM_BLOCK_BINDING,
			GL_UNIFORM_BLOCK_DATA_SIZE,
			GL_UNIFORM_BLOCK_ACTIVE_UNIFORMS,
			GL_UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES,
			GL_UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER,
			GL_UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER,
			GL_INVALID_INDEX,
			GL_MAX_VERTEX_OUTPUT_COMPONENTS,
			GL_MAX_FRAGMENT_INPUT_COMPONENTS,
			GL_MAX_SERVER_WAIT_TIMEOUT,
			GL_OBJECT_TYPE,
			GL_SYNC_CONDITION,
			GL_SYNC_STATUS,
			GL_SYNC_FLAGS,
			GL_SYNC_FENCE,
			GL_SYNC_GPU_COMMANDS_COMPLETE,
			GL_UNSIGNALED,
			GL_SIGNALED,
			GL_ALREADY_SIGNALED,
			GL_TIMEOUT_EXPIRED,
			GL_CONDITION_SATISFIED,
			GL_WAIT_FAILED,
			GL_SYNC_FLUSH_COMMANDS_BIT,
			GL_VERTEX_ATTRIB_ARRAY_DIVISOR,
			GL_ANY_SAMPLES_PASSED,
			GL_ANY_SAMPLES_PASSED_CONSERVATIVE,
			GL_SAMPLER_BINDING,
			GL_RGB10_A2UI,
			GL_INT_2_10_10_10_REV,
			GL_TRANSFORM_FEEDBACK,
			GL_TRANSFORM_FEEDBACK_PAUSED,
			GL_TRANSFORM_FEEDBACK_ACTIVE,
			GL_TRANSFORM_FEEDBACK_BINDING,
			GL_TEXTURE_IMMUTABLE_FORMAT,
			GL_MAX_ELEMENT_INDEX,
			GL_TEXTURE_IMMUTABLE_LEVELS,
			// GL_TIMEOUT_IGNORED,
			// GL_MAX_CLIENT_WAIT_TIMEOUT_WEBGL,

			// GL_QUERY_COUNTER_BITS_EXT,
			GL_TIME_ELAPSED_EXT,
			// GL_TIMESTAMP_EXT,
			// GL_GPU_DISJOINT_EXT,

			GL_COMPRESSED_RGB_S3TC_DXT1_EXT,
			GL_COMPRESSED_RGBA_S3TC_DXT1_EXT,
			GL_COMPRESSED_RGBA_S3TC_DXT3_EXT,
			GL_COMPRESSED_RGBA_S3TC_DXT5_EXT,

			GL_COMPRESSED_SRGB_S3TC_DXT1_EXT,
			GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT,
			GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT,
			GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT,

			GL_COMPRESSED_R11_EAC,
			GL_COMPRESSED_SIGNED_R11_EAC,
			GL_COMPRESSED_RG11_EAC,
			GL_COMPRESSED_SIGNED_RG11_EAC,
			GL_COMPRESSED_RGB8_ETC2,
			GL_COMPRESSED_SRGB8_ETC2,
			GL_COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2,
			GL_COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2,
			GL_COMPRESSED_RGBA8_ETC2_EAC,
			GL_COMPRESSED_SRGB8_ALPHA8_ETC2_EAC,

			// GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG,
			// GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG,
			// GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG,
			// GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG,

			GL_COMPRESSED_RGBA_ASTC_4x4_KHR,
			GL_COMPRESSED_RGBA_ASTC_5x4_KHR,
			GL_COMPRESSED_RGBA_ASTC_5x5_KHR,
			GL_COMPRESSED_RGBA_ASTC_6x5_KHR,
			GL_COMPRESSED_RGBA_ASTC_6x6_KHR,
			GL_COMPRESSED_RGBA_ASTC_8x5_KHR,
			GL_COMPRESSED_RGBA_ASTC_8x6_KHR,
			GL_COMPRESSED_RGBA_ASTC_8x8_KHR,
			GL_COMPRESSED_RGBA_ASTC_10x5_KHR,
			GL_COMPRESSED_RGBA_ASTC_10x6_KHR,
			GL_COMPRESSED_RGBA_ASTC_10x8_KHR,
			GL_COMPRESSED_RGBA_ASTC_10x10_KHR,
			GL_COMPRESSED_RGBA_ASTC_12x10_KHR,
			GL_COMPRESSED_RGBA_ASTC_12x12_KHR,
			GL_COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR,
			GL_COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR,
			GL_COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR,
			GL_COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR,
			GL_COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR,
			GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR,
			GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR,
			GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR,
			GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR,
			GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR,
			GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR,
			GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR,
			GL_COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR,
			GL_COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR,
			0,
			0,
			0
		};

		return glEnums[((int)picoGLConstant) + 1];
	}

	static std::map<GLenum, int> TYPE_SIZE =
	{
		{ GL_BYTE			, 1},
		{ GL_UNSIGNED_BYTE	, 1},
		{ GL_SHORT			, 2},
		{ GL_UNSIGNED_SHORT , 2},
		{ GL_INT			, 4},
		{ GL_UNSIGNED_INT	, 4},
		{ GL_FLOAT			, 4}
	};

#define IMPLEMENT_INIT_OPTION(options, key, value) \
PicoGL::Constant key = value; \
if(options.find(#key) != options.end()) \
    key = options.at(#key);

	static std::map<PicoGL::Constant, std::map<PicoGL::Constant, PicoGL::Constant> > TEXTURE_FORMAT_DEFAULTS =
	{
		{
			PicoGL::Constant::UNSIGNED_BYTE,
			{
				{ PicoGL::Constant::RED , PicoGL::Constant::R8     },
				{ PicoGL::Constant::RG  , PicoGL::Constant::RG8    },
				{ PicoGL::Constant::RGB , PicoGL::Constant::RGB8   },
				{ PicoGL::Constant::RGBA, PicoGL::Constant::RGBA8  }
			}
		},

		{
			PicoGL::Constant::UNSIGNED_SHORT,
			{
				{ PicoGL::Constant::DEPTH_COMPONENT, PicoGL::Constant::DEPTH_COMPONENT16 }
			}
		},

		{
			PicoGL::Constant::FLOAT,
			{
				{ PicoGL::Constant::RED , PicoGL::Constant::R16F							},
				{ PicoGL::Constant::RG  , PicoGL::Constant::RG16F							},
				{ PicoGL::Constant::RGB , PicoGL::Constant::RGB16F							},
				{ PicoGL::Constant::RGBA, PicoGL::Constant::RGBA16F							},
				{ PicoGL::Constant::DEPTH_COMPONENT, PicoGL::Constant::DEPTH_COMPONENT32F	}
			}
		},

		{
			PicoGL::Constant::COMPRESSED_TYPES,
			{
			}
		}
	};


	/**
		Shader.

		@class
		@prop {WebGLShader} shader The shader.
	*/
	Shader::Shader(PicoGL::Constant type, const char* const* source, int sourceLength)
	{
		this->shader = glCreateShader(GetGLEnum(type));

		int length;
		glShaderSource(this->shader, sourceLength, source, &length);
		glCompileShader(this->shader);

		int success;
		glGetShaderiv(this->shader, GL_COMPILE_STATUS, &success);
		if (!success)
		{
			char infoLog[512];
			glGetShaderInfoLog(success, 512, NULL, infoLog);
			::Debug("ERROR::SHADER::VERTEX::COMPILATION_FAILED\n %s\n", infoLog);
		};

		/*
		this.gl = gl;
		this.shader = gl.createShader(type);
		gl.shaderSource(this.shader, source);
		gl.compileShader(this.shader);

		if (!gl.getShaderParameter(this.shader, gl.COMPILE_STATUS)) {
			let i, lines;

			console.error(gl.getShaderInfoLog(this.shader));
			lines = source.split("\n");
			for (i = 0; i < lines.length; ++i) {
				console.error(`${i + 1}: ${lines[i]}`);
			}
		}
		*/
	}

	/**
		Delete this shader.

		@method
		@return {Shader} The Shader object.
	*/
	Shader::~Shader()
	{
		if (this->shader)
		{
			glDeleteShader(this->shader);
			this->shader = 0;
		}
		/*
		if (this.shader) {
			this.gl.deleteShader(this.shader);
			this.shader = null;
		}
		return this;
		*/
	}


	/**
		Generic query object.

		@class
		@prop {WebGLRenderingContext} gl The WebGL context.
		@prop {WebGLQuery} query Query object.
		@prop {GLEnum} target The type of information being queried.
		@prop {boolean} active Whether or not a query is currently in progress.
		@prop {Any} result The result of the query (only available after a call to ready() returns true).
	*/

	Query::Query(PicoGL::Constant target)
	{
		glCreateQueries(GetGLEnum(target), 1, &(this->query));

		this->target = target;
		this->active = false;
		this->result = 0;

		/*
		this.gl = gl;
		this.query = gl.createQuery();
		this.target = target;
		this.active = false;
		this.result = null;
		*/
	}

	/**
		Begin a query.

		@method
		@return {Query} The Query object.
	*/
	Query* Query::Begin()
	{
		if (!this->active)
		{
			glBeginQuery(GetGLEnum(this->target), this->query);
			this->result = 0;
		}

		return this;

		/*
		if (!this.active) {
			this.gl.beginQuery(this.target, this.query);
			this.result = null;
		}

		return this;
		*/
	}

	/**
		End a query.

		@method
		@return {Query} The Query object.
	*/
	Query* Query::End()
	{
		if (!this->active) {
			glEndQuery(GetGLEnum(this->target));
			this->active = true;
		}

		return this;

		/*
		if (!this.active) {
			this.gl.endQuery(this.target);
			this.active = true;
		}

		return this;
		*/
	}

	/**
		Check if query result is available.

		@method
		@return {boolean} If results are available.
	*/
	bool Query::Ready()
	{
		if (this->active)
		{
			int resultAvaliable;
			glGetQueryObjectiv(this->query, GL_QUERY_RESULT_AVAILABLE, &resultAvaliable);
			if (resultAvaliable)
			{
				this->active = false;

				// Note(Tarek): Casting because FF incorrectly returns booleans.
				// https://bugzilla.mozilla.org/show_bug.cgi?id=1422714 
				glGetQueryObjectiv(this->query, GL_QUERY_RESULT, &this->result);
				return true;
			}
		}

		return false;

		/*
		if (this.active && this.gl.getQueryParameter(this.query, this.gl.QUERY_RESULT_AVAILABLE)) {
			this.active = false;
			// Note(Tarek): Casting because FF incorrectly returns booleans.
			// https://bugzilla.mozilla.org/show_bug.cgi?id=1422714
			this.result = Number(this.gl.getQueryParameter(this.query, this.gl.QUERY_RESULT));
			return true;
		}

		return false;
		*/
	}

	/**
		Delete this query.

		@method
		@return {Query} The Query object.
	*/
	Query::~Query()
	{
		if (this->query)
		{
			glDeleteQueries(1, &this->query);
			this->query = 0;
		}

		/*
		if (this.query) {
			this.gl.deleteQuery(this.query);
			this.query = null;
		}

		return this;
		*/
	}



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

	Cubemap::Cubemap(State* state, const Options& options)
	{
		/*
		let{ negX, posX, negY, posY, negZ, posZ } = options;

		let defaultType = options.format == = CONSTANTS.DEPTH_COMPONENT ? CONSTANTS.UNSIGNED_SHORT : CONSTANTS.UNSIGNED_BYTE;

		this.gl = gl;
		this.texture = gl.createTexture();
		this.format = options.format != = undefined ? options.format : gl.RGBA;
		this.type = options.type != = undefined ? options.type : defaultType;
		this.internalFormat = options.internalFormat != = undefined ? options.internalFormat : TEXTURE_FORMAT_DEFAULTS[this.type][this.format];
		this.appState = appState;

		// -1 indicates unbound
		this.currentUnit = -1;

		let{
			width = negX.width,
			height = negX.height,
			flipY = false,
			minFilter = negX ? gl.LINEAR_MIPMAP_NEAREST : gl.NEAREST,
			magFilter = negX ? gl.LINEAR : gl.NEAREST,
			wrapS = gl.REPEAT,
			wrapT = gl.REPEAT,
			compareMode = gl.NONE,
			compareFunc = gl.LEQUAL,
			generateMipmaps = minFilter == = gl.LINEAR_MIPMAP_NEAREST || minFilter == = gl.LINEAR_MIPMAP_LINEAR
		} = options;

		this.bind(0);
		gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, flipY);
		gl.texParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MAG_FILTER, magFilter);
		gl.texParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MIN_FILTER, minFilter);
		gl.texParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_S, wrapS);
		gl.texParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_WRAP_T, wrapT);
		gl.texParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_COMPARE_FUNC, compareFunc);
		gl.texParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_COMPARE_MODE, compareMode);
		if (options.baseLevel != = undefined) {
			gl.texParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_BASE_LEVEL, options.baseLevel);
		}
		if (options.maxLevel != = undefined) {
			gl.texParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MAX_LEVEL, options.maxLevel);
		}
		if (options.minLOD != = undefined) {
			gl.texParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MIN_LOD, options.minLOD);
		}
		if (options.maxLOD != = undefined) {
			gl.texParameteri(gl.TEXTURE_CUBE_MAP, gl.TEXTURE_MAX_LOD, options.maxLOD);
		}

		let levels = generateMipmaps ? Math.floor(Math.log2(Math.min(width, height))) + 1 : 1;
		gl.texStorage2D(gl.TEXTURE_CUBE_MAP, levels, this.internalFormat, width, height);

		if (negX) {
			gl.texSubImage2D(gl.TEXTURE_CUBE_MAP_NEGATIVE_X, 0, 0, 0, width, height, this.format, this.type, negX);
			gl.texSubImage2D(gl.TEXTURE_CUBE_MAP_POSITIVE_X, 0, 0, 0, width, height, this.format, this.type, posX);
			gl.texSubImage2D(gl.TEXTURE_CUBE_MAP_NEGATIVE_Y, 0, 0, 0, width, height, this.format, this.type, negY);
			gl.texSubImage2D(gl.TEXTURE_CUBE_MAP_POSITIVE_Y, 0, 0, 0, width, height, this.format, this.type, posY);
			gl.texSubImage2D(gl.TEXTURE_CUBE_MAP_NEGATIVE_Z, 0, 0, 0, width, height, this.format, this.type, negZ);
			gl.texSubImage2D(gl.TEXTURE_CUBE_MAP_POSITIVE_Z, 0, 0, 0, width, height, this.format, this.type, posZ);
		}

		if (generateMipmaps) {
			gl.generateMipmap(gl.TEXTURE_CUBE_MAP);
		}

		*/
	}

	Cubemap::~Cubemap()
	{
		/*
		if (this.texture) {
			this.gl.deleteTexture(this.texture);
			this.texture = null;
			this.appState.textures[this.currentUnit] = null;
			this.currentUnit = -1;
		}

		return this;
		*/
	}

	/**
		Bind this cubemap to a texture unit.

		@method
		@ignore
		@return {Cubemap} The Cubemap object.
	*/
	Cubemap* Cubemap::Bind(int unit) {
		return this;
		/*
		let currentTexture = this.appState.textures[unit];

		if (currentTexture != = this) {
			if (currentTexture) {
				currentTexture.currentUnit = -1;
			}

			if (this.currentUnit != = -1) {
				this.appState.textures[this.currentUnit] = null;
			}

			this.gl.activeTexture(this.gl.TEXTURE0 + unit);
			this.gl.bindTexture(this.gl.TEXTURE_CUBE_MAP, this.texture);

			this.appState.textures[unit] = this;
			this.currentUnit = unit;
		}

		return this;
		*/
	}


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

	DrawCall::DrawCall(State* state, Program* program, VertexArray* vertexArray, PicoGL::Constant primitive)
	{
		/*
		this.gl = gl;
		this.currentProgram = program;
		this.currentVertexArray = vertexArray;
		this.currentTransformFeedback = null;
		this.appState = appState;

		this.uniformIndices = {};
		this.uniformNames = new Array(CONSTANTS.WEBGL_INFO.MAX_UNIFORMS);
		this.uniformValues = new Array(CONSTANTS.WEBGL_INFO.MAX_UNIFORMS);
		this.uniformCount = 0;
		this.uniformBuffers = new Array(CONSTANTS.WEBGL_INFO.MAX_UNIFORM_BUFFERS);
		this.uniformBlockNames = new Array(CONSTANTS.WEBGL_INFO.MAX_UNIFORM_BUFFERS);
		this.uniformBlockBases = {};
		this.uniformBlockCount = 0;
		this.samplerIndices = {};
		this.textures = new Array(CONSTANTS.WEBGL_INFO.MAX_TEXTURE_UNITS);
		this.textureCount = 0;
		this.primitive = primitive;

		this.numElements = this.currentVertexArray.numElements;
		this.numInstances = this.currentVertexArray.numInstances;
		*/
	}

	/**
		Set the current TransformFeedback object for draw

		@method
		@param {TransformFeedback} transformFeedback Transform Feedback to set.
		@return {DrawCall} The DrawCall object.
	*/
	DrawCall* DrawCall::TransformFeedback(PicoGL::TransformFeedback* transformFeedback) {
		return this;
		/*
		this.currentTransformFeedback = transformFeedback;

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
	DrawCall* DrawCall::Texture(const char* name, PicoGL::Texture* texture) {
		return this;
		/*
		let unit = this.currentProgram.samplers[name];
		this.textures[unit] = texture;

		return this;
		*/
	}

	/**
		Set uniform buffer to bind to a uniform block.

		@method
		@param {string} name Uniform block name.
		@param {UniformBuffer} buffer Uniform buffer to bind.
		@return {DrawCall} The DrawCall object.
	*/
	DrawCall* DrawCall::UniformBlock(const char* name, PicoGL::UniformBuffer* buffer) {
		return this;
		/*
		let base = this.currentProgram.uniformBlocks[name];
		this.uniformBuffers[base] = buffer;

		return this;
		*/
	}

	/**
		 Set numElements property to allow number of elements to be drawn

		 @method
		 @param {GLsizei} [count=0] Number of element to draw, 0 set to all.
		 @return {DrawCall} The DrawCall object.
	 */
	DrawCall* DrawCall::ElementCount(int count) {
		return this;
		/*
		if (count > 0) {
			this.numElements = Math.min(count, this.currentVertexArray.numElements);
		}
		else {
			this.numElements = this.currentVertexArray.numElements;
		}

		return this;
		*/
	}

	/**
		Set numInstances property to allow number of instances be drawn

		@method
		@param {GLsizei} [count=0] Number of instance to draw, 0 set to all.
		@return {DrawCall} The DrawCall object.
	*/
	DrawCall* DrawCall::InstanceCount(int count) {
		return this;
		/*
		if (count > 0) {
			this.numInstances = Math.min(count, this.currentVertexArray.numInstances);
		}
		else {
			this.numInstances = this.currentVertexArray.numInstances;
		}

		return this;
		*/
	}

	/**
		Draw based on current state.

		@method
		@return {DrawCall} The DrawCall object.
	*/
	DrawCall* DrawCall::Draw() {
		return this;
		/*
		let uniformNames = this.uniformNames;
		let uniformValues = this.uniformValues;
		let uniformBuffers = this.uniformBuffers;
		let uniformBlockCount = this.currentProgram.uniformBlockCount;
		let textures = this.textures;
		let textureCount = this.currentProgram.samplerCount;

		this.currentProgram.bind();
		this.currentVertexArray.bind();

		for (let uIndex = 0; uIndex < this.uniformCount; ++uIndex) {
			this.currentProgram.uniform(uniformNames[uIndex], uniformValues[uIndex]);
		}

		for (let base = 0; base < uniformBlockCount; ++base) {
			uniformBuffers[base].bind(base);
		}

		for (let tIndex = 0; tIndex < textureCount; ++tIndex) {
			textures[tIndex].bind(tIndex);
		}

		if (this.currentTransformFeedback) {
			this.currentTransformFeedback.bind();
			this.gl.beginTransformFeedback(this.primitive);
		}

		if (this.currentVertexArray.instanced) {
			if (this.currentVertexArray.indexed) {
				this.gl.drawElementsInstanced(this.primitive, this.numElements, this.currentVertexArray.indexType, 0, this.numInstances);
			}
			else {
				this.gl.drawArraysInstanced(this.primitive, 0, this.numElements, this.numInstances);
			}
		}
		else if (this.currentVertexArray.indexed) {
			this.gl.drawElements(this.primitive, this.numElements, this.currentVertexArray.indexType, 0);
		}
		else {
			this.gl.drawArrays(this.primitive, 0, this.numElements);
		}

		if (this.currentTransformFeedback) {
			this.gl.endTransformFeedback();
			// TODO(Tarek): Need to rebind buffers due to bug in ANGLE.
			// Remove this when that's fixed.
			for (let i = 0, len = this.currentTransformFeedback.angleBugBuffers.length; i < len; ++i) {
				this.gl.bindBufferBase(this.gl.TRANSFORM_FEEDBACK_BUFFER, i, null);
			}
		}

		return this;
		*/
	}

	DrawCall::~DrawCall()
	{
	}


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
	Framebuffer::Framebuffer(State* state)
	{
		/*
		this.gl = gl;
		this.framebuffer = gl.createFramebuffer();
		this.appState = appState;

		this.numColorTargets = 0;

		this.colorTextures = [];
		this.colorAttachments = [];
		this.colorTextureTargets = [];
		this.depthTexture = null;
		this.depthTextureTarget = null;
		*/
	}

	/**
		 Attach a color target to this framebuffer.

		 @method
		 @param {number} index Color attachment index.
		 @param {Texture} texture The texture to attach.
		 @param {GLEnum} [target] The texture target or layer to attach. If the texture is 3D or a texture array,
			 defaults to 0, otherwise to TEXTURE_2D.
		 @return {Framebuffer} The Framebuffer object.
	 */
	Framebuffer* Framebuffer::ColorTarget(int index, Texture* texture) {
		// target = texture->is3D ? 0 : PicoGL::Constant::TEXTURE_2D

		return this;
		/*
		this.colorAttachments[index] = CONSTANTS.COLOR_ATTACHMENT0 + index;

		let currentFramebuffer = this.bindAndCaptureState();

		this.colorTextures[index] = texture;
		this.colorTextureTargets[index] = target;

		if (texture.is3D) {
			this.gl.framebufferTextureLayer(this.gl.DRAW_FRAMEBUFFER, this.colorAttachments[index], texture.texture, 0, target);
		}
		else {
			this.gl.framebufferTexture2D(this.gl.DRAW_FRAMEBUFFER, this.colorAttachments[index], target, texture.texture, 0);
		}

		this.gl.drawBuffers(this.colorAttachments);
		this.numColorTargets++;

		this.restoreState(currentFramebuffer);

		return this;
		*/
	}

	/**
		Attach a depth target to this framebuffer.

		@method
		@param {Texture} texture The texture to attach.
		@param {GLEnum} [target] The texture target or layer to attach. If the texture is 3D or a texture array,
			defaults to 0, otherwise to TEXTURE_2D.
		@return {Framebuffer} The Framebuffer object.
	*/
	PicoGL::Framebuffer* Framebuffer::DepthTarget(PicoGL::Texture* texture) {
		// target = texture->is3D ? 0 : PicoGL::Constant::TEXTURE_2D
		return this;
		/*
		let currentFramebuffer = this.bindAndCaptureState();

		this.depthTexture = texture;
		this.depthTextureTarget = target;

		if (texture.is3D) {
			this.gl.framebufferTextureLayer(this.gl.DRAW_FRAMEBUFFER, CONSTANTS.DEPTH_ATTACHMENT, texture.texture, 0, target);
		}
		else {
			this.gl.framebufferTexture2D(this.gl.DRAW_FRAMEBUFFER, CONSTANTS.DEPTH_ATTACHMENT, target, texture.texture, 0);
		}

		this.restoreState(currentFramebuffer);

		return this;
		*/
	}

	/**
		Resize all currently attached textures.

		@method
		@param {number} [width=app.width] New width of the framebuffer.
		@param {number} [height=app.height] New height of the framebuffer.
		@return {Framebuffer} The Framebuffer object.
	*/
	Framebuffer* Framebuffer::Resize(int width, int height, int depth) {
		if (width == -1)
			width = Platform::GetWidth();
		if (height == -1)
			height = Platform::GetWidth();
		if (depth)
			depth = 1;

		return this;
		/*
		let currentFramebuffer = this.bindAndCaptureState();

		for (let i = 0; i < this.numColorTargets; ++i) {
			var texture = this.colorTextures[i];
			texture.resize(width, height, depth);
			if (texture.is3D) {
				this.gl.framebufferTextureLayer(this.gl.DRAW_FRAMEBUFFER, this.colorAttachments[i], texture.texture, 0, this.colorTextureTargets[i]);
			}
			else {
				this.gl.framebufferTexture2D(this.gl.DRAW_FRAMEBUFFER, this.colorAttachments[i], this.colorTextureTargets[i], texture.texture, 0);
			}
		}

		if (this.depthTexture) {
			this.depthTexture.resize(width, height, depth);
			if (this.depthTexture.is3D) {
				this.gl.framebufferTextureLayer(this.gl.DRAW_FRAMEBUFFER, CONSTANTS.DEPTH_ATTACHMENT, this.depthTexture.texture, 0, this.depthTextureTarget);
			}
			else {
				this.gl.framebufferTexture2D(this.gl.DRAW_FRAMEBUFFER, CONSTANTS.DEPTH_ATTACHMENT, this.depthTextureTarget, this.depthTexture.texture, 0);
			}
		}

		this.restoreState(currentFramebuffer);

		return this;
		*/
	}

	/**
		Delete this framebuffer.

		@method
		@return {Framebuffer} The Framebuffer object.
	*/
	Framebuffer::~Framebuffer() {
		/*
		if (this.framebuffer) {
			this.gl.deleteFramebuffer(this.framebuffer);
			this.framebuffer = null;
		}

		return this;
		*/
	}

	/**
		Bind as the draw framebuffer

		@method
		@ignore
		@return {Framebuffer} The Framebuffer object.
	*/
	Framebuffer* Framebuffer::BindForDraw() {
		return this;
		/*
		if (this.appState.drawFramebuffer != = this) {
			this.gl.bindFramebuffer(this.gl.DRAW_FRAMEBUFFER, this.framebuffer);
			this.appState.drawFramebuffer = this;
		}

		return this;
		*/
	}

	/**
		Bind as the read framebuffer

		@method
		@ignore
		@return {Framebuffer} The Framebuffer object.
	*/
	Framebuffer* Framebuffer::BindForRead() {
		return this;
		/*
		if (this.appState.readFramebuffer != = this) {
			this.gl.bindFramebuffer(this.gl.READ_FRAMEBUFFER, this.framebuffer);
			this.appState.readFramebuffer = this;
		}

		return this;
		*/
	}

	/**
		Bind for a framebuffer state update.
		Capture current binding so we can restore it later.

		@method
		@ignore
		@return {Framebuffer} The Framebuffer object.
	*/
	Framebuffer* Framebuffer::BindAndCaptureState() {
		return this;
		/*
		let currentFramebuffer = this.appState.drawFramebuffer;

		if (currentFramebuffer != = this) {
			this.gl.bindFramebuffer(this.gl.DRAW_FRAMEBUFFER, this.framebuffer);
		}

		return currentFramebuffer;
		*/
	}

	/**
		Bind restore previous binding after state update

		@method
		@ignore
		@return {Framebuffer} The Framebuffer object.
	*/
	Framebuffer* Framebuffer::RestoreState(Framebuffer* framebuffer) {
		return this;
		/*
		if (framebuffer != = this) {
			this.gl.bindFramebuffer(this.gl.DRAW_FRAMEBUFFER, framebuffer ? framebuffer.framebuffer : null);
		}

		return this;
		*/
	}


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

	Program::Program(State* state,
		const char* const* vsSource, int vsSourceLength,
		const char* const* fsSource, int fsSourceLength,
		const std::vector<const char*>& xformFeedbackVars)
	{
		Shader* vShader = new Shader(PicoGL::Constant::VERTEX_SHADER, vsSource, vsSourceLength);

		Shader* fShader = new Shader(PicoGL::Constant::FRAGMENT_SHADER, fsSource, fsSourceLength);

		CreateProgramInternal(state, vShader, fShader, true, true, xformFeedbackVars);
	}

	Program::Program(State* state, Shader* vShader, Shader* fShader, const std::vector<const char*>& xformFeedbackVars)
	{
		CreateProgramInternal(state, vShader, fShader, false, false, xformFeedbackVars);
	}

	void Program::CreateProgramInternal(State* state, Shader* vShader, Shader* fShader, bool ownVertexShader, bool ownFragmentShader, const std::vector<const char*>& xformFeedbackVars)
	{
		/*
		let program = gl.createProgram();
		gl.attachShader(program, vShader.shader);
		gl.attachShader(program, fShader.shader);
		if (xformFeebackVars) {
			gl.transformFeedbackVaryings(program, xformFeebackVars, gl.SEPARATE_ATTRIBS);
		}
		gl.linkProgram(program);

		if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
			console.error(gl.getProgramInfoLog(program));
		}

		if (ownVertexShader) {
			vShader.delete();
		}

		if (ownFragmentShader) {
			fShader.delete();
		}

		this.gl = gl;
		this.program = program;
		this.appState = appState;
		this.transformFeedback = !!xformFeebackVars;
		this.uniforms = {};
		this.uniformBlocks = {};
		this.uniformBlockCount = 0;
		this.samplers = {};
		this.samplerCount = 0;

		gl.useProgram(program);

		let numUniforms = gl.getProgramParameter(program, gl.ACTIVE_UNIFORMS);
		let textureUnit;

		for (i = 0; i < numUniforms; ++i) {
			let uniformInfo = gl.getActiveUniform(program, i);
			let uniformHandle = gl.getUniformLocation(this.program, uniformInfo.name);
			let UniformClass = null;
			let type = uniformInfo.type;
			let numElements = uniformInfo.size;

			switch (type) {
			case CONSTANTS.SAMPLER_2D:
			case CONSTANTS.INT_SAMPLER_2D:
			case CONSTANTS.UNSIGNED_INT_SAMPLER_2D:
			case CONSTANTS.SAMPLER_2D_SHADOW:
			case CONSTANTS.SAMPLER_2D_ARRAY:
			case CONSTANTS.INT_SAMPLER_2D_ARRAY:
			case CONSTANTS.UNSIGNED_INT_SAMPLER_2D_ARRAY:
			case CONSTANTS.SAMPLER_2D_ARRAY_SHADOW:
			case CONSTANTS.SAMPLER_CUBE:
			case CONSTANTS.INT_SAMPLER_CUBE:
			case CONSTANTS.UNSIGNED_INT_SAMPLER_CUBE:
			case CONSTANTS.SAMPLER_CUBE_SHADOW:
			case CONSTANTS.SAMPLER_3D:
			case CONSTANTS.INT_SAMPLER_3D:
			case CONSTANTS.UNSIGNED_INT_SAMPLER_3D:
				textureUnit = this.samplerCount++;
				this.samplers[uniformInfo.name] = textureUnit;
				this.gl.uniform1i(uniformHandle, textureUnit);
				break;
			case CONSTANTS.INT:
			case CONSTANTS.UNSIGNED_INT:
			case CONSTANTS.FLOAT:
				UniformClass = numElements > 1 ? MultiNumericUniform : SingleComponentUniform;
				break;
			case CONSTANTS.BOOL:
				UniformClass = numElements > 1 ? MultiBoolUniform : SingleComponentUniform;
				break;
			case CONSTANTS.FLOAT_VEC2:
			case CONSTANTS.INT_VEC2:
			case CONSTANTS.UNSIGNED_INT_VEC2:
			case CONSTANTS.FLOAT_VEC3:
			case CONSTANTS.INT_VEC3:
			case CONSTANTS.UNSIGNED_INT_VEC3:
			case CONSTANTS.FLOAT_VEC4:
			case CONSTANTS.INT_VEC4:
			case CONSTANTS.UNSIGNED_INT_VEC4:
				UniformClass = MultiNumericUniform;
				break;
			case CONSTANTS.BOOL_VEC2:
			case CONSTANTS.BOOL_VEC3:
			case CONSTANTS.BOOL_VEC4:
				UniformClass = MultiBoolUniform;
				break;
			case CONSTANTS.FLOAT_MAT2:
			case CONSTANTS.FLOAT_MAT3:
			case CONSTANTS.FLOAT_MAT4:
			case CONSTANTS.FLOAT_MAT2x3:
			case CONSTANTS.FLOAT_MAT2x4:
			case CONSTANTS.FLOAT_MAT3x2:
			case CONSTANTS.FLOAT_MAT3x4:
			case CONSTANTS.FLOAT_MAT4x2:
			case CONSTANTS.FLOAT_MAT4x3:
				UniformClass = MatrixUniform;
				break;
			default:
				console.error("Unrecognized type for uniform ", uniformInfo.name);
				break;
			}

			if (UniformClass) {
				this.uniforms[uniformInfo.name] = new UniformClass(gl, uniformHandle, type, numElements);
			}
		}

		let numUniformBlocks = gl.getProgramParameter(program, gl.ACTIVE_UNIFORM_BLOCKS);

		for (i = 0; i < numUniformBlocks; ++i) {
			let blockName = gl.getActiveUniformBlockName(this.program, i);
			let blockIndex = gl.getUniformBlockIndex(this.program, blockName);

			let uniformBlockBase = this.uniformBlockCount++;
			this.gl.uniformBlockBinding(this.program, blockIndex, uniformBlockBase);
			this.uniformBlocks[blockName] = uniformBlockBase;
		}

		gl.useProgram(null);
		*/
	}


	/**
		Delete this program.

		@method
		@return {Program} The Program object.
	*/
	Program::~Program() {
		/*
		if (this.program) {
			this.gl.deleteProgram(this.program);
			this.program = null;
		}

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
	Program* Program::Bind() {
		return this;
		/*
		if (this.appState.program != = this) {
			this.gl.useProgram(this.program);
			this.appState.program = this;
		}

		return this;
		*/
	}


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

	Texture::Texture(State* state, PicoGL::Constant target, const void* image, int width, int height, int depth, bool is3D, const Options& options)
	{
		/*
		let defaultType = options.format == = CONSTANTS.DEPTH_COMPONENT ? CONSTANTS.UNSIGNED_SHORT : CONSTANTS.UNSIGNED_BYTE;

		this.gl = gl;
		this.binding = binding;
		this.texture = null;
		this.width = -1;
		this.height = -1;
		this.depth = -1;
		this.type = options.type != = undefined ? options.type : defaultType;
		this.is3D = is3D;
		this.appState = appState;

		this.format = null;
		this.internalFormat = null;
		this.compressed = !!(TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[options.format] || TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[options.internalFormat]);

		if (this.compressed) {
			// For compressed textures, just need to provide one of format, internalFormat.
			// The other will be the same.
			this.format = options.format != = undefined ? options.format : options.internalFormat;
			this.internalFormat = options.internalFormat != = undefined ? options.internalFormat : options.format;
		}
		else {
			this.format = options.format != = undefined ? options.format : gl.RGBA;
			this.internalFormat = options.internalFormat != = undefined ? options.internalFormat : TEXTURE_FORMAT_DEFAULTS[this.type][this.format];
		}

		// -1 indicates unbound
		this.currentUnit = -1;

		// Sampling parameters
		let{
			minFilter = image ? gl.LINEAR_MIPMAP_NEAREST : gl.NEAREST,
			magFilter = image ? gl.LINEAR : gl.NEAREST,
			wrapS = gl.REPEAT,
			wrapT = gl.REPEAT,
			wrapR = gl.REPEAT,
			compareMode = gl.NONE,
			compareFunc = gl.LEQUAL,
			minLOD = null,
			maxLOD = null,
			baseLevel = null,
			maxLevel = null,
			flipY = false
		} = options;

		this.minFilter = minFilter;
		this.magFilter = magFilter;
		this.wrapS = wrapS;
		this.wrapT = wrapT;
		this.wrapR = wrapR;
		this.compareMode = compareMode;
		this.compareFunc = compareFunc;
		this.minLOD = minLOD;
		this.maxLOD = maxLOD;
		this.baseLevel = baseLevel;
		this.maxLevel = maxLevel;
		this.flipY = flipY;
		this.mipmaps = (minFilter == = gl.LINEAR_MIPMAP_NEAREST || minFilter == = gl.LINEAR_MIPMAP_LINEAR);

		this.resize(width, height, depth);

		if (image) {
			this.data(image);
		}

		*/
	}
	/**
		Re-allocate texture storage.

		@method
		@param {number} width Image width.
		@param {number} height Image height.
		@param {number} [depth] Image depth or number of images. Required when passing 3D or texture array data.
		@return {Texture} The Texture object.
	*/

	Texture* Texture::Resize(int width, int height, int depth) {
		return this;
		/*
		depth = depth || 0;

		if (width == = this.width && height == = this.height && depth == = this.depth) {
			return this;
		}

		this.gl.deleteTexture(this.texture);
		if (this.currentUnit != = -1) {
			this.appState.textures[this.currentUnit] = null;
		}

		this.texture = this.gl.createTexture();
		this.bind(Math.max(this.currentUnit, 0));

		this.width = width;
		this.height = height;
		this.depth = depth;

		this.gl.texParameteri(this.binding, this.gl.TEXTURE_MIN_FILTER, this.minFilter);
		this.gl.texParameteri(this.binding, this.gl.TEXTURE_MAG_FILTER, this.magFilter);
		this.gl.texParameteri(this.binding, this.gl.TEXTURE_WRAP_S, this.wrapS);
		this.gl.texParameteri(this.binding, this.gl.TEXTURE_WRAP_T, this.wrapT);
		this.gl.texParameteri(this.binding, this.gl.TEXTURE_WRAP_R, this.wrapR);
		this.gl.texParameteri(this.binding, this.gl.TEXTURE_COMPARE_FUNC, this.compareFunc);
		this.gl.texParameteri(this.binding, this.gl.TEXTURE_COMPARE_MODE, this.compareMode);
		this.gl.pixelStorei(this.gl.UNPACK_FLIP_Y_WEBGL, this.flipY);
		if (this.minLOD != = null) {
			this.gl.texParameterf(this.binding, this.gl.TEXTURE_MIN_LOD, this.minLOD);
		}
		if (this.maxLOD != = null) {
			this.gl.texParameterf(this.binding, this.gl.TEXTURE_MAX_LOD, this.maxLOD);
		}
		if (this.baseLevel != = null) {
			this.gl.texParameteri(this.binding, this.gl.TEXTURE_BASE_LEVEL, this.baseLevel);
		}

		if (this.maxLevel != = null) {
			this.gl.texParameteri(this.binding, this.gl.TEXTURE_MAX_LEVEL, this.maxLevel);
		}

		let levels;
		if (this.is3D) {
			if (this.mipmaps) {
				levels = Math.floor(Math.log2(Math.max(Math.max(this.width, this.height), this.depth))) + 1;
			}
			else {
				levels = 1;
			}
			this.gl.texStorage3D(this.binding, levels, this.internalFormat, this.width, this.height, this.depth);
		}
		else {
			if (this.mipmaps) {
				levels = Math.floor(Math.log2(Math.max(this.width, this.height))) + 1;
			}
			else {
				levels = 1;
			}
			this.gl.texStorage2D(this.binding, levels, this.internalFormat, this.width, this.height);
		}

		return this;
		*/
	}

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
	Texture* Texture::Data(void* data, unsigned int dataLength) {
		return this;
		/*
		if (!Array.isArray(data)) {
			DUMMY_ARRAY[0] = data;
			data = DUMMY_ARRAY;
		}

		let numLevels = this.mipmaps ? data.length : 1;
		let width = this.width;
		let height = this.height;
		let depth = this.depth;
		let generateMipmaps = this.mipmaps && data.length == = 1;
		let i;

		this.bind(Math.max(this.currentUnit, 0));

		if (this.compressed) {
			if (this.is3D) {
				for (i = 0; i < numLevels; ++i) {
					this.gl.compressedTexSubImage3D(this.binding, i, 0, 0, 0, width, height, depth, this.format, data[i]);
					width = Math.max(width >> 1, 1);
					height = Math.max(height >> 1, 1);
					depth = Math.max(depth >> 1, 1);
				}
			}
			else {
				for (i = 0; i < numLevels; ++i) {
					this.gl.compressedTexSubImage2D(this.binding, i, 0, 0, width, height, this.format, data[i]);
					width = Math.max(width >> 1, 1);
					height = Math.max(height >> 1, 1);
				}
			}
		}
		else if (this.is3D) {
			for (i = 0; i < numLevels; ++i) {
				this.gl.texSubImage3D(this.binding, i, 0, 0, 0, width, height, depth, this.format, this.type, data[i]);
				width = Math.max(width >> 1, 1);
				height = Math.max(height >> 1, 1);
				depth = Math.max(depth >> 1, 1);
			}
		}
		else {
			for (i = 0; i < numLevels; ++i) {
				this.gl.texSubImage2D(this.binding, i, 0, 0, width, height, this.format, this.type, data[i]);
				width = Math.max(width >> 1, 1);
				height = Math.max(height >> 1, 1);
			}
		}

		if (generateMipmaps) {
			this.gl.generateMipmap(this.binding);
		}

		return this;
		*/
	}

	/**
		Delete this texture.

		@method
		@return {Texture} The Texture object.
	*/
	Texture::~Texture() {
		/*
		if (this.texture) {
			this.gl.deleteTexture(this.texture);
			this.texture = null;

			if (this.currentUnit != = -1 && this.appState.textures[this.currentUnit] == = this) {
				this.appState.textures[this.currentUnit] = null;
				this.currentUnit = -1;
			}
		}

		return this;
		*/
	}

	/**
		Bind this texture to a texture unit.

		@method
		@ignore
		@return {Texture} The Texture object.
	*/
	Texture* Texture::Bind(int unit) {
		return this;
		/*
		let currentTexture = this.appState.textures[unit];

		if (currentTexture != = this) {
			if (currentTexture) {
				currentTexture.currentUnit = -1;
			}

			if (this.currentUnit != = -1) {
				this.appState.textures[this.currentUnit] = null;
			}

			this.gl.activeTexture(this.gl.TEXTURE0 + unit);
			this.gl.bindTexture(this.binding, this.texture);

			this.appState.textures[unit] = this;
			this.currentUnit = unit;
		}

		return this;
		*/
	}


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

	Timer::Timer()
	{
	}

	Timer::~Timer()
	{
	}


	/**
		Tranform feedback object.

		@class
		@prop {WebGLRenderingContext} gl The WebGL context.
		@prop {WebGLTransformFeedback} transformFeedback Transform feedback object.
		@prop {Object} appState Tracked GL state.
	*/
	TransformFeedback::TransformFeedback(State* state)
	{
		/*
		this.gl = gl;
		this.transformFeedback = gl.createTransformFeedback();
		this.appState = appState;

		// TODO(Tarek): Need to rebind buffers due to bug in ANGLE.
		// Remove this when that's fixed.
		this.angleBugBuffers = [];
		*/
	}

	/**
		Bind a feedback buffer to capture transform output.

		@method
		@param {number} index Index of transform feedback varying to capture.
		@param {VertexBuffer} buffer Buffer to record output into.
		@return {TransformFeedback} The TransformFeedback object.
	*/
	TransformFeedback* TransformFeedback::FeedbackBuffer(int index, VertexBuffer* buffer) {
		return this;
		/*
		this.gl.bindTransformFeedback(this.gl.TRANSFORM_FEEDBACK, this.transformFeedback);
		this.gl.bindBufferBase(this.gl.TRANSFORM_FEEDBACK_BUFFER, index, buffer.buffer);
		this.gl.bindTransformFeedback(this.gl.TRANSFORM_FEEDBACK, null);
		this.gl.bindBufferBase(this.gl.TRANSFORM_FEEDBACK_BUFFER, index, null);

		this.angleBugBuffers[index] = buffer;

		return this;
		*/
	}

	/**
		Delete this transform feedback.

		@method
		@return {TransformFeedback} The TransformFeedback object.
	*/
	TransformFeedback::~TransformFeedback() {
		/*
		if (this.transformFeedback) {
			this.gl.deleteTransformFeedback(this.transformFeedback);
			this.transformFeedback = null;
		}

		return this;
		*/
	}

	/**
		Bind this transform feedback.

		@method
		@ignore
		@return {TransformFeedback} The TransformFeedback object.
	*/
	TransformFeedback* TransformFeedback::Bind() {
		return this;
		/*
		if (this.appState.transformFeedback != = this) {
			this.gl.bindTransformFeedback(this.gl.TRANSFORM_FEEDBACK, this.transformFeedback);

			for (let i = 0, len = this.angleBugBuffers.length; i < len; ++i) {
				this.gl.bindBufferBase(this.gl.TRANSFORM_FEEDBACK_BUFFER, i, this.angleBugBuffers[i].buffer);
			}

			this.appState.transformFeedback = this;
		}

		return this;
		*/
	}


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
	UniformBuffer::UniformBuffer(State* state, const std::vector<PicoGL::Constant>& layout, PicoGL::Constant usage)
	{
#if 0
		this.gl = gl;
		this.buffer = gl.createBuffer();
		this.dataViews = {};
		this.offsets = new Array(layout.length);
		this.sizes = new Array(layout.length);
		this.types = new Array(layout.length);
		this.size = 0;
		this.usage = usage;
		this.appState = appState;

		// -1 indicates unbound
		this.currentBase = -1;

		for (let i = 0, len = layout.length; i < len; ++i) {
			let type = layout[i];
			switch (type) {
			case CONSTANTS.FLOAT:
			case CONSTANTS.INT:
			case CONSTANTS.UNSIGNED_INT:
			case CONSTANTS.BOOL:
				this.offsets[i] = this.size;
				this.sizes[i] = 1;

				if (type == = CONSTANTS.INT) {
					this.types[i] = CONSTANTS.INT;
				}
				else if (this.type == = CONSTANTS.UNSIGNED_INT) {
					this.types[i] = CONSTANTS.UNSIGNED_INT;
				}
				else {
					this.types[i] = CONSTANTS.FLOAT;
				}

				this.size++;
				break;
			case CONSTANTS.FLOAT_VEC2:
			case CONSTANTS.INT_VEC2:
			case CONSTANTS.UNSIGNED_INT_VEC2:
			case CONSTANTS.BOOL_VEC2:
				this.size += this.size % 2;
				this.offsets[i] = this.size;
				this.sizes[i] = 2;

				if (type == = CONSTANTS.INT_VEC2) {
					this.types[i] = CONSTANTS.INT;
				}
				else if (this.type == = CONSTANTS.UNSIGNED_INT_VEC2) {
					this.types[i] = CONSTANTS.UNSIGNED_INT;
				}
				else {
					this.types[i] = CONSTANTS.FLOAT;
				}

				this.size += 2;
				break;
			case CONSTANTS.FLOAT_VEC3:
			case CONSTANTS.INT_VEC3:
			case CONSTANTS.UNSIGNED_INT_VEC3:
			case CONSTANTS.BOOL_VEC3:
			case CONSTANTS.FLOAT_VEC4:
			case CONSTANTS.INT_VEC4:
			case CONSTANTS.UNSIGNED_INT_VEC4:
			case CONSTANTS.BOOL_VEC4:
				this.size += (4 - this.size % 4) % 4;
				this.offsets[i] = this.size;
				this.sizes[i] = 4;

				if (type == = CONSTANTS.INT_VEC4 || type == = CONSTANTS.INT_VEC3) {
					this.types[i] = CONSTANTS.INT;
				}
				else if (this.type == = CONSTANTS.UNSIGNED_INT_VEC4 || this.type == = CONSTANTS.UNSIGNED_INT_VEC3) {
					this.types[i] = CONSTANTS.UNSIGNED_INT;
				}
				else {
					this.types[i] = CONSTANTS.FLOAT;
				}

				this.size += 4;
				break;
			case CONSTANTS.FLOAT_MAT2:
			case CONSTANTS.FLOAT_MAT2x3:
			case CONSTANTS.FLOAT_MAT2x4:
				this.size += (4 - this.size % 4) % 4;
				this.offsets[i] = this.size;
				this.sizes[i] = 8;
				this.types[i] = CONSTANTS.FLOAT;

				this.size += 8;
				break;
			case CONSTANTS.FLOAT_MAT3:
			case CONSTANTS.FLOAT_MAT3x2:
			case CONSTANTS.FLOAT_MAT3x4:
				this.size += (4 - this.size % 4) % 4;
				this.offsets[i] = this.size;
				this.sizes[i] = 12;
				this.types[i] = CONSTANTS.FLOAT;

				this.size += 12;
				break;
			case CONSTANTS.FLOAT_MAT4:
			case CONSTANTS.FLOAT_MAT4x2:
			case CONSTANTS.FLOAT_MAT4x3:
				this.size += (4 - this.size % 4) % 4;
				this.offsets[i] = this.size;
				this.sizes[i] = 16;
				this.types[i] = CONSTANTS.FLOAT;

				this.size += 16;
				break;
			default:
				console.error("Unsupported type for uniform buffer.");
			}
		}

		this.size += (4 - this.size % 4) % 4;

		this.data = new Float32Array(this.size);
		this.dataViews[CONSTANTS.FLOAT] = this.data;
		this.dataViews[CONSTANTS.INT] = new Int32Array(this.data.buffer);
		this.dataViews[CONSTANTS.UNSIGNED_INT] = new Uint32Array(this.data.buffer);


		this.gl.bindBuffer(this.gl.UNIFORM_BUFFER, this.buffer);
		this.gl.bufferData(this.gl.UNIFORM_BUFFER, this.size * 4, this.usage);
		this.gl.bindBuffer(this.gl.UNIFORM_BUFFER, null);

#endif
	}

	/**
		Update data for a given item in the buffer. NOTE: Data is not
		sent the the GPU until the update() method is called!

		@method
		@param {number} index Index in the layout of item to set.
		@param {ArrayBufferView} value Value to store at the layout location.
		@return {UniformBuffer} The UniformBuffer object.
	*/

	/**
		Send stored buffer data to the GPU.

		@method
		@param {number} [index] Index in the layout of item to send to the GPU. If ommited, entire buffer is sent.
		@return {UniformBuffer} The UniformBuffer object.
	*/
	UniformBuffer* UniformBuffer::Update(int index) {
		return this;
		/*
		let data;
		let offset;
		if (index == = undefined) {
			data = this.data;
			offset = 0;
		}
		else {
			let begin = this.offsets[index];
			let end = begin + this.sizes[index];
			data = this.data.subarray(begin, end);
			offset = begin * 4;
		}

		this.gl.bindBuffer(this.gl.UNIFORM_BUFFER, this.buffer);
		this.gl.bufferSubData(this.gl.UNIFORM_BUFFER, offset, data);
		this.gl.bindBuffer(this.gl.UNIFORM_BUFFER, null);

		return this;
		*/
	}

	/**
		Delete this uniform buffer.

		@method
		@return {UniformBuffer} The UniformBuffer object.
	*/
	UniformBuffer::~UniformBuffer() {
		/*
		if (this.buffer) {
			this.gl.deleteBuffer(this.buffer);
			this.buffer = null;

			if (this.currentBase != = -1 && this.appState.uniformBuffers[this.currentBase] == = this) {
				this.appState.uniformBuffers[this.currentBase] = null;
			}
		}

		return this;
		*/
	}

	/**
		Bind this uniform buffer to the given base.

		@method
		@ignore
		@return {UniformBuffer} The UniformBuffer object.
	*/
	UniformBuffer* UniformBuffer::Bind(int base) {
		return this;
		/*
		let currentBuffer = this.appState.uniformBuffers[base];

		if (currentBuffer != = this) {

			if (currentBuffer) {
				currentBuffer.currentBase = -1;
			}

			if (this.currentBase != = -1) {
				this.appState.uniformBuffers[this.currentBase] = null;
			}

			this.gl.bindBufferBase(this.gl.UNIFORM_BUFFER, base, this.buffer);

			this.appState.uniformBuffers[base] = this;
			this.currentBase = base;
		}

		return this;
		*/
	}

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

	VertexArray::VertexArray(State* state)
	{
		/*
		this.gl = gl;
		this.vertexArray = gl.createVertexArray();
		this.appState = appState;
		this.numElements = 0;
		this.indexType = null;
		this.instancedBuffers = 0;
		this.indexed = false;
		this.numInstances = 0;
		*/
	}

	/**
		Bind an per-vertex attribute buffer to this vertex array.

		@method
		@param {number} attributeIndex The attribute location to bind to.
		@param {VertexBuffer} vertexBuffer The VertexBuffer to bind.
		@return {VertexArray} The VertexArray object.
	*/
	VertexArray* VertexArray::VertexAttributeBuffer(int attributeIndex, VertexBuffer* vertexBuffer) {
		this->AttributeBuffer(attributeIndex, vertexBuffer, false, false, false);

		return this;
	}

	/**
		Bind an per-instance attribute buffer to this vertex array.

		@method
		@param {number} attributeIndex The attribute location to bind to.
		@param {VertexBuffer} vertexBuffer The VertexBuffer to bind.
		@return {VertexArray} The VertexArray object.
	*/
	VertexArray* VertexArray::InstanceAttributeBuffer(int attributeIndex, VertexBuffer* vertexBuffer) {
		this->AttributeBuffer(attributeIndex, vertexBuffer, true, false, false);

		return this;
	}

	/**
		Bind an per-vertex integer attribute buffer to this vertex array.
		Note that this refers to the attribute in the shader being an integer,
		not the data stored in the vertex buffer.

		@method
		@param {number} attributeIndex The attribute location to bind to.
		@param {VertexBuffer} vertexBuffer The VertexBuffer to bind.
		@return {VertexArray} The VertexArray object.
	*/
	VertexArray* VertexArray::VertexIntegerAttributeBuffer(int attributeIndex, VertexBuffer* vertexBuffer) {
		this->AttributeBuffer(attributeIndex, vertexBuffer, false, true, false);

		return this;
	}

	/**
		Bind an per-instance integer attribute buffer to this vertex array.
		Note that this refers to the attribute in the shader being an integer,
		not the data stored in the vertex buffer.

		@method
		@param {number} attributeIndex The attribute location to bind to.
		@param {VertexBuffer} vertexBuffer The VertexBuffer to bind.
		@return {VertexArray} The VertexArray object.
	*/
	VertexArray* VertexArray::InstanceIntegerAttributeBuffer(int attributeIndex, VertexBuffer* vertexBuffer) {
		this->AttributeBuffer(attributeIndex, vertexBuffer, true, true, false);

		return this;
	}

	/**
		Bind an per-vertex normalized attribute buffer to this vertex array.
		Integer data in the vertex buffer will be normalized to [-1.0, 1.0] if
		signed, [0.0, 1.0] if unsigned.

		@method
		@param {number} attributeIndex The attribute location to bind to.
		@param {VertexBuffer} vertexBuffer The VertexBuffer to bind.
		@return {VertexArray} The VertexArray object.
	*/
	VertexArray* VertexArray::VertexNormalizedAttributeBuffer(int attributeIndex, VertexBuffer* vertexBuffer) {
		this->AttributeBuffer(attributeIndex, vertexBuffer, false, false, true);

		return this;
	}

	/**
		Bind an per-instance normalized attribute buffer to this vertex array.
		Integer data in the vertex buffer will be normalized to [-1.0, 1.0] if
		signed, [0.0, 1.0] if unsigned.

		@method
		@param {number} attributeIndex The attribute location to bind to.
		@param {VertexBuffer} vertexBuffer The VertexBuffer to bind.
		@return {VertexArray} The VertexArray object.
	*/
	VertexArray* VertexArray::InstanceNormalizedAttributeBuffer(int attributeIndex, VertexBuffer* vertexBuffer) {
		this->AttributeBuffer(attributeIndex, vertexBuffer, true, false, true);

		return this;
	}

	/**
		Bind an index buffer to this vertex array.

		@method
		@param {VertexBuffer} vertexBuffer The VertexBuffer to bind.
		@return {VertexArray} The VertexArray object.
	*/
	VertexArray* VertexArray::IndexBuffer(VertexBuffer* vertexBuffer) {
		return this;
		/*
		this.gl.bindVertexArray(this.vertexArray);
		this.gl.bindBuffer(vertexBuffer.binding, vertexBuffer.buffer);

		this.numElements = vertexBuffer.numItems * 3;
		this.indexType = vertexBuffer.type;
		this.indexed = true;

		this.gl.bindVertexArray(null);
		this.gl.bindBuffer(vertexBuffer.binding, null);

		return this;
		*/
	}

	/**
		Delete this vertex array.

		@method
		@return {VertexArray} The VertexArray object.
	*/
	VertexArray::~VertexArray() {
		/*
		if (this.vertexArray) {
			this.gl.deleteVertexArray(this.vertexArray);
			this.vertexArray = null;
		}
		this.gl.bindVertexArray(null);

		return this;
		*/
	}

	/**
		Bind this vertex array.

		@method
		@ignore
		@return {VertexArray} The VertexArray object.
	*/
	VertexArray* VertexArray::Bind() {
		return this;
		/*
		if (this.appState.vertexArray != = this) {
			this.gl.bindVertexArray(this.vertexArray);
			this.appState.vertexArray = this;
		}

		return this;
		*/
	}

	/**
		Attach an attribute buffer

		@method
		@ignore
		@return {VertexArray} The VertexArray object.
	*/
	VertexArray* VertexArray::AttributeBuffer(int attributeIndex, VertexBuffer* vertexBuffer, bool instanced, bool integer, bool normalized) {
		return this;
		/*
		this.gl.bindVertexArray(this.vertexArray);
		this.gl.bindBuffer(vertexBuffer.binding, vertexBuffer.buffer);

		let numColumns = vertexBuffer.numColumns;

		for (let i = 0; i < numColumns; ++i) {
			if (integer) {
				this.gl.vertexAttribIPointer(
					attributeIndex + i,
					vertexBuffer.itemSize,
					vertexBuffer.type,
					numColumns * vertexBuffer.itemSize * CONSTANTS.TYPE_SIZE[vertexBuffer.type],
					i * vertexBuffer.itemSize * CONSTANTS.TYPE_SIZE[vertexBuffer.type]);
			}
			else {
				this.gl.vertexAttribPointer(
					attributeIndex + i,
					vertexBuffer.itemSize,
					vertexBuffer.type,
					normalized,
					numColumns * vertexBuffer.itemSize * CONSTANTS.TYPE_SIZE[vertexBuffer.type],
					i * vertexBuffer.itemSize * CONSTANTS.TYPE_SIZE[vertexBuffer.type]);
			}

			if (instanced) {
				this.gl.vertexAttribDivisor(attributeIndex + i, 1);
			}

			this.gl.enableVertexAttribArray(attributeIndex + i);
		}

		this.instanced = this.instanced || instanced;

		if (instanced) {
			this.numInstances = vertexBuffer.numItems;
		}
		else {
			this.numElements = this.numElements || vertexBuffer.numItems;
		}

		this.gl.bindVertexArray(null);
		this.gl.bindBuffer(vertexBuffer.binding, null);

		return this;
		*/
	}

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
	VertexBuffer::VertexBuffer(State* state, PicoGL::Constant type, int itemSize, const void* data, unsigned int dataLength, PicoGL::Constant usage, bool indexType)
	{
		/*
		let numColumns;
		switch (type) {
		case CONSTANTS.FLOAT_MAT4:
		case CONSTANTS.FLOAT_MAT4x2:
		case CONSTANTS.FLOAT_MAT4x3:
			numColumns = 4;
			break;
		case CONSTANTS.FLOAT_MAT3:
		case CONSTANTS.FLOAT_MAT3x2:
		case CONSTANTS.FLOAT_MAT3x4:
			numColumns = 3;
			break;
		case CONSTANTS.FLOAT_MAT2:
		case CONSTANTS.FLOAT_MAT2x3:
		case CONSTANTS.FLOAT_MAT2x4:
			numColumns = 2;
			break;
		default:
			numColumns = 1;
		}

		switch (type) {
		case CONSTANTS.FLOAT_MAT4:
		case CONSTANTS.FLOAT_MAT3x4:
		case CONSTANTS.FLOAT_MAT2x4:
			itemSize = 4;
			type = CONSTANTS.FLOAT;
			break;
		case CONSTANTS.FLOAT_MAT3:
		case CONSTANTS.FLOAT_MAT4x3:
		case CONSTANTS.FLOAT_MAT2x3:
			itemSize = 3;
			type = CONSTANTS.FLOAT;
			break;
		case CONSTANTS.FLOAT_MAT2:
		case CONSTANTS.FLOAT_MAT3x2:
		case CONSTANTS.FLOAT_MAT4x2:
			itemSize = 2;
			type = CONSTANTS.FLOAT;
			break;
		}

		let dataLength;
		if (typeof data == = "number") {
			dataLength = data;
			data *= CONSTANTS.TYPE_SIZE[type];
		}
		else {
			dataLength = data.length;
		}

		this.gl = gl;
		this.buffer = gl.createBuffer();
		this.appState = appState;
		this.type = type;
		this.itemSize = itemSize;
		this.numItems = dataLength / (itemSize * numColumns);
		this.numColumns = numColumns;
		this.usage = usage;
		this.indexArray = !!indexArray;
		this.binding = this.indexArray ? gl.ELEMENT_ARRAY_BUFFER : gl.ARRAY_BUFFER;

		gl.bindBuffer(this.binding, this.buffer);
		gl.bufferData(this.binding, data, this.usage);
		gl.bindBuffer(this.binding, null);
		*/
	}

	/**
		Update data in this buffer. NOTE: the data must fit
		the originally-allocated buffer!

		@method
		@param {VertexBufferView} data Data to store in the buffer.
		@return {VertexBuffer} The VertexBuffer object.
	*/
	VertexBuffer* VertexBuffer::Data(void* data, unsigned int dataLength) {
		return this;
		/*
		// Don't want to update vertex array bindings
		let currentVertexArray = this.appState.vertexArray;
		if (currentVertexArray) {
			this.gl.bindVertexArray(null);
		}

		this.gl.bindBuffer(this.binding, this.buffer);
		this.gl.bufferSubData(this.binding, 0, data);
		this.gl.bindBuffer(this.binding, null);

		if (currentVertexArray) {
			this.gl.bindVertexArray(currentVertexArray.vertexArray);
		}

		return this;
		*/
	}

	/**
		Delete this array buffer.

		@method
		@return {VertexBuffer} The VertexBuffer object.
	*/
	VertexBuffer::~VertexBuffer() {
		/*
		if (this.buffer) {
			this.gl.deleteBuffer(this.buffer);
			this.buffer = null;
		}

		return this;
		*/
	}


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
	State::State
	(
		Program* program,
		VertexArray* vertexArray,
		TransformFeedback* transformFeedback,
		int activeTexture,
		std::vector<Texture*> textures,
		std::vector<UniformBuffer*> uniformBuffers,
		std::vector<int> freeUniformBufferBases,
		Framebuffer* drawFramebuffer,
		Framebuffer* readFramebuffer
	)
	{
		this->program = program;
		this->vertexArray = vertexArray;
		this->transformFeedback = transformFeedback;
		this->activeTexture = activeTexture;
		this->textures = textures;
		this->uniformBuffers = uniformBuffers;
		this->freeUniformBufferBases = freeUniformBufferBases;
		this->drawFramebuffer = drawFramebuffer;
		this->readFramebuffer = readFramebuffer;
	}

	State::~State()
	{
	}



	App::App(const Options& options)
	{
		this->width = Platform::GetWidth();
		this->height = Platform::GetHeight();
		this->viewportX = 0;
		this->viewportY = 0;
		this->viewportWidth = 0;
		this->viewportHeight = 0;
		this->currentDrawCalls = nullptr;
		this->emptyFragmentShader = nullptr;

		glGetIntegerv(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS, &WEBGL_INFO[PicoGL::Constant::MAX_TEXTURE_UNITS]);
		glGetIntegerv(GL_MAX_UNIFORM_BUFFER_BINDINGS, &WEBGL_INFO[PicoGL::Constant::MAX_UNIFORM_BUFFERS]);

		this->state = State
		(
			nullptr,
			nullptr,
			nullptr,
			-1,
			std::vector<Texture*>(WEBGL_INFO[PicoGL::Constant::MAX_TEXTURE_UNITS]),
			std::vector<UniformBuffer*>(WEBGL_INFO[PicoGL::Constant::MAX_UNIFORM_BUFFERS]),
			std::vector<int>(),
			nullptr,
			nullptr
		);

		this->clearBits = GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT;

		this->cpuTime = 0;
		this->gpuTime = 0;

		// Extensions
		this->floatRenderTargetsEnabled = false;
		this->linearFloatTexturesEnabled = false;
		this->s3tcTexturesEnabled = false;
		this->s3tcSRGBTexturesEnabled = false;
		this->etcTexturesEnabled = false;
		this->astcTexturesEnabled = false;
		this->pvrtcTexturesEnabled = false;

		this->viewport = IVector4(0, 0, this->width, this->height);
	}

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
	App* App::ColorMask(bool r, bool g, bool b, bool a)
	{
		glColorMask(r, g, b, a);

		return this;
	}

	/**
		Set the clear color.

		@method
		@param {number} r Red channel.
		@param {number} g Green channel.
		@param {number} b Blue channel.
		@param {number} a Alpha channel.
		@return {App} The App object.
	*/
	App* App::ClearColor(float r, float g, float b, float a)
	{
		glClearColor(r, g, b, a);

		return this;
	}

	/**
		Set the clear mask bits to use when calling clear().
		E.g. app.clearMask(PicoGL.COLOR_BUFFER_BIT).

		@method
		@param {GLEnum} mask Bit mask of buffers to clear.
		@return {App} The App object.
	*/
	App* App::ClearMask(int mask)
	{
		this->clearBits = mask;

		return this;
	}

	/**
		Clear the canvas

		@method
		@return {App} The App object.
	*/
	App* App::Clear()
	{
		glClear(this->clearBits);

		return this;
	}

	/**
		Bind a draw framebuffer to the WebGL context.

		@method
		@param {Framebuffer} framebuffer The Framebuffer object to bind.
		@see Framebuffer
		@return {App} The App object.
	*/
	App* App::DrawFramebuffer(Framebuffer* framebuffer)
	{
		framebuffer->BindForDraw();

		return this;
	}

	/**
		Bind a read framebuffer to the WebGL context.

		@method
		@param {Framebuffer} framebuffer The Framebuffer object to bind.
		@see Framebuffer
		@return {App} The App object.
	*/
	App* App::ReadFramebuffer(Framebuffer* framebuffer)
	{
		framebuffer->BindForRead();

		return this;
	}

	/**
		Switch back to the default framebuffer for drawing (i.e. draw to the screen).
		Note that this method resets the viewport to match the default framebuffer.

		@method
		@return {App} The App object.
	*/
	App* App::DefaultDrawFramebuffer()
	{
		if (this->state.drawFramebuffer != nullptr) {
			glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
			this->state.drawFramebuffer = nullptr;
		}

		return this;
	}

	/**
		Switch back to the default framebuffer for reading (i.e. read from the screen).

		@method
		@return {App} The App object.
	*/
	App* App::DefaultReadFramebuffer()
	{
		if (this->state.readFramebuffer != nullptr) {
			glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);
			this->state.readFramebuffer = nullptr;
		}

		return this;
	}

	/**
		Set the depth range.

		@method
		@param {number} near Minimum depth value.
		@param {number} far Maximum depth value.
		@return {App} The App object.
	*/
	App* App::DepthRange(float near, float far)
	{
		glDepthRange(near, far);

		return this;
	}

	/**
		Enable depth testing.

		@method
		@return {App} The App object.
	*/
	App* App::DepthTest() {
		glEnable(GL_DEPTH_TEST);

		return this;
	}

	/**
		Disable depth testing.

		@method
		@return {App} The App object.
	*/
	App* App::NoDepthTest() {
		glDisable(GL_DEPTH_TEST);

		return this;
	}

	/**
		Enable or disable writing to the depth buffer.

		@method
		@param {Boolean} mask The depth mask.
		@return {App} The App object.
	*/
	App* App::DepthMask(bool mask) {
		glDepthMask(mask);

		return this;
	}

	/**
		Set the depth test function. E.g. app.depthFunc(PicoGL.LEQUAL).

		@method
		@param {GLEnum} func The depth testing function to use.
		@return {App} The App object.
	*/
	App* App::DepthFunc(PicoGL::Constant func) {
		glDepthFunc(GetGLEnum(func));

		return this;
	}

	/**
		Enable blending.

		@method
		@return {App} The App object.
	*/
	App* App::Blend() {
		glEnable(GL_BLEND);

		return this;
	}

	/**
		Disable blending

		@method
		@return {App} The App object.
	*/
	App* App::NoBlend() {
		glDisable(GL_BLEND);

		return this;
	}

	/**
		Set the blend function. E.g. app.blendFunc(PicoGL.ONE, PicoGL.ONE_MINUS_SRC_ALPHA).

		@method
		@param {GLEnum} src The source blending weight.
		@param {GLEnum} dest The destination blending weight.
		@return {App} The App object.
	*/
	App* App::BlendFunc(PicoGL::Constant src, PicoGL::Constant dest) {
		glBlendFunc(GetGLEnum(src), GetGLEnum(dest));

		return this;
	}

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
	App* App::BlendFuncSeparate(PicoGL::Constant csrc, PicoGL::Constant cdest, PicoGL::Constant asrc, PicoGL::Constant adest) {
		glBlendFuncSeparate(GetGLEnum(csrc), GetGLEnum(cdest), GetGLEnum(asrc), GetGLEnum(adest));

		return this;
	}

	/**
		Enable stencil testing.
		NOTE: Only works if { stencil: true } passed as a
		context attribute when creating the App!

		@method
		@return {App} The App object.
	*/
	App* App::StencilTest() {
		glEnable(GL_STENCIL_TEST);

		return this;
	}

	/**
		Disable stencil testing.

		@method
		@return {App} The App object.
	*/
	App* App::NoStencilTest() {
		glDisable(GL_STENCIL_TEST);

		return this;
	}


	/**
		Enable scissor testing.

		@method
		@return {App} The App object.
	*/
	App* App::scissorTest() {
		glEnable(GL_SCISSOR_TEST);

		return this;
	}

	/**
		Disable scissor testing.

		@method
		@return {App} The App object.
	*/
	App* App::NoScissorTest() {
		glDisable(GL_SCISSOR_TEST);

		return this;
	}

	/**
		Define the scissor box.

		@method
		@return {App} The App object.
	*/
	App* App::Scissor(int x, int y, int width, int height) {
		glScissor(x, y, width, height);

		return this;
	}

	/**
		Set the bitmask to use for tested stencil values.
		E.g. app.stencilMask(0xFF).
		NOTE: Only works if { stencil: true } passed as a
		context attribute when creating the App!

		@method
		@param {number} mask The mask value.
		@return {App} The App object.

	*/
	App* App::StencilMask(int mask) {
		glStencilMask(mask);

		return this;
	}

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
	App* App::StencilMaskSeparate(PicoGL::Constant face, int mask) {
		glStencilMaskSeparate(GetGLEnum(face), mask);

		return this;
	}

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
	App* App::StencilFunc(PicoGL::Constant func, int ref, int mask) {
		glStencilFunc(GetGLEnum(func), ref, mask);

		return this;
	}

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
	App* App::StencilFuncSeparate(PicoGL::Constant face, PicoGL::Constant func, int ref, int mask) {
		glStencilFuncSeparate(GetGLEnum(face), GetGLEnum(func), ref, mask);

		return this;
	}

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
	App* App::StencilOp(PicoGL::Constant stencilFail, PicoGL::Constant depthFail, PicoGL::Constant pass) {
		glStencilOp(GetGLEnum(stencilFail), GetGLEnum(depthFail), GetGLEnum(pass));

		return this;
	}

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
	App* App::StencilOpSeparate(PicoGL::Constant face, PicoGL::Constant stencilFail, PicoGL::Constant depthFail, PicoGL::Constant pass) {
		glStencilOpSeparate(GetGLEnum(face), GetGLEnum(stencilFail), GetGLEnum(depthFail), GetGLEnum(pass));

		return this;
	}

	/**
		Enable rasterization step.

		@method
		@return {App} The App object.
	*/
	App* App::Rasterize() {
		glDisable(GL_RASTERIZER_DISCARD);

		return this;
	}

	/**
		Disable rasterization step.

		@method
		@return {App} The App object.
	*/
	App* App::NoRasterize() {
		glEnable(GL_RASTERIZER_DISCARD);

		return this;
	}

	/**
		Enable backface culling.

		@method
		@return {App} The App object.
	*/
	App* App::CullBackfaces() {
		glEnable(GL_CULL_FACE);

		return this;
	}

	/**
		Disable backface culling.

		@method
		@return {App} The App object.
	*/
	App* App::NoCullBackfaces() {
		glDisable(GL_CULL_FACE);

		return this;
	}

	/**
		Enable the EXT_color_buffer_float extension. Allows for creating float textures as
		render targets on FrameBuffer objects.

		@method
		@see Framebuffer
		@return {App} The App object.
	*/

	void PrintAllExtensions()
	{
		GLint n = 0;
		glGetIntegerv(GL_NUM_EXTENSIONS, &n);

		for (GLint i = 0; i < n; i++)
		{
			const char* extension = (const char*)glGetStringi(GL_EXTENSIONS, i);
			::Debug("Ext %d: %s\n", i, extension);
		}
	}

	App* App::FloatRenderTargets() {
		PrintAllExtensions();

		this->floatRenderTargetsEnabled = glfwExtensionSupported("GL_ARB_color_buffer_float");

		return this;
	}

	/**
		Enable the OES_texture_float_linear extension. Allows for linear blending on float textures.

		@method
		@see Framebuffer
		@return {App} The App object.
	*/
	App* App::LinearFloatTextures() {
		this->linearFloatTexturesEnabled = glfwExtensionSupported("GL_EXT_texture_float_linear");

		return this;
	}


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
	App* App::S3TCTextures() {
		this->s3tcTexturesEnabled = glfwExtensionSupported("GL_EXT_texture_compression_s3tc"); // ext name not sure, need to check!!!

		if (this->s3tcTexturesEnabled) {
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_RGB_S3TC_DXT1_EXT] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_RGBA_S3TC_DXT1_EXT] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_RGBA_S3TC_DXT3_EXT] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_RGBA_S3TC_DXT5_EXT] = PicoGL::Constant::TRUE;
		}

		this->s3tcSRGBTexturesEnabled = glfwExtensionSupported("GL_EXT_texture_compression_s3tc_srgb"); // ext name not sure, need to check!!!

		if (this->s3tcSRGBTexturesEnabled) {
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_SRGB_S3TC_DXT1_EXT] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT] = PicoGL::Constant::TRUE;
		}

		return this;
	}

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
	App* App::ETCTextures() {
		this->etcTexturesEnabled = glfwExtensionSupported("GL_EXT_texture_compression_etc");// ext name not sure, need to check!!!
		
		if (this->etcTexturesEnabled) {
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_R11_EAC] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_SIGNED_R11_EAC] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_RG11_EAC] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_SIGNED_RG11_EAC] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_RGB8_ETC2] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_SRGB8_ETC2] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_RGBA8_ETC2_EAC] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_SRGB8_ALPHA8_ETC2_EAC] = PicoGL::Constant::TRUE;
		}

		return this;
	}

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
	App* App::ASTCTextures() {
		this->astcTexturesEnabled = glfwExtensionSupported("GL_EXT_texture_compression_astc"); // ext name not sure, need to check!!!

		if (this->astcTexturesEnabled) {
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_RGBA_ASTC_4x4_KHR] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_RGBA_ASTC_5x4_KHR] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_RGBA_ASTC_5x5_KHR] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_RGBA_ASTC_6x5_KHR] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_RGBA_ASTC_6x6_KHR] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_RGBA_ASTC_8x5_KHR] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_RGBA_ASTC_8x6_KHR] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_RGBA_ASTC_8x8_KHR] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_RGBA_ASTC_10x5_KHR] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_RGBA_ASTC_10x6_KHR] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_RGBA_ASTC_10x8_KHR] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_RGBA_ASTC_10x10_KHR] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_RGBA_ASTC_12x10_KHR] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_RGBA_ASTC_12x12_KHR] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES][PicoGL::Constant::COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR] = PicoGL::Constant::TRUE;
		}

		return this;
	}

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
	App* App::PVRTCTextures() {
		this->pvrtcTexturesEnabled = glfwExtensionSupported("GL_EXT_texture_compression_pvrtc"); // ext name not sure, need to check!!!

		if (this->pvrtcTexturesEnabled) {
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES[PicoGL::Constant::COMPRESSED_RGB_PVRTC_4BPPV1_IMG] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES[PicoGL::Constant::COMPRESSED_RGB_PVRTC_2BPPV1_IMG] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES[PicoGL::Constant::COMPRESSED_RGBA_PVRTC_4BPPV1_IMG] = PicoGL::Constant::TRUE;
			TEXTURE_FORMAT_DEFAULTS[PicoGL::Constant::COMPRESSED_TYPES[PicoGL::Constant::COMPRESSED_RGBA_PVRTC_2BPPV1_IMG] = PicoGL::Constant::TRUE;
		}

		return this;
	}
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

	App* App::ReadPixel(int x, int y, void* outColor, const Options& options) {
		IMPLEMENT_INIT_OPTION(options, format, PicoGL::Constant::RGBA);
		IMPLEMENT_INIT_OPTION(options, type, PicoGL::Constant::UNSIGNED_BYTE);
		/*
		let{
			format = CONSTANTS.RGBA,
			type = CONSTANTS.UNSIGNED_BYTE
		} = options;
		*/
		glReadPixels(x, y, 1, 1, GetGLEnum(format), GetGLEnum(type), outColor);

		return this;
	}

	/**
		Set the viewport.

		@method
		@param {number} x Left bound of the viewport rectangle.
		@param {number} y Lower bound of the viewport rectangle.
		@param {number} width Width of the viewport rectangle.
		@param {number} height Height of the viewport rectangle.
		@return {App} The App object.
	*/
	App* App::Viewport(int x, int y, int width, int height) {
		if (this->viewportWidth != width || this->viewportHeight != height || this->viewportX != x || this->viewportY != y)
		{
			this->viewportX = x;
			this->viewportY = y;
			this->viewportWidth = width;
			this->viewportHeight = height;
			glViewport(x, y, this->viewportWidth, this->viewportHeight);
		}

		return this;
	}

	/**
		Set the viewport to the full canvas.

		@method
		@return {App} The App object.
	*/
	App* App::DefaultViewport() {
		this->Viewport(0, 0, this->width, this->height);

		return this;
	}

	/**
		Resize the drawing surface.

		@method
		@param {number} width The new canvas width.
		@param {number} height The new canvas height.
		@return {App} The App object.
	*/
	App* App::Resize(int width, int height) {
		// this.canvas.width = width;
		// this.canvas.height = height;

		this->width = width; //  this.gl.drawingBufferWidth;
		this->height = height; // this.gl.drawingBufferHeight;
		this->Viewport(0, 0, this->width, this->height);

		return this;
	}
	/**
		Create a program.

		@method
		@param {Shader|string} vertexShader Vertex shader object or source code.
		@param {Shader|string} fragmentShader Fragment shader object or source code.
		@param {Array} [xformFeedbackVars] Transform feedback varyings.
		@return {Program} New Program object.
	*/
	Program* App::CreateProgram(const char* const* vsSource, unsigned int vsSourceLength,
		const char* const* fsSource, unsigned int fsSourceLength,
		const std::vector<const char*>& xformFeedbackVars) {
		return new Program(&this->state, vsSource, vsSourceLength, fsSource, fsSourceLength, xformFeedbackVars);
	}

	Program* App::CreateProgram(Shader* vShader, Shader* fShader, const std::vector<const char*>& xformFeedbackVars) {
		return new Program(&this->state, vShader, fShader, xformFeedbackVars);
	}

	/**
		Create a shader. Creating a shader separately from a program allows for
		shader reuse.

		@method
		@param {GLEnum} type Shader type.
		@param {string} source Shader source.
		@return {Shader} New Shader object.
	*/
	Shader* App::CreateShader(PicoGL::Constant type, const char* const* source, int sourceLength) {
		return new Shader(type, source, sourceLength);
	}

	/**
		Create a vertex array.

		@method
		@return {VertexArray} New VertexArray object.
	*/
	VertexArray* App::CreateVertexArray() {
		return new VertexArray(&this->state);
	}

	/**
		Create a transform feedback object.

		@method
		@return {TransformFeedback} New TransformFeedback object.
	*/
	TransformFeedback* App::CreateTransformFeedback() {
		return new TransformFeedback(&this->state);
	}

	/**
		Create a vertex buffer.

		@method
		@param {GLEnum} type The data type stored in the vertex buffer.
		@param {number} itemSize Number of elements per vertex.
		@param {ArrayBufferView} data Buffer data.
		@param {GLEnum} [usage=STATIC_DRAW] Buffer usage.
		@return {VertexBuffer} New VertexBuffer object.
	*/
	VertexBuffer* App::CreateVertexBuffer(PicoGL::Constant type, int itemSize, const void* data, unsigned int dataLength, PicoGL::Constant usage) {
		return new VertexBuffer(&this->state, type, itemSize, data, dataLength, usage);
	}

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
	PicoGL::VertexBuffer* App::CreateMatrixBuffer(PicoGL::Constant type, const void* data, unsigned int dataLength, PicoGL::Constant usage) {
		return new VertexBuffer(&this->state, type, 0, data, dataLength, usage);
	}

	/**
		Create an index buffer.

		@method
		@param {GLEnum} type The data type stored in the index buffer.
		@param {number} itemSize Number of elements per primitive.
		@param {ArrayBufferView} data Index buffer data.
		@param {GLEnum} [usage=STATIC_DRAW] Buffer usage.
		@return {VertexBuffer} New VertexBuffer object.
	*/
	PicoGL::VertexBuffer* App::CreateIndexBuffer(PicoGL::Constant type, int itemSize, const void* data, unsigned int dataLength, PicoGL::Constant usage) {
		return new VertexBuffer(&this->state, type, itemSize, data, dataLength, usage, true);
	}

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
	PicoGL::UniformBuffer* App::CreateUniformBuffer(const std::vector<PicoGL::Constant>& layout, PicoGL::Constant usage) {
		return new UniformBuffer(&this->state, layout, usage);
	}

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
	Texture* App::CreateTexture2D(const void* image, int width, int height, const Options& options) {
		/*
		if (typeof image == = "number") {
			// Create empty texture just give width/height.
			options = height;
			height = width;
			width = image;
			image = null;
		}
		else if (height == = undefined) {
			// Passing in a DOM element. Height/width not required.
			options = width;
			width = image.width;
			height = image.height;
		}
		//return new Texture(this.gl, this.state, this.gl.TEXTURE_2D, image, width, height, undefined, false, options);
		*/

		return new Texture(&this->state, PicoGL::Constant::TEXTURE_2D, image, width, height, -1, false, options);
	}

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
	Texture* App::CreateTextureArray(const void* image, int width, int height, int depth, const Options& options) {
		/*
		if (typeof image == = "number") {
			// Create empty texture just give width/height/depth.
			options = depth;
			depth = height;
			height = width;
			width = image;
			image = null;
		}
		return new Texture(this.gl, this.state, this.gl.TEXTURE_2D_ARRAY, image, width, height, depth, true, options);
		*/

		return new Texture(&this->state, PicoGL::Constant::TEXTURE_2D_ARRAY, image, width, height, depth, true, options);
	}

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
	Texture* App::CreateTexture3D(const void* image, int width, int height, int depth, const Options& options) {
		/*
		if (typeof image == = "number") {
			// Create empty texture just give width/height/depth.
			options = depth;
			depth = height;
			height = width;
			width = image;
			image = null;
		}
		return new Texture(this.gl, this.state, this.gl.TEXTURE_3D, image, width, height, depth, true, options);
		*/
		return new Texture(&this->state, PicoGL::Constant::TEXTURE_3D, image, width, height, depth, true, options);
	}

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
	Cubemap* App::CreateCubemap(const Options& options) {
		return new Cubemap(&this->state, options);
	}

	/**
		Create a framebuffer.

		@method
		@return {Framebuffer} New Framebuffer object.
	*/
	Framebuffer* App::CreateFramebuffer() {
		return new Framebuffer(&this->state);
	}

	/**
		Create a query.

		@method
		@param {GLEnum} target Information to query.
		@return {Query} New Query object.
	*/
	Query* App::CreateQuery(PicoGL::Constant target) {
		return new Query(target);
	}

	/**
		Create a timer.

		@method
		@return {Timer} New Timer object.
	*/
	Timer* App::CreateTimer() {
		return new Timer();
	}

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
	DrawCall* App::CreateDrawCall(Program* program, VertexArray* vertexArray, PicoGL::Constant primitive) {
		return new DrawCall(&this->state, program, vertexArray, primitive);
	}

	App* CreateApp(const Options& options) {
		return new App(options);
	};
};