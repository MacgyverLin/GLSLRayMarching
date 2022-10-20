#include "RHI.h"
#include "Graphics.h"
#include "Vector4.h"

GLenum GetGLConstant(RHI::Constant constant)
{
	static std::vector<GLenum> glConstants =
	{
		GL_DEPTH_BUFFER_BIT,
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
		//GL_TIMEOUT_IGNORED,
		// GL_MAX_CLIENT_WAIT_TIMEOUT_WEBGL,

		// https://www.khronos.org/registry/webgl/extensions/EXT_disjoint_timer_query_webgl2/
		// GL_QUERY_COUNTER_BITS_EXT,
		GL_TIME_ELAPSED_EXT,
		// GL_TIMESTAMP_EXT,
		// GL_GPU_DISJOINT_EXT,

		// https://www.khronos.org/registry/webgl/extensions/WEBcompressed_texture_s3tc/
		GL_COMPRESSED_RGB_S3TC_DXT1_EXT,
		GL_COMPRESSED_RGBA_S3TC_DXT1_EXT,
		GL_COMPRESSED_RGBA_S3TC_DXT3_EXT,
		GL_COMPRESSED_RGBA_S3TC_DXT5_EXT,

		// https://www.khronos.org/registry/webgl/extensions/WEBcompressed_texture_s3tc_srgb/
		GL_COMPRESSED_SRGB_S3TC_DXT1_EXT,
		GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT,
		GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT,
		GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT,

		// https://www.khronos.org/registry/webgl/extensions/WEBcompressed_texture_etc/
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

		// https://www.khronos.org/registry/webgl/extensions/WEBcompressed_texture_pvrtc/
		// GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG,
		// GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG,
		// GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG,
		// GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG,

		// https://www.khronos.org/registry/webgl/extensions/WEBcompressed_texture_astc/
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
		GL_INVALID_ENUM
	};

	return glConstants[GLuint(constant)];
}

int GetTypeSize(RHI::Constant constant)
{
	static std::map<RHI::Constant, int> typeSizes =
	{
		{ RHI::Constant::BYTE			, 1 },
		{ RHI::Constant::UNSIGNED_BYTE	, 1 },
		{ RHI::Constant::SHORT			, 2 },
		{ RHI::Constant::UNSIGNED_SHORT	, 2 },
		{ RHI::Constant::INT			, 4 },
		{ RHI::Constant::UNSIGNED_INT	, 4 },
		{ RHI::Constant::FLOAT			, 4 }
	};

	return typeSizes[constant];
}

std::map<RHI::Constant, int>& GetDeviceInfos()
{
	static bool inited = false;
	static std::map<RHI::Constant, int> glInfos;

	if (!inited)
	{
		glGetIntegerv(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS, &(glInfos[RHI::Constant::MAX_COMBINED_TEXTURE_IMAGE_UNITS]));
		glGetIntegerv(GL_MAX_UNIFORM_BUFFER_BINDINGS, &(glInfos[RHI::Constant::MAX_UNIFORM_BUFFER_BINDINGS]));
	}

	return glInfos;
}

int GetDeviceInfo(RHI::Constant constant)
{
	std::map<RHI::Constant, int>& deviceInfos = GetDeviceInfos();

	return deviceInfos[constant];
}

std::map<RHI::Constant, std::map<RHI::Constant, RHI::Constant>> TEXTURE_FORMAT_DEFAULTS =
{
	{
		RHI::Constant::UNSIGNED_BYTE,
		{
			{ RHI::Constant::RED , RHI::Constant::R8 },
			{ RHI::Constant::RG  , RHI::Constant::RG8 },
			{ RHI::Constant::RGB , RHI::Constant::RGB8 },
			{ RHI::Constant::RGBA, RHI::Constant::RGBA8 }
		},
	},

	{
		RHI::Constant::UNSIGNED_SHORT,
		{
			{ RHI::Constant::DEPTH_COMPONENT , RHI::Constant::DEPTH_COMPONENT16 }
		},
	},

	{
		RHI::Constant::FLOAT,
		{
			{RHI::Constant::RED , RHI::Constant::R16F },
			{ RHI::Constant::RG  , RHI::Constant::RG16F },
			{ RHI::Constant::RGB , RHI::Constant::RGB16F },
			{ RHI::Constant::RGBA, RHI::Constant::RGBA16F },
			{ RHI::Constant::DEPTH_COMPONENT , RHI::Constant::DEPTH_COMPONENT32F }
		},
	},

	{
		RHI::Constant::COMPRESSED_TYPES,
		{
		}
	}
};

RHI::Shader::Shader(RHI::State* state, RHI::Constant type, const char* source)
{
	this->state = state;
	this->shader = glCreateShader(GetGLConstant(type));

	int length = 0;
	glShaderSource(this->shader, sizeof(source), (const GLchar* const*)source, &length);
	glCompileShader(this->shader);

	int success;
	glGetShaderiv(this->shader, GL_COMPILE_STATUS, &success);
	if (!success)
	{
		int i, lines;

		char infoLog[512];
		glGetShaderInfoLog(this->shader, 512, nullptr, infoLog);
		::Debug(infoLog);
	}
}

RHI::Shader::~Shader()
{
	if (this->shader)
	{
		glDeleteShader(this->shader);
		this->shader = 0;
	}
}

//////////////////////////////////////////////////////////////////
RHI::TransformFeedback::TransformFeedback(RHI::State* state)
{
}

RHI::TransformFeedback::~TransformFeedback()
{
}

//////////////////////////////////////////////////////////////////
RHI::Program::UniformClass::UniformClass(unsigned int uniformHandle, unsigned int uniformInfoType, unsigned int uniformNumElements)
{
	static std::map<unsigned int, int> UNIFORM_CACHE_TYPE_DATA_SIZE =
	{
		{ GL_BOOL, 1},
		{ GL_INT, 1},
		{ GL_SAMPLER_2D, 1},
		{ GL_INT_SAMPLER_2D, 1},
		{ GL_UNSIGNED_INT_SAMPLER_2D, 1},
		{ GL_SAMPLER_2D_SHADOW, 1},
		{ GL_SAMPLER_2D_ARRAY, 1},
		{ GL_INT_SAMPLER_2D_ARRAY, 1},
		{ GL_UNSIGNED_INT_SAMPLER_2D_ARRAY, 1},
		{ GL_SAMPLER_2D_ARRAY_SHADOW, 1},
		{ GL_SAMPLER_CUBE, 1},
		{ GL_INT_SAMPLER_CUBE, 1},
		{ GL_UNSIGNED_INT_SAMPLER_CUBE, 1},
		{ GL_SAMPLER_CUBE_SHADOW, 1},
		{ GL_SAMPLER_3D, 1},
		{ GL_INT_SAMPLER_3D, 1},
		{ GL_UNSIGNED_INT_SAMPLER_3D, 1},
		{ GL_UNSIGNED_INT,1},
		{ GL_FLOAT, 1},
		{ GL_FLOAT_VEC2, 2},
		{ GL_FLOAT_VEC3, 3},
		{ GL_FLOAT_VEC4, 4},
		{ GL_INT_VEC2, 2},
		{ GL_INT_VEC3, 3},
		{ GL_INT_VEC4, 4},
		{ GL_UNSIGNED_INT_VEC2, 2},
		{ GL_UNSIGNED_INT_VEC3, 3},
		{ GL_UNSIGNED_INT_VEC4, 4},
		{ GL_BOOL_VEC2, 2},
		{ GL_BOOL_VEC3, 3},
		{ GL_BOOL_VEC4, 4},
		{ GL_FLOAT_MAT2, 4},
		{ GL_FLOAT_MAT3, 9},
		{ GL_FLOAT_MAT4, 16},
		{ GL_FLOAT_MAT2x3, 6},
		{ GL_FLOAT_MAT2x4, 8},
		{ GL_FLOAT_MAT3x2, 6},
		{ GL_FLOAT_MAT3x4, 12},
		{ GL_FLOAT_MAT4x2, 8},
		{ GL_FLOAT_MAT4x3, 12}
	};

	this->uniformHandle = uniformHandle;
	this->uniformInfoType = uniformInfoType;
	this->uniformNumElements = uniformNumElements;

	this->cache.resize(UNIFORM_CACHE_TYPE_DATA_SIZE[uniformInfoType] * 4 * uniformNumElements);
}

void RHI::Program::UniformClass::Set(const int& value)
{
	Assert(this->uniformInfoType == GL_INT);

	int* cacheValue = (int*)(&cache[0]);
	if (*cacheValue != value)
	{
		*cacheValue = value;
		glUniform1iv(uniformHandle, uniformNumElements, (const int*)(&value));
	}
}

void RHI::Program::UniformClass::Set(const unsigned int& value)
{
	Assert(this->uniformInfoType == GL_UNSIGNED_INT);

	unsigned int* cacheValue = (unsigned int*)(&cache[0]);
	if (*cacheValue != value)
	{
		*cacheValue = value;
		glUniform1uiv(uniformHandle, uniformNumElements, (const unsigned int*)(&value));
	}
}

void RHI::Program::UniformClass::Set(const float& value)
{
	Assert(this->uniformInfoType == GL_FLOAT);

	float* cacheValue = (float*)(&cache[0]);
	if (*cacheValue != value)
	{
		*cacheValue = value;
		glUniform1fv(uniformHandle, uniformNumElements, (const float*)(&value));
	}
}

void RHI::Program::UniformClass::Set(const bool& value)
{
	Assert(this->uniformInfoType == GL_BOOL);

	bool* cacheValue = (bool*)(&cache[0]);
	if (*cacheValue != value)
	{
		*cacheValue = value;
		glUniform1iv(uniformHandle, uniformNumElements, (const int*)(&value));
	}
}

void RHI::Program::UniformClass::Set(const IVector2& value)
{
	Assert(this->uniformInfoType == GL_INT);

	IVector2* cacheValue = (IVector2*)(&cache[0]);
	if (*cacheValue != value)
	{
		*cacheValue = value;
		glUniform2iv(uniformHandle, uniformNumElements, (const int*)(&value));
	}
}

void RHI::Program::UniformClass::Set(const UIVector2& value)
{
	Assert(this->uniformInfoType == GL_UNSIGNED_INT);

	UIVector2* cacheValue = (UIVector2*)(&cache[0]);
	if (*cacheValue != value)
	{
		*cacheValue = value;
		glUniform2uiv(uniformHandle, uniformNumElements, (const unsigned int*)(&value));
	}
}

void RHI::Program::UniformClass::Set(const Vector2& value)
{
	Assert(this->uniformInfoType == GL_FLOAT);

	Vector2* cacheValue = (Vector2*)(&cache[0]);
	if (*cacheValue != value)
	{
		*cacheValue = value;
		glUniform2fv(uniformHandle, uniformNumElements, (const float*)(&value));
	}
}

void RHI::Program::UniformClass::Set(const BVector2& value)
{
	Assert(this->uniformInfoType == GL_BOOL);

	BVector2* cacheValue = (BVector2*)(&cache[0]);
	if (*cacheValue != value)
	{
		*cacheValue = value;
		glUniform2iv(uniformHandle, uniformNumElements, (const int*)(&value));
	}
}

void RHI::Program::UniformClass::Set(const IVector3& value)
{
	Assert(this->uniformInfoType == GL_INT);

	IVector3* cacheValue = (IVector3*)(&cache[0]);
	if (*cacheValue != value)
	{
		*cacheValue = value;
		glUniform3iv(uniformHandle, uniformNumElements, (const int*)(&value));
	}
}

void RHI::Program::UniformClass::Set(const UIVector3& value)
{
	Assert(this->uniformInfoType == GL_UNSIGNED_INT);

	UIVector3* cacheValue = (UIVector3*)(&cache[0]);
	if (*cacheValue != value)
	{
		*cacheValue = value;
		glUniform3uiv(uniformHandle, uniformNumElements, (const unsigned int*)(&value));
	}
}

void RHI::Program::UniformClass::Set(const Vector3& value)
{
	Assert(this->uniformInfoType == GL_FLOAT);

	Vector3* cacheValue = (Vector3*)(&cache[0]);
	if (*cacheValue != value)
	{
		*cacheValue = value;
		glUniform3fv(uniformHandle, uniformNumElements, (const float*)(&value));
	}
}

void RHI::Program::UniformClass::Set(const BVector3& value)
{
	Assert(this->uniformInfoType == GL_BOOL);

	BVector3* cacheValue = (BVector3*)(&cache[0]);
	if (*cacheValue != value)
	{
		*cacheValue = value;
		glUniform3iv(uniformHandle, uniformNumElements, (const int*)(&value));
	}
}

void RHI::Program::UniformClass::Set(const IVector4& value)
{
	Assert(this->uniformInfoType == GL_INT);

	IVector4* cacheValue = (IVector4*)(&cache[0]);
	if (*cacheValue != value)
	{
		*cacheValue = value;
		glUniform4iv(uniformHandle, uniformNumElements, (const int*)(&value));
	}
}

void RHI::Program::UniformClass::Set(const UIVector4& value)
{
	Assert(this->uniformInfoType == GL_UNSIGNED_INT);

	UIVector4* cacheValue = (UIVector4*)(&cache[0]);
	if (*cacheValue != value)
	{
		*cacheValue = value;
		glUniform4uiv(uniformHandle, uniformNumElements, (const unsigned int*)(&value));
	}
}

void RHI::Program::UniformClass::Set(const Vector4& value)
{
	Assert(this->uniformInfoType == GL_FLOAT);

	Vector4* cacheValue = (Vector4*)(&cache[0]);
	if (*cacheValue != value)
	{
		*cacheValue = value;
		glUniform4fv(uniformHandle, uniformNumElements, (const float*)(&value));
	}
}

void RHI::Program::UniformClass::Set(const BVector4& value)
{
	Assert(this->uniformInfoType == GL_BOOL);

	BVector4* cacheValue = (BVector4*)(&cache[0]);
	if (*cacheValue != value)
	{
		*cacheValue = value;
		glUniform4iv(uniformHandle, uniformNumElements, (const int*)(&value));
	}
}

void RHI::Program::UniformClass::Set(const Matrix22& value)
{
	Assert(this->uniformInfoType == GL_FLOAT_MAT2);

	Matrix22* cacheValue = (Matrix22*)(&cache[0]);
	if (*cacheValue != value)
	{
		*cacheValue = value;
		glUniformMatrix2fv(uniformHandle, uniformNumElements, GL_FALSE, (const float*)(&value));
	}
}

void RHI::Program::UniformClass::Set(const Matrix32& value)
{
	Assert(this->uniformInfoType == GL_FLOAT_MAT2x3);

	Matrix32* cacheValue = (Matrix32*)(&cache[0]);
	if (*cacheValue != value)
	{
		*cacheValue = value;
		glUniformMatrix2x3fv(uniformHandle, uniformNumElements, GL_FALSE, (const float*)(&value));
	}
}

void RHI::Program::UniformClass::Set(const Matrix42& value)
{
	Assert(this->uniformInfoType == GL_FLOAT_MAT2x4);

	Matrix42* cacheValue = (Matrix42*)(&cache[0]);
	if (*cacheValue != value)
	{
		*cacheValue = value;
		glUniformMatrix2x4fv(uniformHandle, uniformNumElements, GL_FALSE, (const float*)(&value));
	}
}

void RHI::Program::UniformClass::Set(const Matrix23& value)
{
	Assert(this->uniformInfoType == GL_FLOAT_MAT3x2);

	Matrix23* cacheValue = (Matrix23*)(&cache[0]);
	if (*cacheValue != value)
	{
		*cacheValue = value;
		glUniformMatrix3x2fv(uniformHandle, uniformNumElements, GL_FALSE, (const float*)(&value));
	}
}

void RHI::Program::UniformClass::Set(const Matrix33& value)
{
	Assert(this->uniformInfoType == GL_FLOAT_MAT3);

	Matrix33* cacheValue = (Matrix33*)(&cache[0]);
	if (*cacheValue != value)
	{
		*cacheValue = value;
		glUniformMatrix3fv(uniformHandle, uniformNumElements, GL_FALSE, (const float*)(&value));
	}
}

void RHI::Program::UniformClass::Set(const Matrix43& value)
{
	Assert(this->uniformInfoType == GL_FLOAT_MAT3x4);

	Matrix43* cacheValue = (Matrix43*)(&cache[0]);
	if (*cacheValue != value)
	{
		*cacheValue = value;
		glUniformMatrix3x4fv(uniformHandle, uniformNumElements, GL_FALSE, (const float*)(&value));
	}
}

void RHI::Program::UniformClass::Set(const Matrix24& value)
{
	Assert(this->uniformInfoType == GL_FLOAT_MAT4x2);

	Matrix24* cacheValue = (Matrix24*)(&cache[0]);
	if (*cacheValue != value)
	{
		*cacheValue = value;
		glUniformMatrix4x2fv(uniformHandle, uniformNumElements, GL_FALSE, (const float*)(&value));
	}
}

void RHI::Program::UniformClass::Set(const Matrix34& value)
{
	Assert(this->uniformInfoType == GL_FLOAT_MAT4x3);

	Matrix34* cacheValue = (Matrix34*)(&cache[0]);
	if (*cacheValue != value)
	{
		*cacheValue = value;
		glUniformMatrix4x3fv(uniformHandle, uniformNumElements, GL_FALSE, (const float*)(&value));
	}
}

void RHI::Program::UniformClass::Set(const Matrix44& value)
{
	Assert(this->uniformInfoType == GL_FLOAT_MAT4);

	Matrix44* cacheValue = (Matrix44*)(&cache[0]);
	if (*cacheValue != value)
	{
		*cacheValue = value;
		glUniformMatrix4fv(uniformHandle, uniformNumElements, GL_FALSE, (const float*)(&value));
	}
}

void RHI::Program::UniformClass::Set(const int* value, int count)
{
	Assert(this->uniformInfoType == GL_INT);
	Assert(this->uniformNumElements <= count);

	int* cacheValue = (int*)(&cache[0]);
	for (int i = 0; i < count; i++)
	{
		if (cacheValue[i] != value[i])
		{
			::MemCpy(cacheValue, value, count * sizeof(Vector2));
			glUniform1iv(uniformHandle, count, (const int*)(&value));
			return;
		}
	}
}

void RHI::Program::UniformClass::Set(const unsigned int* value, int count)
{
	Assert(this->uniformInfoType == GL_UNSIGNED_INT);
	Assert(this->uniformNumElements <= count);

	unsigned int* cacheValue = (unsigned int*)(&cache[0]);
	for (int i = 0; i < count; i++)
	{
		if (cacheValue[i] != value[i])
		{
			::MemCpy(cacheValue, value, count * sizeof(Vector2));
			glUniform1uiv(uniformHandle, count, (const unsigned int*)(&value));
			return;
		}
	}
}

void RHI::Program::UniformClass::Set(const float* value, int count)
{
	Assert(this->uniformInfoType == GL_FLOAT);
	Assert(this->uniformNumElements <= count);

	float* cacheValue = (float*)(&cache[0]);
	for (int i = 0; i < count; i++)
	{
		if (cacheValue[i] != value[i])
		{
			::MemCpy(cacheValue, value, count * sizeof(float));
			glUniform1fv(uniformHandle, count, (const float*)(&value));
			return;
		}
	}
}

void RHI::Program::UniformClass::Set(const bool* value, int count)
{
	Assert(this->uniformInfoType == GL_BOOL);
	Assert(this->uniformNumElements <= count);

	bool* cacheValue = (bool*)(&cache[0]);
	int a = sizeof(bool);
	for (int i = 0; i < count; i++)
	{
		if (cacheValue[i] != value[i])
		{
			::MemCpy(cacheValue, value, count * sizeof(bool));
			glUniform1iv(uniformHandle, count, (const int*)(&value));
			return;
		}
	}
}

void RHI::Program::UniformClass::Set(const IVector2* value, int count)
{
	Assert(this->uniformInfoType == GL_INT);
	Assert(this->uniformNumElements <= count);

	IVector2* cacheValue = (IVector2*)(&cache[0]);
	for (int i = 0; i < count; i++)
	{
		if (cacheValue[i] != value[i])
		{
			::MemCpy(cacheValue, value, count * sizeof(IVector2));
			glUniform2iv(uniformHandle, count, (const int*)(&value));
			return;
		}
	}
}

void RHI::Program::UniformClass::Set(const UIVector2* value, int count)
{
	Assert(this->uniformInfoType == GL_UNSIGNED_INT);
	Assert(this->uniformNumElements <= count);

	UIVector2* cacheValue = (UIVector2*)(&cache[0]);
	for (int i = 0; i < count; i++)
	{
		if (cacheValue[i] != value[i])
		{
			::MemCpy(cacheValue, value, count * sizeof(UIVector2));
			glUniform2uiv(uniformHandle, count, (const unsigned int*)(&value));
			return;
		}
	}
}

void RHI::Program::UniformClass::Set(const Vector2* value, int count)
{
	Assert(this->uniformInfoType == GL_FLOAT);
	Assert(this->uniformNumElements <= count);

	Vector2* cacheValue = (Vector2*)(&cache[0]);
	for (int i = 0; i < count; i++)
	{
		if (cacheValue[i] != value[i])
		{
			::MemCpy(cacheValue, value, count * sizeof(Vector2));
			glUniform2fv(uniformHandle, count, (const float*)(&value));
			return;
		}
	}
}

void RHI::Program::UniformClass::Set(const BVector2* value, int count)
{
	Assert(this->uniformInfoType == GL_BOOL);
	Assert(this->uniformNumElements <= count);

	BVector2* cacheValue = (BVector2*)(&cache[0]);
	for (int i = 0; i < count; i++)
	{
		if (cacheValue[i] != value[i])
		{
			::MemCpy(cacheValue, value, count * sizeof(BVector2));
			glUniform2iv(uniformHandle, count, (const int*)(&value));
			return;
		}
	}
}

void RHI::Program::UniformClass::Set(const IVector3* value, int count)
{
	Assert(this->uniformInfoType == GL_INT);
	Assert(this->uniformNumElements <= count);

	IVector3* cacheValue = (IVector3*)(&cache[0]);
	for (int i = 0; i < count; i++)
	{
		if (cacheValue[i] != value[i])
		{
			::MemCpy(cacheValue, value, count * sizeof(IVector3));
			glUniform3iv(uniformHandle, count, (const int*)(&value));
			return;
		}
	}
}

void RHI::Program::UniformClass::Set(const UIVector3* value, int count)
{
	Assert(this->uniformInfoType == GL_UNSIGNED_INT);
	Assert(this->uniformNumElements <= count);

	UIVector3* cacheValue = (UIVector3*)(&cache[0]);
	for (int i = 0; i < count; i++)
	{
		if (cacheValue[i] != value[i])
		{
			::MemCpy(cacheValue, value, count * sizeof(UIVector3));
			glUniform3uiv(uniformHandle, count, (const unsigned int*)(&value));
			return;
		}
	}
}

void RHI::Program::UniformClass::Set(const Vector3* value, int count)
{
	Assert(this->uniformInfoType == GL_FLOAT);
	Assert(this->uniformNumElements <= count);

	Vector3* cacheValue = (Vector3*)(&cache[0]);
	for (int i = 0; i < count; i++)
	{
		if (cacheValue[i] != value[i])
		{
			::MemCpy(cacheValue, value, count * sizeof(Vector3));
			glUniform3fv(uniformHandle, count, (const float*)(&value));
			return;
		}
	}
}

void RHI::Program::UniformClass::Set(const BVector3* value, int count)
{
	Assert(this->uniformInfoType == GL_BOOL);
	Assert(this->uniformNumElements <= count);

	BVector3* cacheValue = (BVector3*)(&cache[0]);
	for (int i = 0; i < count; i++)
	{
		if (cacheValue[i] != value[i])
		{
			::MemCpy(cacheValue, value, count * sizeof(BVector3));
			glUniform3iv(uniformHandle, count, (const int*)(&value));
			return;
		}
	}
}

void RHI::Program::UniformClass::Set(const IVector4* value, int count)
{
	Assert(this->uniformInfoType == GL_INT);
	Assert(this->uniformNumElements <= count);

	IVector4* cacheValue = (IVector4*)(&cache[0]);
	for (int i = 0; i < count; i++)
	{
		if (cacheValue[i] != value[i])
		{
			::MemCpy(cacheValue, value, count * sizeof(IVector4));
			glUniform4iv(uniformHandle, count, (const int*)(&value));
			return;
		}
	}
}

void RHI::Program::UniformClass::Set(const UIVector4* value, int count)
{
	Assert(this->uniformInfoType == GL_UNSIGNED_INT);
	Assert(this->uniformNumElements <= count);

	UIVector4* cacheValue = (UIVector4*)(&cache[0]);
	for (int i = 0; i < count; i++)
	{
		if (cacheValue[i] != value[i])
		{
			::MemCpy(cacheValue, value, count * sizeof(UIVector4));
			glUniform4uiv(uniformHandle, count, (const unsigned int*)(&value));
			return;
		}
	}
}

void RHI::Program::UniformClass::Set(const Vector4* value, int count)
{
	Assert(this->uniformInfoType == GL_FLOAT);
	Assert(this->uniformNumElements <= count);

	Vector4* cacheValue = (Vector4*)(&cache[0]);
	for (int i = 0; i < count; i++)
	{
		if (cacheValue[i] != value[i])
		{
			::MemCpy(cacheValue, value, count * sizeof(Vector4));
			glUniform4fv(uniformHandle, count, (const float*)(&value));
			return;
		}
	}
}

void RHI::Program::UniformClass::Set(const BVector4* value, int count)
{
	Assert(this->uniformInfoType == GL_BOOL);
	Assert(this->uniformNumElements <= count);

	BVector4* cacheValue = (BVector4*)(&cache[0]);
	for (int i = 0; i < count; i++)
	{
		if (cacheValue[i] != value[i])
		{
			::MemCpy(cacheValue, value, count * sizeof(BVector4));
			glUniform4iv(uniformHandle, count, (const int*)(&value));
			return;
		}
	}
}

void RHI::Program::UniformClass::Set(const Matrix22* value, int count)
{
	Assert(this->uniformInfoType == GL_FLOAT_MAT2);
	Assert(this->uniformNumElements <= count);

	Matrix22* cacheValue = (Matrix22*)(&cache[0]);
	for (int i = 0; i < count; i++)
	{
		if (cacheValue[i] != value[i])
		{
			::MemCpy(cacheValue, value, count * sizeof(Matrix22));
			glUniformMatrix2fv(uniformHandle, count, GL_FALSE, (const float*)(&value));
			return;
		}
	}
}

void RHI::Program::UniformClass::Set(const Matrix32* value, int count)
{
	Assert(this->uniformInfoType == GL_FLOAT_MAT2x3);
	Assert(this->uniformNumElements <= count);

	Matrix32* cacheValue = (Matrix32*)(&cache[0]);
	for (int i = 0; i < count; i++)
	{
		if (cacheValue[i] != value[i])
		{
			::MemCpy(cacheValue, value, count * sizeof(Matrix32));
			glUniformMatrix2x3fv(uniformHandle, count, GL_FALSE, (const float*)(&value));
			return;
		}
	}
}

void RHI::Program::UniformClass::Set(const Matrix42* value, int count)
{
	Assert(this->uniformInfoType == GL_FLOAT_MAT2x4);
	Assert(this->uniformNumElements <= count);

	Matrix42* cacheValue = (Matrix42*)(&cache[0]);
	for (int i = 0; i < count; i++)
	{
		if (cacheValue[i] != value[i])
		{
			::MemCpy(cacheValue, value, count * sizeof(Matrix42));
			glUniformMatrix2x4fv(uniformHandle, count, GL_FALSE, (const float*)(&value));
			return;
		}
	}
}

void RHI::Program::UniformClass::Set(const Matrix23* value, int count)
{
	Assert(this->uniformInfoType == GL_FLOAT_MAT3x2);
	Assert(this->uniformNumElements <= count);

	Matrix23* cacheValue = (Matrix23*)(&cache[0]);
	for (int i = 0; i < count; i++)
	{
		if (cacheValue[i] != value[i])
		{
			::MemCpy(cacheValue, value, count * sizeof(Matrix23));
			glUniformMatrix3x2fv(uniformHandle, count, GL_FALSE, (const float*)(&value));
			return;
		}
	}
}

void RHI::Program::UniformClass::Set(const Matrix33* value, int count)
{
	Assert(this->uniformInfoType == GL_FLOAT_MAT3);
	Assert(this->uniformNumElements <= count);

	Matrix33* cacheValue = (Matrix33*)(&cache[0]);
	for (int i = 0; i < count; i++)
	{
		if (cacheValue[i] != value[i])
		{
			::MemCpy(cacheValue, value, count * sizeof(Matrix33));
			glUniformMatrix3fv(uniformHandle, count, GL_FALSE, (const float*)(&value));
			return;
		}
	}
}

void RHI::Program::UniformClass::Set(const Matrix43* value, int count)
{
	Assert(this->uniformInfoType == GL_FLOAT_MAT3x4);
	Assert(this->uniformNumElements <= count);

	Matrix43* cacheValue = (Matrix43*)(&cache[0]);
	for (int i = 0; i < count; i++)
	{
		if (cacheValue[i] != value[i])
		{
			::MemCpy(cacheValue, value, count * sizeof(Matrix43));
			glUniformMatrix3x4fv(uniformHandle, count, GL_FALSE, (const float*)(&value));
			return;
		}
	}
}

void RHI::Program::UniformClass::Set(const Matrix24* value, int count)
{
	Assert(this->uniformInfoType == GL_FLOAT_MAT4x2);
	Assert(this->uniformNumElements <= count);

	Matrix24* cacheValue = (Matrix24*)(&cache[0]);
	for (int i = 0; i < count; i++)
	{
		if (cacheValue[i] != value[i])
		{
			::MemCpy(cacheValue, value, count * sizeof(Matrix24));
			glUniformMatrix4x2fv(uniformHandle, count, GL_FALSE, (const float*)(&value));
			return;
		}
	}
}

void RHI::Program::UniformClass::Set(const Matrix34* value, int count)
{
	Assert(this->uniformInfoType == GL_FLOAT_MAT4x3);
	Assert(this->uniformNumElements <= count);

	Matrix34* cacheValue = (Matrix34*)(&cache[0]);
	for (int i = 0; i < count; i++)
	{
		if (cacheValue[i] != value[i])
		{
			::MemCpy(cacheValue, value, count * sizeof(Matrix34));
			glUniformMatrix4x3fv(uniformHandle, count, GL_FALSE, (const float*)(&value));
			return;
		}
	}
}

void RHI::Program::UniformClass::Set(const Matrix44* value, int count)
{
	Assert(this->uniformInfoType == GL_FLOAT_MAT4);
	Assert(this->uniformNumElements <= count);

	Matrix44* cacheValue = (Matrix44*)(&cache[0]);
	for (int i = 0; i < count; i++)
	{
		if (cacheValue[i] != value[i])
		{
			::MemCpy(cacheValue, value, count * sizeof(Matrix44));
			glUniformMatrix4fv(uniformHandle, count, GL_FALSE, (const float*)(&value));
			return;
		}
	}
}

RHI::Program::Program(RHI::State* state, const char* vsSource, const char* fsSource, const std::vector<const char*>& xformFeebackVars)
{
	RHI::Shader* vShader;
	RHI::Shader* fShader;
	vShader = new RHI::Shader(state, RHI::Constant::VERTEX_SHADER, vsSource);
	fShader = new RHI::Shader(state, RHI::Constant::FRAGMENT_SHADER, fsSource);

	CreateProgramInternal(state, vShader, fShader, true, true, xformFeebackVars);
}

RHI::Program::Program(RHI::State* state, RHI::Shader* vShader, RHI::Shader* fShader, const std::vector<const char*>& xformFeebackVars)
{
	CreateProgramInternal(state, vShader, fShader, false, false, xformFeebackVars);
}

void RHI::Program::CreateProgramInternal(RHI::State* state, RHI::Shader* vShader, RHI::Shader* fShader, bool ownVertexShader, bool ownFragmentShader, const std::vector<const char*>& xformFeebackVars)
{
	GLuint program = glCreateProgram();
	glAttachShader(program, vShader->shader);
	glAttachShader(program, fShader->shader);

	if (xformFeebackVars.size())
	{
		glTransformFeedbackVaryings(program, xformFeebackVars.size(), &xformFeebackVars[0], GL_SEPARATE_ATTRIBS);
	}
	glLinkProgram(program);

	int success;
	glGetProgramiv(program, GL_LINK_STATUS, &success);
	if (!success)
	{
		int i, lines;

		char infoLog[4096];
		glGetProgramInfoLog(program, 4096, nullptr, infoLog);
		::Debug(infoLog);
	}

	if (ownVertexShader)
	{
		delete vShader;
		vShader = nullptr;
	}

	if (ownFragmentShader)
	{
		delete fShader;
		fShader = nullptr;
	}

	this->state = state;
	this->program = program;
	this->transformFeedback = xformFeebackVars;
	this->uniforms = std::map<std::string, RHI::Program::UniformClass*>();
	this->uniformBlocks = std::map<std::string, int>();
	this->samplers = std::map<std::string, int>();

	glUseProgram(program);

	int textureUnit;
	int numUniforms;
	glGetProgramiv(program, GL_ACTIVE_UNIFORMS, &numUniforms);
	for (int i = 0; i < numUniforms; ++i)
	{
		GLsizei length;
		GLint uniformNumElements;
		GLenum uniformInfoType;
		GLchar uniformInfoName[4096];
		glGetActiveUniform(program, i, 4096, &length, &uniformNumElements, &uniformInfoType, uniformInfoName);
		GLint uniformHandle = glGetUniformLocation(program, uniformInfoName);

		switch (uniformInfoType)
		{
		case GL_SAMPLER_2D:
		case GL_INT_SAMPLER_2D:
		case GL_UNSIGNED_INT_SAMPLER_2D:
		case GL_SAMPLER_2D_SHADOW:
		case GL_SAMPLER_2D_ARRAY:
		case GL_INT_SAMPLER_2D_ARRAY:
		case GL_UNSIGNED_INT_SAMPLER_2D_ARRAY:
		case GL_SAMPLER_2D_ARRAY_SHADOW:
		case GL_SAMPLER_CUBE:
		case GL_INT_SAMPLER_CUBE:
		case GL_UNSIGNED_INT_SAMPLER_CUBE:
		case GL_SAMPLER_CUBE_SHADOW:
		case GL_SAMPLER_3D:
		case GL_INT_SAMPLER_3D:
		case GL_UNSIGNED_INT_SAMPLER_3D:
			textureUnit = samplers.size();
			samplers[uniformInfoName] = textureUnit;
			glUniform1i(uniformHandle, textureUnit);
			break;
		case GL_INT:
		case GL_UNSIGNED_INT:
		case GL_FLOAT:
			// uniformClass = uniformNumElements > 1 ? MultiNumericUniform : SingleComponentUniform;
			// C++ use single UniformClass, too complcated to be ported
			break;
		case GL_BOOL:
			// uniformClass = uniformNumElements > 1 ? MultiBoolUniform : SingleComponentUniform;
			// C++ use single UniformClass, too complcated to be ported
			break;
		case GL_FLOAT_VEC2:
		case GL_INT_VEC2:
		case GL_UNSIGNED_INT_VEC2:
		case GL_FLOAT_VEC3:
		case GL_INT_VEC3:
		case GL_UNSIGNED_INT_VEC3:
		case GL_FLOAT_VEC4:
		case GL_INT_VEC4:
		case GL_UNSIGNED_INT_VEC4:
			// uniformClass = MultiNumericUniform;
			// C++ use single UniformClass, too complcated to be ported
			break;
		case GL_BOOL_VEC2:
		case GL_BOOL_VEC3:
		case GL_BOOL_VEC4:
			// uniformClass = MultiBoolUniform;
			// C++ use single UniformClass, too complcated to be ported
			break;
		case GL_FLOAT_MAT2:
		case GL_FLOAT_MAT3:
		case GL_FLOAT_MAT4:
		case GL_FLOAT_MAT2x3:
		case GL_FLOAT_MAT2x4:
		case GL_FLOAT_MAT3x2:
		case GL_FLOAT_MAT3x4:
		case GL_FLOAT_MAT4x2:
		case GL_FLOAT_MAT4x3:
			// uniformClass = MatrixUniform;
			// C++ use single UniformClass, too complcated to be ported
			break;
		default:
			::Debug("Unrecognized type for uniform ", uniformInfoName);
			break;
		}

		this->uniforms[uniformInfoName] = new UniformClass(uniformHandle, uniformInfoType, uniformNumElements);
	}

	int numUniformBlocks;
	glGetProgramiv(program, GL_ACTIVE_UNIFORM_BLOCKS, &numUniformBlocks);
	for (int i = 0; i < numUniformBlocks; ++i)
	{
		GLsizei length;
		GLchar uniformBlockInfoName[4096];
		glGetActiveUniformBlockName(program, i, 4096, &length, uniformBlockInfoName);
		int uniformBlockInfoIndex = glGetUniformBlockIndex(program, uniformBlockInfoName);

		int uniformBlockBase = uniformBlocks.size();
		glUniformBlockBinding(program, uniformBlockInfoIndex, uniformBlockBase);
		uniformBlocks[uniformBlockInfoName] = uniformBlockBase;
	}

	glUseProgram(0);
}

/**
	Delete this program.

	@method
	@return {Program} The Program object.
*/
RHI::Program::~Program()
{
	if (this->program)
	{
		if (state->program == this)
		{
			state->program = nullptr;
		}

		glDeleteProgram(this->program);
		this->program = 0;
	}
}

// 
/**
	Use this program.

	@method
	@ignore
	@return {Program} The Program object.
*/
RHI::Program& RHI::Program::Bind()
{
	if (state->program != this)
	{
		glUseProgram(this->program);
		state->program = this;
	}

	return *this;
}

//////////////////////////////////////////////////////////////////
RHI::VertexArray::VertexArray(RHI::State* state)
{
	this->state = state;
	glCreateVertexArrays(1, &this->vertexArray);
	this->numElements = 0;
	this->indexType = RHI::Constant::INVALID_ENUM;
	//this->instancedBuffers = 0;
	this->instanced = false;
	this->indexed = false;
	this->numInstances = 0;
}

/**
	 Bind an per-vertex attribute buffer to this vertex array.

	 @method
	 @param {number} attributeIndex The attribute location to bind to.
	 @param {VertexBuffer} vertexBuffer The VertexBuffer to bind.
	 @return {VertexArray} The VertexArray object.
 */
RHI::VertexArray& RHI::VertexArray::VertexAttributeBuffer(int attributeIndex, RHI::VertexBuffer* vertexBuffer)
{
	this->AttributeBuffer(attributeIndex, vertexBuffer, false, false, false);

	return *this;
}

/**
	Bind an per-instance attribute buffer to this vertex array.

	@method
	@param {number} attributeIndex The attribute location to bind to.
	@param {VertexBuffer} vertexBuffer The VertexBuffer to bind.
	@return {VertexArray} The VertexArray object.
*/
RHI::VertexArray& RHI::VertexArray::InstanceAttributeBuffer(int attributeIndex, RHI::VertexBuffer* vertexBuffer)
{
	this->AttributeBuffer(attributeIndex, vertexBuffer, true, false, false);

	return *this;
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
RHI::VertexArray& RHI::VertexArray::VertexIntegerAttributeBuffer(int attributeIndex, RHI::VertexBuffer* vertexBuffer)
{
	this->AttributeBuffer(attributeIndex, vertexBuffer, false, true, false);

	return *this;
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
RHI::VertexArray& RHI::VertexArray::InstanceIntegerAttributeBuffer(int attributeIndex, RHI::VertexBuffer* vertexBuffer)
{
	this->AttributeBuffer(attributeIndex, vertexBuffer, true, true, false);

	return *this;
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
RHI::VertexArray& RHI::VertexArray::VertexNormalizedAttributeBuffer(int attributeIndex, RHI::VertexBuffer* vertexBuffer)
{
	this->AttributeBuffer(attributeIndex, vertexBuffer, false, false, true);

	return *this;
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
RHI::VertexArray& RHI::VertexArray::InstanceNormalizedAttributeBuffer(int attributeIndex, RHI::VertexBuffer* vertexBuffer)
{
	this->AttributeBuffer(attributeIndex, vertexBuffer, true, false, true);

	return *this;
}

/**
	 Bind an index buffer to this vertex array.

	 @method
	 @param {VertexBuffer} vertexBuffer The VertexBuffer to bind.
	 @return {VertexArray} The VertexArray object.
 */
RHI::VertexArray& RHI::VertexArray::IndexBuffer(RHI::VertexBuffer* vertexBuffer)
{
	glBindVertexArray(this->vertexArray);
	glBindBuffer(vertexBuffer->binding, vertexBuffer->buffer);

	numElements = vertexBuffer->numItems * 3;
	indexType = vertexBuffer->type;
	indexed = true;

	glBindVertexArray(0);
	glBindBuffer(vertexBuffer->binding, 0);

	return *this;
}

RHI::VertexArray::~VertexArray()
{
	if (this->vertexArray) 
	{
		glDeleteVertexArrays(1, &this->vertexArray);
		this->vertexArray = 0;
	}
	glBindVertexArray(0);
}

RHI::VertexArray& RHI::VertexArray::Bind() 
{
	if (this->state->vertexArray != this) 
	{
		glBindVertexArray(this->vertexArray);
		this->state->vertexArray = this;
	}

	return *this;
}

RHI::VertexArray& RHI::VertexArray::AttributeBuffer(int attributeIndex, RHI::VertexBuffer* vertexBuffer, bool instanced, bool integer, bool normalized) 
{
	glBindVertexArray(this->vertexArray);
	glBindBuffer(vertexBuffer->binding, vertexBuffer->buffer);

	int numColumns = vertexBuffer->numColumns;
	for (int i = 0; i < numColumns; ++i) 
	{
		if (integer) 
		{
			glVertexAttribIPointer
			(
				attributeIndex + i,
				vertexBuffer->itemSize,
				GetGLConstant(vertexBuffer->type),
				numColumns * vertexBuffer->itemSize * GetTypeSize(vertexBuffer->type),
				(void*)(i * vertexBuffer->itemSize * GetTypeSize(vertexBuffer->type))
			);
		}
		else 
		{
			glVertexAttribPointer
			(
				attributeIndex + i,
				vertexBuffer->itemSize,
				GetGLConstant(vertexBuffer->type),
				normalized,
				numColumns * vertexBuffer->itemSize * GetTypeSize(vertexBuffer->type),
				(void*)(i * vertexBuffer->itemSize * GetTypeSize(vertexBuffer->type))
			);
		}

		if (instanced) 
		{
			glVertexAttribDivisor(attributeIndex + i, 1);
		}

		glEnableVertexAttribArray(attributeIndex + i);
	}

	this->instanced = this->instanced || instanced;

	if (instanced) 
	{
		this->numInstances = vertexBuffer->numItems;
	}
	else 
	{
		//this->numElements = this->numElements || vertexBuffer->numItems;
		if (this->numElements == 0)
			this->numElements = vertexBuffer->numItems;
		else
			this->numElements = this->numElements;
	}

	glBindVertexArray(0);
	glBindBuffer(vertexBuffer->binding, 0);

	return *this;
}

//////////////////////////////////////////////////////////////////
RHI::VertexBuffer::VertexBuffer(RHI::State* state, RHI::Constant type, int itemSize, void* data, unsigned int dataLength, RHI::Constant usage, bool indexArray)
{
	int numColumns;
	switch (type)
	{
	case RHI::Constant::FLOAT_MAT4:
	case RHI::Constant::FLOAT_MAT4x2:
	case RHI::Constant::FLOAT_MAT4x3:
		numColumns = 4;
		break;
	case RHI::Constant::FLOAT_MAT3:
	case RHI::Constant::FLOAT_MAT3x2:
	case RHI::Constant::FLOAT_MAT3x4:
		numColumns = 3;
		break;
	case RHI::Constant::FLOAT_MAT2:
	case RHI::Constant::FLOAT_MAT2x3:
	case RHI::Constant::FLOAT_MAT2x4:
		numColumns = 2;
		break;
	default:
		numColumns = 1;
	};

	switch (type)
	{
	case RHI::Constant::FLOAT_MAT4:
	case RHI::Constant::FLOAT_MAT3x4:
	case RHI::Constant::FLOAT_MAT2x4:
		itemSize = 4;
		type = RHI::Constant::FLOAT;
		break;
	case RHI::Constant::FLOAT_MAT3:
	case RHI::Constant::FLOAT_MAT4x3:
	case RHI::Constant::FLOAT_MAT2x3:
		itemSize = 3;
		type = RHI::Constant::FLOAT;
		break;
	case RHI::Constant::FLOAT_MAT2:
	case RHI::Constant::FLOAT_MAT3x2:
	case RHI::Constant::FLOAT_MAT4x2:
		itemSize = 2;
		type = RHI::Constant::FLOAT;
		break;
	};

	//int dataLength;
	//if (typeof data == = "number") 
	//{
	//	dataLength = data;
	//	data *= GetTypeSize(type);
	//}
	//else 
	//{
	//	dataLength = data.length;
	//}

	this->state = state;
	glCreateBuffers(1, &this->buffer);
	this->type = type;
	this->itemSize = itemSize;
	this->numItems = dataLength / (itemSize * numColumns * GetTypeSize(type));
	this->numColumns = numColumns;
	this->usage = usage;
	this->indexArray = indexArray;
	this->binding = this->indexArray ? GL_ELEMENT_ARRAY_BUFFER : GL_ARRAY_BUFFER;

	glBindBuffer(this->binding, this->buffer);
	glBufferData(this->binding, dataLength, data, GetGLConstant(this->usage));
	glBindBuffer(this->binding, 0);
}

RHI::VertexBuffer::~VertexBuffer()
{
	if (this->buffer)
	{
		glDeleteBuffers(1, &(this->buffer));
		this->buffer = 0;
	}
}

RHI::VertexBuffer& RHI::VertexBuffer::Data(void* data, unsigned int dataLength)
{
	// Don't want to update vertex array bindings
	RHI::VertexArray* currentVertexArray = state->vertexArray;
	if (currentVertexArray)
	{
		glBindVertexArray(0);
	}

	glBindBuffer(this->binding, this->buffer);
	glBufferSubData(this->binding, 0, dataLength, data);
	glBindBuffer(this->binding, 0);

	if (currentVertexArray)
	{
		glBindVertexArray(currentVertexArray->vertexArray);
	}

	return *this;
}

//////////////////////////////////////////////////////////////////
RHI::UniformBuffer::UniformBuffer(RHI::State* state, const std::vector<RHI::Constant>& layout, RHI::Constant usage)
{
	glCreateBuffers(1, &this->buffer);
	this->dataViews = std::map<RHI::Constant, unsigned char*>();
	this->offsets = std::vector<int>(layout.size());
	this->sizes = std::vector<int>(layout.size());
	this->types = std::vector<RHI::Constant>(layout.size());
	this->size = 0;
	this->usage = usage;
	this->state = state;

	// -1 indicates unbound
	this->currentBase = -1;

	for (int i = 0, len = layout.size(); i < len; ++i)
	{
		RHI::Constant type = layout[i];
		switch (type)
		{
		case RHI::Constant::FLOAT:
		case RHI::Constant::INT:
		case RHI::Constant::UNSIGNED_INT:
		case RHI::Constant::BOOL:
			this->offsets[i] = this->size;
			this->sizes[i] = 1;

			if (type == RHI::Constant::INT)
			{
				types[i] = RHI::Constant::INT;
			}
			else if (type == RHI::Constant::UNSIGNED_INT)
			{
				types[i] = RHI::Constant::UNSIGNED_INT;
			}
			else
			{
				types[i] = RHI::Constant::FLOAT;
			}

			this->size++;
			break;
		case RHI::Constant::FLOAT_VEC2:
		case RHI::Constant::INT_VEC2:
		case RHI::Constant::UNSIGNED_INT_VEC2:
		case RHI::Constant::BOOL_VEC2:
			this->size += this->size % 2;
			this->offsets[i] = this->size;
			this->sizes[i] = 2;

			if (type == RHI::Constant::INT_VEC2)
			{
				this->types[i] = RHI::Constant::INT;
			}
			else if (type == RHI::Constant::UNSIGNED_INT_VEC2)
			{
				this->types[i] = RHI::Constant::UNSIGNED_INT;
			}
			else
			{
				this->types[i] = RHI::Constant::FLOAT;
			}

			this->size += 2;
			break;
		case RHI::Constant::FLOAT_VEC3:
		case RHI::Constant::INT_VEC3:
		case RHI::Constant::UNSIGNED_INT_VEC3:
		case RHI::Constant::BOOL_VEC3:
		case RHI::Constant::FLOAT_VEC4:
		case RHI::Constant::INT_VEC4:
		case RHI::Constant::UNSIGNED_INT_VEC4:
		case RHI::Constant::BOOL_VEC4:
			this->size += (4 - this->size % 4) % 4;
			this->offsets[i] = this->size;
			this->sizes[i] = 4;

			if (type == RHI::Constant::INT_VEC4 || type == RHI::Constant::INT_VEC3)
			{
				this->types[i] = RHI::Constant::INT;
			}
			else if (type == RHI::Constant::UNSIGNED_INT_VEC4 || type == RHI::Constant::UNSIGNED_INT_VEC3)
			{
				this->types[i] = RHI::Constant::UNSIGNED_INT;
			}
			else
			{
				this->types[i] = RHI::Constant::FLOAT;
			}

			this->size += 4;
			break;
		case RHI::Constant::FLOAT_MAT2:
		case RHI::Constant::FLOAT_MAT2x3:
		case RHI::Constant::FLOAT_MAT2x4:
			this->size += (4 - this->size % 4) % 4;
			this->offsets[i] = this->size;
			this->sizes[i] = 8;
			this->types[i] = RHI::Constant::FLOAT;

			this->size += 8;
			break;
		case RHI::Constant::FLOAT_MAT3:
		case RHI::Constant::FLOAT_MAT3x2:
		case RHI::Constant::FLOAT_MAT3x4:
			this->size += (4 - this->size % 4) % 4;
			this->offsets[i] = this->size;
			this->sizes[i] = 12;
			this->types[i] = RHI::Constant::FLOAT;

			this->size += 12;
			break;
		case RHI::Constant::FLOAT_MAT4:
		case RHI::Constant::FLOAT_MAT4x2:
		case RHI::Constant::FLOAT_MAT4x3:
			this->size += (4 - this->size % 4) % 4;
			this->offsets[i] = this->size;
			this->sizes[i] = 16;
			this->types[i] = RHI::Constant::FLOAT;

			this->size += 16;
			break;
		default:
			::Debug("Unsupported type for uniform buffer.");
		}
	}

	this->size += (4 - this->size % 4) % 4;

	this->data.resize(this->size * 4);
	this->dataViews[RHI::Constant::FLOAT] = &(this->data[0]);
	this->dataViews[RHI::Constant::INT] = &(this->data[0]);
	this->dataViews[RHI::Constant::UNSIGNED_INT] = &(this->data[0]);

	glBindBuffer(GL_UNIFORM_BUFFER, this->buffer);
	glBufferData(GL_UNIFORM_BUFFER, this->size * 4, nullptr, GetGLConstant(this->usage));
	glBindBuffer(GL_UNIFORM_BUFFER, 0);
}

RHI::UniformBuffer::~UniformBuffer()
{
	if (buffer)
	{
		glDeleteBuffers(1, &buffer);
		buffer = 0;

		if (this->currentBase != -1 && this->state->uniformBuffers[this->currentBase] == this)
		{
			this->state->uniformBuffers[this->currentBase] = nullptr;
		}
	}
}

/**
	 Update data for a given item in the buffer.
	 NOTE: Data is not sent the the GPU until the update() method is called!

	 @method
	 @param {number} index Index in the layout of item to set.
	 @param {ArrayBufferView} value Value to store at the layout location.
	 @return {UniformBuffer} The UniformBuffer object.
 */
RHI::UniformBuffer& RHI::UniformBuffer::Set(int index, void* value, unsigned int dataLength)
{
	unsigned char* view = this->dataViews[this->types[index]];

	if (this->sizes[index] == 1)
	{
		::MemCpy(&view[this->offsets[index] * 4], value, dataLength);
	}
	else
	{
		::MemCpy(&view[this->offsets[index] * 4], value, dataLength);
	}

	return *this;
}

/**
	Send stored buffer data to the GPU.

	@method
	@param {number} [index] Index in the layout of item to send to the GPU. If ommited, entire buffer is sent.
	@return {UniformBuffer} The UniformBuffer object.
*/
RHI::UniformBuffer& RHI::UniformBuffer::Update(int index = -1)
{
	unsigned char* data;
	int offset;
	int totalDataSize;

	if (index == -1)
	{
		offset = 0;

		data = &this->data[offset];

		totalDataSize = this->data.size();
	}
	else
	{
		offset = this->offsets[index] * 4;

		data = &this->data[offset];

		totalDataSize = this->sizes[index] * 4;
	}

	glBindBuffer(GL_UNIFORM_BUFFER, this->buffer);
	glBufferSubData(GL_UNIFORM_BUFFER, offset, totalDataSize, data);
	glBindBuffer(GL_UNIFORM_BUFFER, 0);

	return *this;
}

RHI::UniformBuffer& RHI::UniformBuffer::Bind(int base)
{
	UniformBuffer* currentBuffer = this->state->uniformBuffers[base];

	if (currentBuffer != this)
	{
		if (currentBuffer)
		{
			currentBuffer->currentBase = -1;
		}

		if (this->currentBase != -1)
		{
			this->state->uniformBuffers[this->currentBase] = nullptr;
		}

		glBindBufferBase(GL_UNIFORM_BUFFER, base, this->buffer);

		this->state->uniformBuffers[base] = this;
		this->currentBase = base;
	}

	return *this;
}

//////////////////////////////////////////////////////////////////
RHI::Texture::Texture(RHI::State* state)
{
}

RHI::Texture::~Texture()
{
}

//////////////////////////////////////////////////////////////////
RHI::Framebuffer::Framebuffer(RHI::State* state)
{
}

RHI::Framebuffer::~Framebuffer()
{
}

void RHI::Framebuffer::BindForDraw()
{
}

void RHI::Framebuffer::BindForRead()
{
}

//////////////////////////////////////////////////////////////////
RHI::DrawCall::DrawCall(RHI::State* state)
{
}

RHI::DrawCall::~DrawCall()
{
}

//////////////////////////////////////////////////////////////////
RHI::Query::Query(RHI::State* state, RHI::Constant target)
{
	this->state = state;
	glCreateQueries(GetGLConstant(target), 1, &this->query);
	this->target = target;
	this->active = false;
	this->result = 0;
}

RHI::Query& RHI::Query::Begin()
{
	if (!this->active)
	{
		glBeginQuery(GetGLConstant(this->target), this->query);
		this->result = 0;
	}

	return *this;
}

RHI::Query& RHI::Query::End()
{
	if (!this->active)
	{
		glEndQuery(GetGLConstant(this->target));
		this->active = true;
	}

	return *this;
}

bool RHI::Query::Ready()
{
	if (this->active)
	{
		GLint hasQuery;
		glGetQueryObjectiv(this->query, GL_QUERY_RESULT_AVAILABLE, &hasQuery);
		if (hasQuery)
		{
			this->active = false;
			glGetQueryObjectiv(this->query, GL_QUERY_RESULT, &(result));
			return true;
		}
	}

	return false;
}

RHI::Query::~Query()
{
	if (this->query)
	{
		glDeleteQueries(1, &(this->query));
		this->query = 0;
	}
}

//////////////////////////////////////////////////////////////////
RHI::State::State
(
	Program* program,
	VertexArray* vertexArray,
	TransformFeedback* transformFeedback,
	int activeTexture,
	std::vector<Texture*> textures,
	std::vector<UniformBuffer*> uniformBuffers,
	//freeUniformBufferBases: [],
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
	//freeUniformBufferBases: [];
	this->drawFramebuffer = drawFramebuffer;
	this->readFramebuffer = readFramebuffer;
}

RHI::State::~State()
{
}

//////////////////////////////////////////////////////////////////
RHI::RHI()
{
	this->width = Platform::GetWidth();
	this->height = Platform::GetHeight();
	this->viewportX = 0;
	this->viewportY = 0;
	this->viewportWidth = 0;
	this->viewportHeight = 0;
	this->currentDrawCalls = nullptr;
	this->emptyFragmentShader = nullptr;

	this->state = RHI::State(
		nullptr,
		nullptr,
		nullptr,
		-1,
		std::vector<Texture*>(GetDeviceInfo(RHI::Constant::MAX_TEXTURE_IMAGE_UNITS)),
		std::vector<UniformBuffer*>(GetDeviceInfo(RHI::Constant::MAX_UNIFORM_BUFFER_BINDINGS)),
		//freeUniformBufferBases : [] ,
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

RHI::~RHI()
{
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
RHI& RHI::ColorMask(bool r, bool g, bool b, bool a)
{
	glColorMask(r, g, b, a);

	return *this;
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
RHI& RHI::ClearColor(float r, float g, float b, float a)
{
	glClearColor(r, g, b, a);

	return *this;
}

/**
	Set the clear mask bits to use when calling clear().
	E.g. app.clearMask(PicoGL.COLOR_BUFFER_BIT).

	@method
	@param {GLEnum} mask Bit mask of buffers to clear.
	@return {App} The App object.
*/
RHI& RHI::ClearMask(bool clearColor, bool clearDepth, bool clearStencil)
{
	this->clearBits = 0;

	if (clearColor)
		this->clearBits |= GL_COLOR_BUFFER_BIT;

	if (clearDepth)
		this->clearBits |= GL_DEPTH_BUFFER_BIT;

	if (clearStencil)
		this->clearBits |= GL_STENCIL_BUFFER_BIT;

	return *this;
}

/**
	Clear the canvas

	@method
	@return {App} The App object.
*/
RHI& RHI::Clear()
{
	glClear(this->clearBits);

	return *this;
}

/**
	Bind a draw framebuffer to the WebGL context.

	@method
	@param {Framebuffer} framebuffer The Framebuffer object to bind.
	@see Framebuffer
	@return {App} The App object.
*/
RHI& RHI::DrawFramebuffer(RHI::Framebuffer* framebuffer)
{
	framebuffer->BindForDraw();

	return *this;
}

/**
	Bind a read framebuffer to the WebGL context.

	@method
	@param {Framebuffer} framebuffer The Framebuffer object to bind.
	@see Framebuffer
	@return {App} The App object.
*/
RHI& RHI::ReadFramebuffer(RHI::Framebuffer* framebuffer)
{
	framebuffer->BindForRead();

	return *this;
}

/**
	Switch back to the default framebuffer for drawing (i.e. draw to the screen).
	Note that this method resets the viewport to match the default framebuffer.

	@method
	@return {App} The App object.
*/
RHI& RHI::DefaultDrawFramebuffer()
{
	if (this->state.drawFramebuffer != nullptr)
	{
		glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
		this->state.drawFramebuffer = nullptr;
	}

	return *this;
}

/**
	Switch back to the default framebuffer for reading (i.e. read from the screen).

	@method
	@return {App} The App object.
*/
RHI& RHI::DefaultReadFramebuffer()
{
	if (this->state.readFramebuffer != nullptr)
	{
		glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);
		this->state.readFramebuffer = nullptr;
	}

	return *this;
}

/**
	Set the depth range.

	@method
	@param {number} near Minimum depth value.
	@param {number} far Maximum depth value.
	@return {App} The App object.
*/
RHI& RHI::DepthRange(float near, float far)
{
	glDepthRange(near, far);

	return *this;
}

/**
	Enable depth testing.

	@method
	@return {App} The App object.
*/
RHI& RHI::DepthTest()
{
	glEnable(GL_DEPTH_TEST);

	return *this;
}

/**
	Disable depth testing.

	@method
	@return {App} The App object.
*/
RHI& RHI::NoDepthTest()
{
	glDisable(GL_DEPTH_TEST);

	return *this;
}

/**
	Enable or disable writing to the depth buffer.

	@method
	@param {Boolean} mask The depth mask.
	@return {App} The App object.
*/
RHI& RHI::DepthMask(bool mask)
{
	glDepthMask(mask);

	return *this;
}

/**
	Set the depth test function. E.g. app.depthFunc(PicoGL.LEQUAL).

	@method
	@param {GLEnum} func The depth testing function to use.
	@return {App} The App object.
*/
RHI& RHI::DepthFunc(RHI::Constant func)
{
	glDepthFunc(GetGLConstant(func));

	return *this;
}

/**
	Enable blending.

	@method
	@return {App} The App object.
*/
RHI& RHI::Blend()
{
	glEnable(GL_BLEND);

	return *this;
}

/**
	Disable blending

	@method
	@return {App} The App object.
*/
RHI& RHI::NoBlend()
{
	glDisable(GL_BLEND);

	return *this;
}

/**
	Set the blend function. E.g. app.blendFunc(PicoGL.ONE, PicoGL.ONE_MINUS_SRC_ALPHA).

	@method
	@param {GLEnum} src The source blending weight.
	@param {GLEnum} dest The destination blending weight.
	@return {App} The App object.
*/
RHI& RHI::BlendFunc(RHI::Constant src, RHI::Constant dest)
{
	glBlendFunc(GetGLConstant(src), GetGLConstant(dest));

	return *this;
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
RHI& RHI::BlendFuncSeparate(RHI::Constant csrc, RHI::Constant cdest, RHI::Constant asrc, RHI::Constant adest)
{
	glBlendFuncSeparate(GetGLConstant(csrc), GetGLConstant(cdest), GetGLConstant(asrc), GetGLConstant(adest));

	return *this;
}

/**
	Enable stencil testing.
	NOTE: Only works if { stencil: true } passed as a
	context attribute when creating the App!

	@method
	@return {App} The App object.
*/
RHI& RHI::StencilTest()
{
	glEnable(GL_STENCIL_TEST);

	return *this;
}

/**
	Disable stencil testing.

	@method
	@return {App} The App object.
*/
RHI& RHI::NoStencilTest()
{
	glDisable(GL_STENCIL_TEST);

	return *this;
}


/**
	Enable scissor testing.

	@method
	@return {App} The App object.
*/
RHI& RHI::ScissorTest()
{
	glEnable(GL_SCISSOR_TEST);

	return *this;
}

/**
	Disable scissor testing.

	@method
	@return {App} The App object.
*/
RHI& RHI::NoScissorTest()
{
	glDisable(GL_SCISSOR_TEST);

	return *this;
}

/**
	Define the scissor box.

	@method
	@return {App} The App object.
*/
RHI& RHI::Scissor(int x, int y, int width, int height)
{
	glScissor(x, y, width, height);

	return *this;
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
RHI& RHI::StencilMask(unsigned int mask)
{
	glStencilMask(mask);

	return *this;
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
RHI& RHI::StencilMaskSeparate(RHI::Constant face, unsigned int mask)
{
	glStencilMaskSeparate(GetGLConstant(face), mask);

	return *this;
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
RHI& RHI::StencilFunc(RHI::Constant func, unsigned int ref, unsigned int mask)
{
	glStencilFunc(GetGLConstant(func), ref, mask);

	return *this;
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
RHI& RHI::StencilFuncSeparate(RHI::Constant face, RHI::Constant func,
	unsigned int ref, unsigned int mask)
{
	glStencilFuncSeparate(GetGLConstant(face), GetGLConstant(func), ref, mask);

	return *this;
}

RHI& RHI::StencilOp(RHI::Constant stencilFail, RHI::Constant depthFail, RHI::Constant pass)
{
	glStencilOp(GetGLConstant(stencilFail), GetGLConstant(depthFail), GetGLConstant(pass));

	return *this;
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
RHI& RHI::StencilOpSeparate(RHI::Constant face, RHI::Constant stencilFail, RHI::Constant depthFail, RHI::Constant pass)
{
	glStencilOpSeparate(GetGLConstant(face), GetGLConstant(stencilFail), GetGLConstant(depthFail), GetGLConstant(pass));

	return *this;
}

/**
	Enable rasterization step.

	@method
	@return {App} The App object.
*/
RHI& RHI::Rasterize()
{
	glDisable(GL_RASTERIZER_DISCARD);

	return *this;
}

/**
	Disable rasterization step.

	@method
	@return {App} The App object.
*/
RHI& RHI::NoRasterize()
{
	glEnable(GL_RASTERIZER_DISCARD);

	return *this;
}

/**
	Enable backface culling.

	@method
	@return {App} The App object.
*/
RHI& RHI::CullBackfaces()
{
	glEnable(GL_CULL_FACE);

	return *this;
}

/**
	Disable backface culling.

	@method
	@return {App} The App object.
*/
RHI& RHI::NoCullBackfaces()
{
	glDisable(GL_CULL_FACE);

	return *this;
}

RHI& RHI::FrontFaceClockwise()
{
	glFrontFace(GL_CW);

	return *this;
}

RHI& RHI::FrontFaceCounterClockwise()
{
	glFrontFace(GL_CCW);

	return *this;
}

/**
	Enable the EXT_color_buffer_float extension. Allows for creating float textures as
	render targets on FrameBuffer objects.

	@method
	@see Framebuffer
	@return {App} The App object.
*/
RHI& RHI::FloatRenderTargets()
{
	floatRenderTargetsEnabled = glfwExtensionSupported("EXT_color_buffer_float");

	return *this;
}

RHI& RHI::LinearFloatTextures()
{
	linearFloatTexturesEnabled = glfwExtensionSupported("OES_texture_float_linear");

	return *this;
}

RHI& RHI::S3TCTextures()
{
	s3tcTexturesEnabled = glfwExtensionSupported("WEBGL_compressed_texture_s3tc");

	if (s3tcTexturesEnabled)
	{
		std::map<RHI::Constant, RHI::Constant>& compressedTypes = TEXTURE_FORMAT_DEFAULTS[RHI::Constant::COMPRESSED_TYPES];
		compressedTypes[RHI::Constant::COMPRESSED_RGB_S3TC_DXT1_EXT] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_RGBA_S3TC_DXT1_EXT] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_RGBA_S3TC_DXT3_EXT] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_RGBA_S3TC_DXT5_EXT] = RHI::Constant::TRUE;
	}

	s3tcSRGBTexturesEnabled = glfwExtensionSupported("WEBGL_compressed_texture_s3tc_srgb");

	if (s3tcSRGBTexturesEnabled)
	{
		std::map<RHI::Constant, RHI::Constant>& compressedTypes = TEXTURE_FORMAT_DEFAULTS[RHI::Constant::COMPRESSED_TYPES];

		compressedTypes[RHI::Constant::COMPRESSED_SRGB_S3TC_DXT1_EXT] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT] = RHI::Constant::TRUE;
	}

	return *this;
}

RHI& RHI::ETCTextures()
{
	etcTexturesEnabled = glfwExtensionSupported("WEBGL_compressed_texture_etc");

	if (etcTexturesEnabled)
	{
		std::map<RHI::Constant, RHI::Constant>& compressedTypes = TEXTURE_FORMAT_DEFAULTS[RHI::Constant::COMPRESSED_TYPES];

		compressedTypes[RHI::Constant::COMPRESSED_R11_EAC] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_SIGNED_R11_EAC] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_RG11_EAC] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_SIGNED_RG11_EAC] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_RGB8_ETC2] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_SRGB8_ETC2] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_RGBA8_ETC2_EAC] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_SRGB8_ALPHA8_ETC2_EAC] = RHI::Constant::TRUE;
	}

	return *this;
}

RHI& RHI::ASTCTextures()
{
	astcTexturesEnabled = glfwExtensionSupported("WEBGL_compressed_texture_astc");

	if (astcTexturesEnabled)
	{
		std::map<RHI::Constant, RHI::Constant>& compressedTypes = TEXTURE_FORMAT_DEFAULTS[RHI::Constant::COMPRESSED_TYPES];

		compressedTypes[RHI::Constant::COMPRESSED_RGBA_ASTC_4x4_KHR] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_RGBA_ASTC_5x4_KHR] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_RGBA_ASTC_5x5_KHR] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_RGBA_ASTC_6x5_KHR] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_RGBA_ASTC_6x6_KHR] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_RGBA_ASTC_8x5_KHR] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_RGBA_ASTC_8x6_KHR] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_RGBA_ASTC_8x8_KHR] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_RGBA_ASTC_10x5_KHR] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_RGBA_ASTC_10x6_KHR] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_RGBA_ASTC_10x8_KHR] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_RGBA_ASTC_10x10_KHR] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_RGBA_ASTC_12x10_KHR] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_RGBA_ASTC_12x12_KHR] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR] = RHI::Constant::TRUE;
		compressedTypes[RHI::Constant::COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR] = RHI::Constant::TRUE;
	}

	return *this;
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

	@method
	@return {App} The App object.
*/
/*
RHI& RHI::PVRTCTextures()
{
	pvrtcTexturesEnabled = glfwExtensionSupported("WEBGL_compressed_texture_pvrtc");

	if (pvrtcTexturesEnabled)
	{
		std::map<RHI::Constant, RHI::Constant>& compressedTypes = TEXTURE_FORMAT_DEFAULTS[RHI::Constant::COMPRESSED_TYPES];

		compressedTypes[RHI::Constant::COMPRESSED_RGB_PVRTC_4BPPV1_IMG] = true;
		compressedTypes[RHI::Constant::COMPRESSED_RGB_PVRTC_2BPPV1_IMG] = true;
		compressedTypes[RHI::Constant::COMPRESSED_RGBA_PVRTC_4BPPV1_IMG] = true;
		compressedTypes[RHI::Constant::COMPRESSED_RGBA_PVRTC_2BPPV1_IMG] = true;
	}

	return *this;
}
*/

RHI& RHI::ReadPixel(int x, int y, void* outColor)
{
	glReadPixels
	(
		x, y, 1, 1,
		GetGLConstant(RHI::Constant::RGBA),
		GetGLConstant(RHI::Constant::UNSIGNED_BYTE), outColor
	);

	return *this;
}

RHI& RHI::ReadPixel(int x, int y, int w, int h, void* outColor)
{
	glReadPixels
	(
		x, y, w, h,
		GetGLConstant(RHI::Constant::RGBA),
		GetGLConstant(RHI::Constant::UNSIGNED_BYTE), outColor
	);

	return *this;
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
RHI& RHI::Viewport(int x, int y, int width, int height)
{
	if (this->viewportWidth != width || this->viewportHeight != height || this->viewportX != x || this->viewportY != y)
	{
		this->viewportX = x;
		this->viewportY = y;
		this->viewportWidth = width;
		this->viewportHeight = height;

		glViewport(x, y, this->viewportWidth, this->viewportHeight);
	}

	return *this;
}

/**
	Set the viewport to the full canvas.

	@method
	@return {App} The App object.
*/
RHI& RHI::DefaultViewport()
{
	Viewport(0, 0, this->width, this->height);

	return *this;
}

/**
	Resize the drawing surface.

	@method
	@param {number} width The new canvas width.
	@param {number} height The new canvas height.
	@return {App} The App object.
*/
RHI& RHI::Resize(int width, int height)
{
	// this->canvas.width = width;
	// this->canvas.height = height;

	this->width = width;
	this->height = height;
	this->viewport = IVector4(0, 0, this->width, this->height);

	return *this;
}

/**
	Create a program.

	@method
	@param {Shader|string} vertexShader Vertex shader object or source code.
	@param {Shader|string} fragmentShader Fragment shader object or source code.
	@param {Array} [xformFeedbackVars] Transform feedback varyings.
	@return {Program} New Program object.
*/
RHI::Program* RHI::CreateProgram(const char* vsSource, const char* fsSource, const std::vector<const char*>& xformFeedbackVars)
{
	return new RHI::Program(&this->state, vsSource, fsSource, xformFeedbackVars);
}

/**
	Create a shader. Creating a shader separately from a program allows for
	shader reuse.

	@method
	@param {GLEnum} type Shader type.
	@param {string} source Shader source.
	@return {Shader} New Shader object.
*/
RHI::Shader* RHI::CreateShader(RHI::Constant type, const char* source)
{
	return new RHI::Shader(&this->state, type, source);
}

/**
	Create a vertex array.

	@method
	@return {VertexArray} New VertexArray object.
*/
RHI::VertexArray* RHI::CreateVertexArray()
{
	return new RHI::VertexArray(&this->state);
}

/**
	Create a transform feedback object.

	@method
	@return {TransformFeedback} New TransformFeedback object.
*/
RHI::TransformFeedback* RHI::CreateTransformFeedback()
{
	return new RHI::TransformFeedback(&this->state);
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
RHI::VertexBuffer* RHI::CreateVertexBuffer(RHI::Constant type, int itemSize, void* data, unsigned int dataLength, RHI::Constant usage)
{
	return new RHI::VertexBuffer(&this->state, type, itemSize, data, dataLength, usage);
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
RHI::VertexBuffer* RHI::CreateMatrixBuffer(RHI::Constant type, void* data, unsigned int dataLength, RHI::Constant usage)
{
	return new RHI::VertexBuffer(&this->state, type, 0, data, dataLength, usage);
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
RHI::VertexBuffer* RHI::CreateIndexBuffer(RHI::Constant type, int itemSize, void* data, unsigned int dataLength, RHI::Constant usage)
{
	return new RHI::VertexBuffer(&this->state, type, itemSize, data, dataLength, usage, true);
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
RHI::UniformBuffer* RHI::CreateUniformBuffer(const std::vector<RHI::Constant>& layout, RHI::Constant usage)
{
	return new RHI::UniformBuffer(&this->state, layout, usage);
}



#if 0

/*
PicoGL.js v0.8.8

The MIT License (MIT)

Copyright (c) 2017 Tarek Sherif

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

(function webpackUniversalModuleDefinition(root, factory) {
	if (typeof exports == = 'object' && typeof module == = 'object')
		module.exports = factory();
	else if (typeof define == = 'function' && define.amd)
		define([], factory);
	else if (typeof exports == = 'object')
		exports["PicoGL"] = factory();
	else
		root["PicoGL"] = factory();
})(this, function() {
	return /******/ (function(modules) { // webpackBootstrap
	/******/ 	// The module cache
		/******/ 	var installedModules = {};
		/******/
		/******/ 	// The require function
		/******/ 	function __webpack_require__(moduleId) {
			/******/
			/******/ 		// Check if module is in cache
			/******/ 		if (installedModules[moduleId]) {
				/******/ 			return installedModules[moduleId].exports;
				/******/
			}
			/******/ 		// Create a new module (and put it into the cache)
			/******/ 		var module = installedModules[moduleId] = {
				/******/ 			i: moduleId,
				/******/ 			l : false,
				/******/ 			exports : {}
			/******/ };
			/******/
			/******/ 		// Execute the module function
			/******/ 		modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
			/******/
			/******/ 		// Flag the module as loaded
			/******/ 		module.l = true;
			/******/
			/******/ 		// Return the exports of the module
			/******/ 		return module.exports;
			/******/
		}
		/******/
		/******/
		/******/ 	// expose the modules object (__webpack_modules__)
		/******/ 	__webpack_require__.m = modules;
		/******/
		/******/ 	// expose the module cache
		/******/ 	__webpack_require__.c = installedModules;
		/******/
		/******/ 	// define getter function for harmony exports
		/******/ 	__webpack_require__.d = function(exports, name, getter) {
			/******/ 		if (!__webpack_require__.o(exports, name)) {
				/******/ 			Object.defineProperty(exports, name, {
					/******/ 				configurable: false,
					/******/ 				enumerable : true,
					/******/ 				get : getter
					/******/ });
				/******/
			}
			/******/
		};
		/******/
		/******/ 	// getDefaultExport function for compatibility with non-harmony modules
		/******/ 	__webpack_require__.n = function(module) {
			/******/ 		var getter = module && module.__esModule ?
				/******/ 			function getDefault() { return module['default']; } :
				/******/ 			function getModuleExports() { return module; };
			/******/ 		__webpack_require__.d(getter, 'a', getter);
			/******/ 		return getter;
			/******/
		};
		/******/
		/******/ 	// Object.prototype.hasOwnProperty.call
		/******/ 	__webpack_require__.o = function(object, property) { return Object.prototype.hasOwnProperty.call(object, property); };
		/******/
		/******/ 	// __webpack_public_path__
		/******/ 	__webpack_require__.p = "";
		/******/
		/******/ 	// Load entry module and return exports
		/******/ 	return __webpack_require__(__webpack_require__.s = 4);
		/******/
	})
		/************************************************************************/
		/******/ ([
			/* 0 */
			/***/ (function(module, exports, __webpack_require__) {

				"use strict";
				///////////////////////////////////////////////////////////////////////////////////
				// The MIT License (MIT)
				//
				// Copyright (c) 2017 Tarek Sherif
				//
				// Permission is hereby granted, free of charge, to any person obtaining a copy of
				// this software and associated documentation files (the "Software"), to deal in
				// the Software without restriction, including without limitation the rights to
				// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
				// the Software, and to permit persons to whom the Software is furnished to do so,
				// subject to the following conditions:
				//
				// The above copyright notice and this permission notice shall be included in all
				// copies or substantial portions of the Software.
				//
				// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
				// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
				// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
				// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
				// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
				// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
				///////////////////////////////////////////////////////////////////////////////////



				let canvas = document.createElement("canvas");
				let gl = canvas.getContext("webgl2");

				// https://www.khronos.org/registry/webgl/specs/1.0/
				// https://www.khronos.org/registry/webgl/specs/latest/2.0/#1.1
				const CONSTANTS = {
					DEPTH_BUFFER_BIT: 0x00000100,
					STENCIL_BUFFER_BIT : 0x00000400,
					COLOR_BUFFER_BIT : 0x00004000,
					POINTS : 0x0000,
					LINES : 0x0001,
					LINE_LOOP : 0x0002,
					LINE_STRIP : 0x0003,
					TRIANGLES : 0x0004,
					TRIANGLE_STRIP : 0x0005,
					TRIANGLE_FAN : 0x0006,
					ZERO : 0,
					ONE : 1,
					SRC_COLOR : 0x0300,
					ONE_MINUS_SRC_COLOR : 0x0301,
					SRC_ALPHA : 0x0302,
					ONE_MINUS_SRC_ALPHA : 0x0303,
					DST_ALPHA : 0x0304,
					ONE_MINUS_DST_ALPHA : 0x0305,
					DST_COLOR : 0x0306,
					ONE_MINUS_DST_COLOR : 0x0307,
					SRC_ALPHA_SATURATE : 0x0308,
					FUNC_ADD : 0x8006,
					BLEND_EQUATION : 0x8009,
					BLEND_EQUATION_RGB : 0x8009,
					BLEND_EQUATION_ALPHA : 0x883D,
					FUNC_SUBTRACT : 0x800A,
					FUNC_REVERSE_SUBTRACT : 0x800B,
					BLEND_DST_RGB : 0x80C8,
					BLEND_SRC_RGB : 0x80C9,
					BLEND_DST_ALPHA : 0x80CA,
					BLEND_SRC_ALPHA : 0x80CB,
					CONSTANT_COLOR : 0x8001,
					ONE_MINUS_CONSTANT_COLOR : 0x8002,
					CONSTANT_ALPHA : 0x8003,
					ONE_MINUS_CONSTANT_ALPHA : 0x8004,
					BLEND_COLOR : 0x8005,
					ARRAY_BUFFER : 0x8892,
					ELEMENT_ARRAY_BUFFER : 0x8893,
					ARRAY_BUFFER_BINDING : 0x8894,
					ELEMENT_ARRAY_BUFFER_BINDING : 0x8895,
					STREAM_DRAW : 0x88E0,
					STATIC_DRAW : 0x88E4,
					DYNAMIC_DRAW : 0x88E8,
					BUFFER_SIZE : 0x8764,
					BUFFER_USAGE : 0x8765,
					CURRENT_VERTEX_ATTRIB : 0x8626,
					FRONT : 0x0404,
					BACK : 0x0405,
					FRONT_AND_BACK : 0x0408,
					CULL_FACE : 0x0B44,
					BLEND : 0x0BE2,
					DITHER : 0x0BD0,
					STENCIL_TEST : 0x0B90,
					DEPTH_TEST : 0x0B71,
					SCISSOR_TEST : 0x0C11,
					POLYGON_OFFSET_FILL : 0x8037,
					SAMPLE_ALPHA_TO_COVERAGE : 0x809E,
					SAMPLE_COVERAGE : 0x80A0,
					NO_ERROR : 0,
					INVALID_ENUM : 0x0500,
					INVALID_VALUE : 0x0501,
					INVALID_OPERATION : 0x0502,
					OUT_OF_MEMORY : 0x0505,
					CW : 0x0900,
					CCW : 0x0901,
					LINE_WIDTH : 0x0B21,
					ALIASED_POINT_SIZE_RANGE : 0x846D,
					ALIASED_LINE_WIDTH_RANGE : 0x846E,
					CULL_FACE_MODE : 0x0B45,
					FRONT_FACE : 0x0B46,
					DEPTH_RANGE : 0x0B70,
					DEPTH_WRITEMASK : 0x0B72,
					DEPTH_CLEAR_VALUE : 0x0B73,
					DEPTH_FUNC : 0x0B74,
					STENCIL_CLEAR_VALUE : 0x0B91,
					STENCIL_FUNC : 0x0B92,
					STENCIL_FAIL : 0x0B94,
					STENCIL_PASS_DEPTH_FAIL : 0x0B95,
					STENCIL_PASS_DEPTH_PASS : 0x0B96,
					STENCIL_REF : 0x0B97,
					STENCIL_VALUE_MASK : 0x0B93,
					STENCIL_WRITEMASK : 0x0B98,
					STENCIL_BACK_FUNC : 0x8800,
					STENCIL_BACK_FAIL : 0x8801,
					STENCIL_BACK_PASS_DEPTH_FAIL : 0x8802,
					STENCIL_BACK_PASS_DEPTH_PASS : 0x8803,
					STENCIL_BACK_REF : 0x8CA3,
					STENCIL_BACK_VALUE_MASK : 0x8CA4,
					STENCIL_BACK_WRITEMASK : 0x8CA5,
					VIEWPORT : 0x0BA2,
					SCISSOR_BOX : 0x0C10,
					COLOR_CLEAR_VALUE : 0x0C22,
					COLOR_WRITEMASK : 0x0C23,
					UNPACK_ALIGNMENT : 0x0CF5,
					PACK_ALIGNMENT : 0x0D05,
					MAX_TEXTURE_SIZE : 0x0D33,
					MAX_VIEWPORT_DIMS : 0x0D3A,
					SUBPIXEL_BITS : 0x0D50,
					RED_BITS : 0x0D52,
					GREEN_BITS : 0x0D53,
					BLUE_BITS : 0x0D54,
					ALPHA_BITS : 0x0D55,
					DEPTH_BITS : 0x0D56,
					STENCIL_BITS : 0x0D57,
					POLYGON_OFFSET_UNITS : 0x2A00,
					POLYGON_OFFSET_FACTOR : 0x8038,
					TEXTURE_BINDING_2D : 0x8069,
					SAMPLE_BUFFERS : 0x80A8,
					SAMPLES : 0x80A9,
					SAMPLE_COVERAGE_VALUE : 0x80AA,
					SAMPLE_COVERAGE_INVERT : 0x80AB,
					COMPRESSED_TEXTURE_FORMATS : 0x86A3,
					DONT_CARE : 0x1100,
					FASTEST : 0x1101,
					NICEST : 0x1102,
					GENERATE_MIPMAP_HINT : 0x8192,
					BYTE : 0x1400,
					UNSIGNED_BYTE : 0x1401,
					SHORT : 0x1402,
					UNSIGNED_SHORT : 0x1403,
					INT : 0x1404,
					UNSIGNED_INT : 0x1405,
					FLOAT : 0x1406,
					DEPTH_COMPONENT : 0x1902,
					ALPHA : 0x1906,
					RGB : 0x1907,
					RGBA : 0x1908,
					LUMINANCE : 0x1909,
					LUMINANCE_ALPHA : 0x190A,
					UNSIGNED_SHORT_4_4_4_4 : 0x8033,
					UNSIGNED_SHORT_5_5_5_1 : 0x8034,
					UNSIGNED_SHORT_5_6_5 : 0x8363,
					FRAGMENT_SHADER : 0x8B30,
					VERTEX_SHADER : 0x8B31,
					MAX_VERTEX_ATTRIBS : 0x8869,
					MAX_VERTEX_UNIFORM_VECTORS : 0x8DFB,
					MAX_VARYING_VECTORS : 0x8DFC,
					MAX_COMBINED_TEXTURE_IMAGE_UNITS : 0x8B4D,
					MAX_VERTEX_TEXTURE_IMAGE_UNITS : 0x8B4C,
					MAX_TEXTURE_IMAGE_UNITS : 0x8872,
					MAX_FRAGMENT_UNIFORM_VECTORS : 0x8DFD,
					SHADER_TYPE : 0x8B4F,
					DELETE_STATUS : 0x8B80,
					LINK_STATUS : 0x8B82,
					VALIDATE_STATUS : 0x8B83,
					ATTACHED_SHADERS : 0x8B85,
					ACTIVE_UNIFORMS : 0x8B86,
					ACTIVE_ATTRIBUTES : 0x8B89,
					SHADING_LANGUAGE_VERSION : 0x8B8C,
					CURRENT_PROGRAM : 0x8B8D,
					NEVER : 0x0200,
					LESS : 0x0201,
					EQUAL : 0x0202,
					LEQUAL : 0x0203,
					GREATER : 0x0204,
					NOTEQUAL : 0x0205,
					GEQUAL : 0x0206,
					ALWAYS : 0x0207,
					KEEP : 0x1E00,
					REPLACE : 0x1E01,
					INCR : 0x1E02,
					DECR : 0x1E03,
					INVERT : 0x150A,
					INCR_WRAP : 0x8507,
					DECR_WRAP : 0x8508,
					VENDOR : 0x1F00,
					RENDERER : 0x1F01,
					VERSION : 0x1F02,
					NEAREST : 0x2600,
					LINEAR : 0x2601,
					NEAREST_MIPMAP_NEAREST : 0x2700,
					LINEAR_MIPMAP_NEAREST : 0x2701,
					NEAREST_MIPMAP_LINEAR : 0x2702,
					LINEAR_MIPMAP_LINEAR : 0x2703,
					TEXTURE_MAG_FILTER : 0x2800,
					TEXTURE_MIN_FILTER : 0x2801,
					TEXTURE_WRAP_S : 0x2802,
					TEXTURE_WRAP_T : 0x2803,
					TEXTURE_2D : 0x0DE1,
					TEXTURE : 0x1702,
					TEXTURE_CUBE_MAP : 0x8513,
					TEXTURE_BINDING_CUBE_MAP : 0x8514,
					TEXTURE_CUBE_MAP_POSITIVE_X : 0x8515,
					TEXTURE_CUBE_MAP_NEGATIVE_X : 0x8516,
					TEXTURE_CUBE_MAP_POSITIVE_Y : 0x8517,
					TEXTURE_CUBE_MAP_NEGATIVE_Y : 0x8518,
					TEXTURE_CUBE_MAP_POSITIVE_Z : 0x8519,
					TEXTURE_CUBE_MAP_NEGATIVE_Z : 0x851A,
					MAX_CUBE_MAP_TEXTURE_SIZE : 0x851C,
					TEXTURE0 : 0x84C0,
					TEXTURE1 : 0x84C1,
					TEXTURE2 : 0x84C2,
					TEXTURE3 : 0x84C3,
					TEXTURE4 : 0x84C4,
					TEXTURE5 : 0x84C5,
					TEXTURE6 : 0x84C6,
					TEXTURE7 : 0x84C7,
					TEXTURE8 : 0x84C8,
					TEXTURE9 : 0x84C9,
					TEXTURE10 : 0x84CA,
					TEXTURE11 : 0x84CB,
					TEXTURE12 : 0x84CC,
					TEXTURE13 : 0x84CD,
					TEXTURE14 : 0x84CE,
					TEXTURE15 : 0x84CF,
					TEXTURE16 : 0x84D0,
					TEXTURE17 : 0x84D1,
					TEXTURE18 : 0x84D2,
					TEXTURE19 : 0x84D3,
					TEXTURE20 : 0x84D4,
					TEXTURE21 : 0x84D5,
					TEXTURE22 : 0x84D6,
					TEXTURE23 : 0x84D7,
					TEXTURE24 : 0x84D8,
					TEXTURE25 : 0x84D9,
					TEXTURE26 : 0x84DA,
					TEXTURE27 : 0x84DB,
					TEXTURE28 : 0x84DC,
					TEXTURE29 : 0x84DD,
					TEXTURE30 : 0x84DE,
					TEXTURE31 : 0x84DF,
					ACTIVE_TEXTURE : 0x84E0,
					REPEAT : 0x2901,
					CLAMP_TO_EDGE : 0x812F,
					MIRRORED_REPEAT : 0x8370,
					FLOAT_VEC2 : 0x8B50,
					FLOAT_VEC3 : 0x8B51,
					FLOAT_VEC4 : 0x8B52,
					INT_VEC2 : 0x8B53,
					INT_VEC3 : 0x8B54,
					INT_VEC4 : 0x8B55,
					BOOL : 0x8B56,
					BOOL_VEC2 : 0x8B57,
					BOOL_VEC3 : 0x8B58,
					BOOL_VEC4 : 0x8B59,
					FLOAT_MAT2 : 0x8B5A,
					FLOAT_MAT3 : 0x8B5B,
					FLOAT_MAT4 : 0x8B5C,
					SAMPLER_2D : 0x8B5E,
					SAMPLER_CUBE : 0x8B60,
					VERTEX_ATTRIB_ARRAY_ENABLED : 0x8622,
					VERTEX_ATTRIB_ARRAY_SIZE : 0x8623,
					VERTEX_ATTRIB_ARRAY_STRIDE : 0x8624,
					VERTEX_ATTRIB_ARRAY_TYPE : 0x8625,
					VERTEX_ATTRIB_ARRAY_NORMALIZED : 0x886A,
					VERTEX_ATTRIB_ARRAY_POINTER : 0x8645,
					VERTEX_ATTRIB_ARRAY_BUFFER_BINDING : 0x889F,
					IMPLEMENTATION_COLOR_READ_TYPE : 0x8B9A,
					IMPLEMENTATION_COLOR_READ_FORMAT : 0x8B9B,
					COMPILE_STATUS : 0x8B81,
					LOW_FLOAT : 0x8DF0,
					MEDIUM_FLOAT : 0x8DF1,
					HIGH_FLOAT : 0x8DF2,
					LOW_INT : 0x8DF3,
					MEDIUM_INT : 0x8DF4,
					HIGH_INT : 0x8DF5,
					FRAMEBUFFER : 0x8D40,
					RENDERBUFFER : 0x8D41,
					RGBA4 : 0x8056,
					RGB5_A1 : 0x8057,
					RGB565 : 0x8D62,
					DEPTH_COMPONENT16 : 0x81A5,
					STENCIL_INDEX : 0x1901,
					STENCIL_INDEX8 : 0x8D48,
					DEPTH_STENCIL : 0x84F9,
					RENDERBUFFER_WIDTH : 0x8D42,
					RENDERBUFFER_HEIGHT : 0x8D43,
					RENDERBUFFER_INTERNAL_FORMAT : 0x8D44,
					RENDERBUFFER_RED_SIZE : 0x8D50,
					RENDERBUFFER_GREEN_SIZE : 0x8D51,
					RENDERBUFFER_BLUE_SIZE : 0x8D52,
					RENDERBUFFER_ALPHA_SIZE : 0x8D53,
					RENDERBUFFER_DEPTH_SIZE : 0x8D54,
					RENDERBUFFER_STENCIL_SIZE : 0x8D55,
					FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE : 0x8CD0,
					FRAMEBUFFER_ATTACHMENT_OBJECT_NAME : 0x8CD1,
					FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL : 0x8CD2,
					FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE : 0x8CD3,
					COLOR_ATTACHMENT0 : 0x8CE0,
					DEPTH_ATTACHMENT : 0x8D00,
					STENCIL_ATTACHMENT : 0x8D20,
					DEPTH_STENCIL_ATTACHMENT : 0x821A,
					NONE : 0,
					FRAMEBUFFER_COMPLETE : 0x8CD5,
					FRAMEBUFFER_INCOMPLETE_ATTACHMENT : 0x8CD6,
					FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT : 0x8CD7,
					FRAMEBUFFER_INCOMPLETE_DIMENSIONS : 0x8CD9,
					FRAMEBUFFER_UNSUPPORTED : 0x8CDD,
					FRAMEBUFFER_BINDING : 0x8CA6,
					RENDERBUFFER_BINDING : 0x8CA7,
					MAX_RENDERBUFFER_SIZE : 0x84E8,
					INVALID_FRAMEBUFFER_OPERATION : 0x0506,
					UNPACK_FLIP_Y_WEBGL : 0x9240,
					UNPACK_PREMULTIPLY_ALPHA_WEBGL : 0x9241,
					CONTEXT_LOST_WEBGL : 0x9242,
					UNPACK_COLORSPACE_CONVERSION_WEBGL : 0x9243,
					BROWSER_DEFAULT_WEBGL : 0x9244,
					READ_BUFFER : 0x0C02,
					UNPACK_ROW_LENGTH : 0x0CF2,
					UNPACK_SKIP_ROWS : 0x0CF3,
					UNPACK_SKIP_PIXELS : 0x0CF4,
					PACK_ROW_LENGTH : 0x0D02,
					PACK_SKIP_ROWS : 0x0D03,
					PACK_SKIP_PIXELS : 0x0D04,
					COLOR : 0x1800,
					DEPTH : 0x1801,
					STENCIL : 0x1802,
					RED : 0x1903,
					RGB8 : 0x8051,
					RGBA8 : 0x8058,
					RGB10_A2 : 0x8059,
					TEXTURE_BINDING_3D : 0x806A,
					UNPACK_SKIP_IMAGES : 0x806D,
					UNPACK_IMAGE_HEIGHT : 0x806E,
					TEXTURE_3D : 0x806F,
					TEXTURE_WRAP_R : 0x8072,
					MAX_3D_TEXTURE_SIZE : 0x8073,
					UNSIGNED_INT_2_10_10_10_REV : 0x8368,
					MAX_ELEMENTS_VERTICES : 0x80E8,
					MAX_ELEMENTS_INDICES : 0x80E9,
					TEXTURE_MIN_LOD : 0x813A,
					TEXTURE_MAX_LOD : 0x813B,
					TEXTURE_BASE_LEVEL : 0x813C,
					TEXTURE_MAX_LEVEL : 0x813D,
					MIN : 0x8007,
					MAX : 0x8008,
					DEPTH_COMPONENT24 : 0x81A6,
					MAX_TEXTURE_LOD_BIAS : 0x84FD,
					TEXTURE_COMPARE_MODE : 0x884C,
					TEXTURE_COMPARE_FUNC : 0x884D,
					CURRENT_QUERY : 0x8865,
					QUERY_RESULT : 0x8866,
					QUERY_RESULT_AVAILABLE : 0x8867,
					STREAM_READ : 0x88E1,
					STREAM_COPY : 0x88E2,
					STATIC_READ : 0x88E5,
					STATIC_COPY : 0x88E6,
					DYNAMIC_READ : 0x88E9,
					DYNAMIC_COPY : 0x88EA,
					MAX_DRAW_BUFFERS : 0x8824,
					DRAW_BUFFER0 : 0x8825,
					DRAW_BUFFER1 : 0x8826,
					DRAW_BUFFER2 : 0x8827,
					DRAW_BUFFER3 : 0x8828,
					DRAW_BUFFER4 : 0x8829,
					DRAW_BUFFER5 : 0x882A,
					DRAW_BUFFER6 : 0x882B,
					DRAW_BUFFER7 : 0x882C,
					DRAW_BUFFER8 : 0x882D,
					DRAW_BUFFER9 : 0x882E,
					DRAW_BUFFER10 : 0x882F,
					DRAW_BUFFER11 : 0x8830,
					DRAW_BUFFER12 : 0x8831,
					DRAW_BUFFER13 : 0x8832,
					DRAW_BUFFER14 : 0x8833,
					DRAW_BUFFER15 : 0x8834,
					MAX_FRAGMENT_UNIFORM_COMPONENTS : 0x8B49,
					MAX_VERTEX_UNIFORM_COMPONENTS : 0x8B4A,
					SAMPLER_3D : 0x8B5F,
					SAMPLER_2D_SHADOW : 0x8B62,
					FRAGMENT_SHADER_DERIVATIVE_HINT : 0x8B8B,
					PIXEL_PACK_BUFFER : 0x88EB,
					PIXEL_UNPACK_BUFFER : 0x88EC,
					PIXEL_PACK_BUFFER_BINDING : 0x88ED,
					PIXEL_UNPACK_BUFFER_BINDING : 0x88EF,
					FLOAT_MAT2x3 : 0x8B65,
					FLOAT_MAT2x4 : 0x8B66,
					FLOAT_MAT3x2 : 0x8B67,
					FLOAT_MAT3x4 : 0x8B68,
					FLOAT_MAT4x2 : 0x8B69,
					FLOAT_MAT4x3 : 0x8B6A,
					SRGB : 0x8C40,
					SRGB8 : 0x8C41,
					SRGB8_ALPHA8 : 0x8C43,
					COMPARE_REF_TO_TEXTURE : 0x884E,
					RGBA32F : 0x8814,
					RGB32F : 0x8815,
					RGBA16F : 0x881A,
					RGB16F : 0x881B,
					VERTEX_ATTRIB_ARRAY_INTEGER : 0x88FD,
					MAX_ARRAY_TEXTURE_LAYERS : 0x88FF,
					MIN_PROGRAM_TEXEL_OFFSET : 0x8904,
					MAX_PROGRAM_TEXEL_OFFSET : 0x8905,
					MAX_VARYING_COMPONENTS : 0x8B4B,
					TEXTURE_2D_ARRAY : 0x8C1A,
					TEXTURE_BINDING_2D_ARRAY : 0x8C1D,
					R11F_G11F_B10F : 0x8C3A,
					UNSIGNED_INT_10F_11F_11F_REV : 0x8C3B,
					RGB9_E5 : 0x8C3D,
					UNSIGNED_INT_5_9_9_9_REV : 0x8C3E,
					TRANSFORM_FEEDBACK_BUFFER_MODE : 0x8C7F,
					MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS : 0x8C80,
					TRANSFORM_FEEDBACK_VARYINGS : 0x8C83,
					TRANSFORM_FEEDBACK_BUFFER_START : 0x8C84,
					TRANSFORM_FEEDBACK_BUFFER_SIZE : 0x8C85,
					TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN : 0x8C88,
					RASTERIZER_DISCARD : 0x8C89,
					MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS : 0x8C8A,
					MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS : 0x8C8B,
					INTERLEAVED_ATTRIBS : 0x8C8C,
					SEPARATE_ATTRIBS : 0x8C8D,
					TRANSFORM_FEEDBACK_BUFFER : 0x8C8E,
					TRANSFORM_FEEDBACK_BUFFER_BINDING : 0x8C8F,
					RGBA32UI : 0x8D70,
					RGB32UI : 0x8D71,
					RGBA16UI : 0x8D76,
					RGB16UI : 0x8D77,
					RGBA8UI : 0x8D7C,
					RGB8UI : 0x8D7D,
					RGBA32I : 0x8D82,
					RGB32I : 0x8D83,
					RGBA16I : 0x8D88,
					RGB16I : 0x8D89,
					RGBA8I : 0x8D8E,
					RGB8I : 0x8D8F,
					RED_INTEGER : 0x8D94,
					RGB_INTEGER : 0x8D98,
					RGBA_INTEGER : 0x8D99,
					SAMPLER_2D_ARRAY : 0x8DC1,
					SAMPLER_2D_ARRAY_SHADOW : 0x8DC4,
					SAMPLER_CUBE_SHADOW : 0x8DC5,
					UNSIGNED_INT_VEC2 : 0x8DC6,
					UNSIGNED_INT_VEC3 : 0x8DC7,
					UNSIGNED_INT_VEC4 : 0x8DC8,
					INT_SAMPLER_2D : 0x8DCA,
					INT_SAMPLER_3D : 0x8DCB,
					INT_SAMPLER_CUBE : 0x8DCC,
					INT_SAMPLER_2D_ARRAY : 0x8DCF,
					UNSIGNED_INT_SAMPLER_2D : 0x8DD2,
					UNSIGNED_INT_SAMPLER_3D : 0x8DD3,
					UNSIGNED_INT_SAMPLER_CUBE : 0x8DD4,
					UNSIGNED_INT_SAMPLER_2D_ARRAY : 0x8DD7,
					DEPTH_COMPONENT32F : 0x8CAC,
					DEPTH32F_STENCIL8 : 0x8CAD,
					FLOAT_32_UNSIGNED_INT_24_8_REV : 0x8DAD,
					FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING : 0x8210,
					FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE : 0x8211,
					FRAMEBUFFER_ATTACHMENT_RED_SIZE : 0x8212,
					FRAMEBUFFER_ATTACHMENT_GREEN_SIZE : 0x8213,
					FRAMEBUFFER_ATTACHMENT_BLUE_SIZE : 0x8214,
					FRAMEBUFFER_ATTACHMENT_ALPHA_SIZE : 0x8215,
					FRAMEBUFFER_ATTACHMENT_DEPTH_SIZE : 0x8216,
					FRAMEBUFFER_ATTACHMENT_STENCIL_SIZE : 0x8217,
					FRAMEBUFFER_DEFAULT : 0x8218,
					UNSIGNED_INT_24_8 : 0x84FA,
					DEPTH24_STENCIL8 : 0x88F0,
					UNSIGNED_NORMALIZED : 0x8C17,
					DRAW_FRAMEBUFFER_BINDING : 0x8CA6,
					READ_FRAMEBUFFER : 0x8CA8,
					DRAW_FRAMEBUFFER : 0x8CA9,
					READ_FRAMEBUFFER_BINDING : 0x8CAA,
					RENDERBUFFER_SAMPLES : 0x8CAB,
					FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER : 0x8CD4,
					MAX_COLOR_ATTACHMENTS : 0x8CDF,
					COLOR_ATTACHMENT1 : 0x8CE1,
					COLOR_ATTACHMENT2 : 0x8CE2,
					COLOR_ATTACHMENT3 : 0x8CE3,
					COLOR_ATTACHMENT4 : 0x8CE4,
					COLOR_ATTACHMENT5 : 0x8CE5,
					COLOR_ATTACHMENT6 : 0x8CE6,
					COLOR_ATTACHMENT7 : 0x8CE7,
					COLOR_ATTACHMENT8 : 0x8CE8,
					COLOR_ATTACHMENT9 : 0x8CE9,
					COLOR_ATTACHMENT10 : 0x8CEA,
					COLOR_ATTACHMENT11 : 0x8CEB,
					COLOR_ATTACHMENT12 : 0x8CEC,
					COLOR_ATTACHMENT13 : 0x8CED,
					COLOR_ATTACHMENT14 : 0x8CEE,
					COLOR_ATTACHMENT15 : 0x8CEF,
					FRAMEBUFFER_INCOMPLETE_MULTISAMPLE : 0x8D56,
					MAX_SAMPLES : 0x8D57,
					HALF_FLOAT : 0x140B,
					RG : 0x8227,
					RG_INTEGER : 0x8228,
					R8 : 0x8229,
					RG8 : 0x822B,
					R16F : 0x822D,
					R32F : 0x822E,
					RG16F : 0x822F,
					RG32F : 0x8230,
					R8I : 0x8231,
					R8UI : 0x8232,
					R16I : 0x8233,
					R16UI : 0x8234,
					R32I : 0x8235,
					R32UI : 0x8236,
					RG8I : 0x8237,
					RG8UI : 0x8238,
					RG16I : 0x8239,
					RG16UI : 0x823A,
					RG32I : 0x823B,
					RG32UI : 0x823C,
					VERTEX_ARRAY_BINDING : 0x85B5,
					R8_SNORM : 0x8F94,
					RG8_SNORM : 0x8F95,
					RGB8_SNORM : 0x8F96,
					RGBA8_SNORM : 0x8F97,
					SIGNED_NORMALIZED : 0x8F9C,
					COPY_READ_BUFFER : 0x8F36,
					COPY_WRITE_BUFFER : 0x8F37,
					COPY_READ_BUFFER_BINDING : 0x8F36,
					COPY_WRITE_BUFFER_BINDING : 0x8F37,
					UNIFORM_BUFFER : 0x8A11,
					UNIFORM_BUFFER_BINDING : 0x8A28,
					UNIFORM_BUFFER_START : 0x8A29,
					UNIFORM_BUFFER_SIZE : 0x8A2A,
					MAX_VERTEX_UNIFORM_BLOCKS : 0x8A2B,
					MAX_FRAGMENT_UNIFORM_BLOCKS : 0x8A2D,
					MAX_COMBINED_UNIFORM_BLOCKS : 0x8A2E,
					MAX_UNIFORM_BUFFER_BINDINGS : 0x8A2F,
					MAX_UNIFORM_BLOCK_SIZE : 0x8A30,
					MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS : 0x8A31,
					MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS : 0x8A33,
					UNIFORM_BUFFER_OFFSET_ALIGNMENT : 0x8A34,
					ACTIVE_UNIFORM_BLOCKS : 0x8A36,
					UNIFORM_TYPE : 0x8A37,
					UNIFORM_SIZE : 0x8A38,
					UNIFORM_BLOCK_INDEX : 0x8A3A,
					UNIFORM_OFFSET : 0x8A3B,
					UNIFORM_ARRAY_STRIDE : 0x8A3C,
					UNIFORM_MATRIX_STRIDE : 0x8A3D,
					UNIFORM_IS_ROW_MAJOR : 0x8A3E,
					UNIFORM_BLOCK_BINDING : 0x8A3F,
					UNIFORM_BLOCK_DATA_SIZE : 0x8A40,
					UNIFORM_BLOCK_ACTIVE_UNIFORMS : 0x8A42,
					UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES : 0x8A43,
					UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER : 0x8A44,
					UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER : 0x8A46,
					INVALID_INDEX : 0xFFFFFFFF,
					MAX_VERTEX_OUTPUT_COMPONENTS : 0x9122,
					MAX_FRAGMENT_INPUT_COMPONENTS : 0x9125,
					MAX_SERVER_WAIT_TIMEOUT : 0x9111,
					OBJECT_TYPE : 0x9112,
					SYNC_CONDITION : 0x9113,
					SYNC_STATUS : 0x9114,
					SYNC_FLAGS : 0x9115,
					SYNC_FENCE : 0x9116,
					SYNC_GPU_COMMANDS_COMPLETE : 0x9117,
					UNSIGNALED : 0x9118,
					SIGNALED : 0x9119,
					ALREADY_SIGNALED : 0x911A,
					TIMEOUT_EXPIRED : 0x911B,
					CONDITION_SATISFIED : 0x911C,
					WAIT_FAILED : 0x911D,
					SYNC_FLUSH_COMMANDS_BIT : 0x00000001,
					VERTEX_ATTRIB_ARRAY_DIVISOR : 0x88FE,
					ANY_SAMPLES_PASSED : 0x8C2F,
					ANY_SAMPLES_PASSED_CONSERVATIVE : 0x8D6A,
					SAMPLER_BINDING : 0x8919,
					RGB10_A2UI : 0x906F,
					INT_2_10_10_10_REV : 0x8D9F,
					TRANSFORM_FEEDBACK : 0x8E22,
					TRANSFORM_FEEDBACK_PAUSED : 0x8E23,
					TRANSFORM_FEEDBACK_ACTIVE : 0x8E24,
					TRANSFORM_FEEDBACK_BINDING : 0x8E25,
					TEXTURE_IMMUTABLE_FORMAT : 0x912F,
					MAX_ELEMENT_INDEX : 0x8D6B,
					TEXTURE_IMMUTABLE_LEVELS : 0x82DF,
					TIMEOUT_IGNORED : -1,
					MAX_CLIENT_WAIT_TIMEOUT_WEBGL : 0x9247,

					// https://www.khronos.org/registry/webgl/extensions/EXT_disjoint_timer_query_webgl2/
					QUERY_COUNTER_BITS_EXT : 0x8864,
					TIME_ELAPSED_EXT : 0x88BF,
					TIMESTAMP_EXT : 0x8E28,
					GPU_DISJOINT_EXT : 0x8FBB,

					// https://www.khronos.org/registry/webgl/extensions/WEBGL_compressed_texture_s3tc/
					COMPRESSED_RGB_S3TC_DXT1_EXT : 0x83F0,
					COMPRESSED_RGBA_S3TC_DXT1_EXT : 0x83F1,
					COMPRESSED_RGBA_S3TC_DXT3_EXT : 0x83F2,
					COMPRESSED_RGBA_S3TC_DXT5_EXT : 0x83F3,

					// https://www.khronos.org/registry/webgl/extensions/WEBGL_compressed_texture_s3tc_srgb/
					COMPRESSED_SRGB_S3TC_DXT1_EXT : 0x8C4C,
					COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT : 0x8C4D,
					COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT : 0x8C4E,
					COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT : 0x8C4F,

					// https://www.khronos.org/registry/webgl/extensions/WEBGL_compressed_texture_etc/
					COMPRESSED_R11_EAC : 0x9270,
					COMPRESSED_SIGNED_R11_EAC : 0x9271,
					COMPRESSED_RG11_EAC : 0x9272,
					COMPRESSED_SIGNED_RG11_EAC : 0x9273,
					COMPRESSED_RGB8_ETC2 : 0x9274,
					COMPRESSED_SRGB8_ETC2 : 0x9275,
					COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2 : 0x9276,
					COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2 : 0x9277,
					COMPRESSED_RGBA8_ETC2_EAC : 0x9278,
					COMPRESSED_SRGB8_ALPHA8_ETC2_EAC : 0x9279,

					// https://www.khronos.org/registry/webgl/extensions/WEBGL_compressed_texture_pvrtc/
					COMPRESSED_RGB_PVRTC_4BPPV1_IMG : 0x8C00,
					COMPRESSED_RGB_PVRTC_2BPPV1_IMG : 0x8C01,
					COMPRESSED_RGBA_PVRTC_4BPPV1_IMG : 0x8C02,
					COMPRESSED_RGBA_PVRTC_2BPPV1_IMG : 0x8C03,

					// https://www.khronos.org/registry/webgl/extensions/WEBGL_compressed_texture_astc/
					COMPRESSED_RGBA_ASTC_4x4_KHR : 0x93B0,
					COMPRESSED_RGBA_ASTC_5x4_KHR : 0x93B1,
					COMPRESSED_RGBA_ASTC_5x5_KHR : 0x93B2,
					COMPRESSED_RGBA_ASTC_6x5_KHR : 0x93B3,
					COMPRESSED_RGBA_ASTC_6x6_KHR : 0x93B4,
					COMPRESSED_RGBA_ASTC_8x5_KHR : 0x93B5,
					COMPRESSED_RGBA_ASTC_8x6_KHR : 0x93B6,
					COMPRESSED_RGBA_ASTC_8x8_KHR : 0x93B7,
					COMPRESSED_RGBA_ASTC_10x5_KHR : 0x93B8,
					COMPRESSED_RGBA_ASTC_10x6_KHR : 0x93B9,
					COMPRESSED_RGBA_ASTC_10x8_KHR : 0x93BA,
					COMPRESSED_RGBA_ASTC_10x10_KHR : 0x93BB,
					COMPRESSED_RGBA_ASTC_12x10_KHR : 0x93BC,
					COMPRESSED_RGBA_ASTC_12x12_KHR : 0x93BD,
					COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR : 0x93D0,
					COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR : 0x93D1,
					COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR : 0x93D2,
					COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR : 0x93D3,
					COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR : 0x93D4,
					COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR : 0x93D5,
					COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR : 0x93D6,
					COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR : 0x93D7,
					COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR : 0x93D8,
					COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR : 0x93D9,
					COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR : 0x93DA,
					COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR : 0x93DB,
					COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR : 0x93DC,
					COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR : 0x93DD,

					TYPE_SIZE : {
						[gl.BYTE] : 1,
						[gl.UNSIGNED_BYTE] : 1,
						[gl.SHORT] : 2,
						[gl.UNSIGNED_SHORT] : 2,
						[gl.INT] : 4,
						[gl.UNSIGNED_INT] : 4,
						[gl.FLOAT] : 4
					},

					WEBGL_INFO: {
						MAX_TEXTURE_UNITS: gl.getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS),
						MAX_UNIFORM_BUFFERS : gl.getParameter(gl.MAX_UNIFORM_BUFFER_BINDINGS)
					},

					DUMMY_OBJECT : {}
				};

				module.exports = CONSTANTS;


				/***/
			}),
				/* 1 */
				/***/ (function(module, exports, __webpack_require__) {

				"use strict";
				// Copyright (c) 2017 Tarek Sherif
				//
				// Permission is hereby granted, free of charge, to any person obtaining a copy of
				// this software and associated documentation files (the "Software"), to deal in
				// the Software without restriction, including without limitation the rights to
				// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
				// the Software, and to permit persons to whom the Software is furnished to do so,
				// subject to the following conditions:
				//
				// The above copyright notice and this permission notice shall be included in all
				// copies or substantial portions of the Software.
				//
				// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
				// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
				// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
				// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
				// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
				// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
				///////////////////////////////////////////////////////////////////////////////////



				const CONSTANTS = __webpack_require__(0);

				const TEXTURE_FORMAT_DEFAULTS = {
					[CONSTANTS.UNSIGNED_BYTE] : {
						[CONSTANTS.RED] : CONSTANTS.R8,
						[CONSTANTS.RG] : CONSTANTS.RG8,
						[CONSTANTS.RGB] : CONSTANTS.RGB8,
						[CONSTANTS.RGBA] : CONSTANTS.RGBA8
					},

					[CONSTANTS.UNSIGNED_SHORT]: {
						[CONSTANTS.DEPTH_COMPONENT] : CONSTANTS.DEPTH_COMPONENT16
					},

					[CONSTANTS.FLOAT] : {
						[CONSTANTS.RED] : CONSTANTS.R16F,
						[CONSTANTS.RG] : CONSTANTS.RG16F,
						[CONSTANTS.RGB] : CONSTANTS.RGB16F,
						[CONSTANTS.RGBA] : CONSTANTS.RGBA16F,
						[CONSTANTS.DEPTH_COMPONENT] : CONSTANTS.DEPTH_COMPONENT32F
					},

					COMPRESSED_TYPES: {}
				};

				module.exports = TEXTURE_FORMAT_DEFAULTS;


				/***/
			}),
				/* 2 */
				/***/ (function(module, exports, __webpack_require__) {

				"use strict";
				///////////////////////////////////////////////////////////////////////////////////
				// The MIT License (MIT)
				//
				// Copyright (c) 2017 Tarek Sherif
				//
				// Permission is hereby granted, free of charge, to any person obtaining a copy of
				// this software and associated documentation files (the "Software"), to deal in
				// the Software without restriction, including without limitation the rights to
				// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
				// the Software, and to permit persons to whom the Software is furnished to do so,
				// subject to the following conditions:
				//
				// The above copyright notice and this permission notice shall be included in all
				// copies or substantial portions of the Software.
				//
				// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
				// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
				// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
				// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
				// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
				// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
				///////////////////////////////////////////////////////////////////////////////////



				/**
					WebGL shader.

					@class
					@prop {WebGLRenderingContext} gl The WebGL context.
					@prop {WebGLShader} shader The shader.
				*/
				class Shader {

					constructor(gl, type, source) {
						this.gl = gl;
						this.shader = gl.createShader(type);
						gl.shaderSource(this.shader, source);
						gl.compileShader(this.shader);

						if (!gl.getShaderParameter(this.shader, gl.COMPILE_STATUS)) {
							let i, lines;

							console.error(gl.getShaderInfoLog(this.shader));
							lines = source.split("\n");
							for (i = 0; i < lines.length; ++i) {
								console.error(`${i + 1
							}: ${ lines[i] }`);
						}
					}
				}

				/**
					Delete this shader.

					@method
					@return {Shader} The Shader object.
				*/
				delete() {
					if (this.shader) {
						this.gl.deleteShader(this.shader);
						this.shader = null;
					}

					return this;
				}

			}

			module.exports = Shader;


			/***/ }),
									/* 3 */
				/***/ (function(module, exports, __webpack_require__) {

				"use strict";
				///////////////////////////////////////////////////////////////////////////////////
				// The MIT License (MIT)
				//
				// Copyright (c) 2017 Tarek Sherif
				//
				// Permission is hereby granted, free of charge, to any person obtaining a copy of
				// this software and associated documentation files (the "Software"), to deal in
				// the Software without restriction, including without limitation the rights to
				// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
				// the Software, and to permit persons to whom the Software is furnished to do so,
				// subject to the following conditions:
				//
				// The above copyright notice and this permission notice shall be included in all
				// copies or substantial portions of the Software.
				//
				// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
				// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
				// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
				// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
				// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
				// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
				///////////////////////////////////////////////////////////////////////////////////



				/**
					Generic query object.

					@class
					@prop {WebGLRenderingContext} gl The WebGL context.
					@prop {WebGLQuery} query Query object.
					@prop {GLEnum} target The type of information being queried.
					@prop {boolean} active Whether or not a query is currently in progress.
					@prop {Any} result The result of the query (only available after a call to ready() returns true).
				*/
				class Query {

					constructor(gl, target) {
						this.gl = gl;
						this.query = gl.createQuery();
						this.target = target;
						this.active = false;
						this.result = null;
					}

					/**
						Begin a query.

						@method
						@return {Query} The Query object.
					*/
					begin() {
						if (!this.active) {
							this.gl.beginQuery(this.target, this.query);
							this.result = null;
						}

						return this;
					}

					/**
						End a query.

						@method
						@return {Query} The Query object.
					*/
					end() {
						if (!this.active) {
							this.gl.endQuery(this.target);
							this.active = true;
						}

						return this;
					}

					/**
						Check if query result is available.

						@method
						@return {boolean} If results are available.
					*/
					ready() {
						if (this.active && this.gl.getQueryParameter(this.query, this.gl.QUERY_RESULT_AVAILABLE)) {
							this.active = false;
							// Note(Tarek): Casting because FF incorrectly returns booleans.
							// https://bugzilla.mozilla.org/show_bug.cgi?id=1422714 
							this.result = Number(this.gl.getQueryParameter(this.query, this.gl.QUERY_RESULT));
							return true;
						}

						return false;
					}

					/**
						Delete this query.

						@method
						@return {Query} The Query object.
					*/
					delete() {
						if (this.query) {
							this.gl.deleteQuery(this.query);
							this.query = null;
						}

						return this;
					}

				}

				module.exports = Query;


				/***/
			}),
				/* 4 */
				/***/ (function(module, exports, __webpack_require__) {

				"use strict";
				///////////////////////////////////////////////////////////////////////////////////
				// The MIT License (MIT)
				//
				// Copyright (c) 2017 Tarek Sherif
				//
				// Permission is hereby granted, free of charge, to any person obtaining a copy of
				// this software and associated documentation files (the "Software"), to deal in
				// the Software without restriction, including without limitation the rights to
				// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
				// the Software, and to permit persons to whom the Software is furnished to do so,
				// subject to the following conditions:
				//
				// The above copyright notice and this permission notice shall be included in all
				// copies or substantial portions of the Software.
				//
				// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
				// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
				// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
				// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
				// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
				// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
				///////////////////////////////////////////////////////////////////////////////////



				const App = __webpack_require__(5);

				/**
					Global PicoGL module. For convenience, all WebGL enums are stored
					as properties of PicoGL (e.g. PicoGL.FLOAT, PicoGL.ONE_MINUS_SRC_ALPHA).

					@namespace PicoGL
				*/
				const PicoGL = __webpack_require__(0);
				PicoGL.version = "0.8.8";

				/**
					Create a PicoGL app. The app is the primary entry point to PicoGL. It stores
					the canvas, the WebGL context and all WebGL state.

					@function PicoGL.createApp
					@param {DOMElement} canvas The canvas on which to create the WebGL context.
					@param {Object} [contextAttributes] Context attributes to pass when calling getContext().
					@return {App} New App object.
				*/
				PicoGL.createApp = function(canvas, contextAttributes) {
					return new App(canvas, contextAttributes);
				};

				module.exports = PicoGL;


				/***/
			}),
				/* 5 */
				/***/ (function(module, exports, __webpack_require__) {

				"use strict";
				///////////////////////////////////////////////////////////////////////////////////
				// The MIT License (MIT)
				//
				// Copyright (c) 2017 Tarek Sherif
				//
				// Permission is hereby granted, free of charge, to any person obtaining a copy of
				// this software and associated documentation files (the "Software"), to deal in
				// the Software without restriction, including without limitation the rights to
				// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
				// the Software, and to permit persons to whom the Software is furnished to do so,
				// subject to the following conditions:
				//
				// The above copyright notice and this permission notice shall be included in all
				// copies or substantial portions of the Software.
				//
				// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
				// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
				// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
				// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
				// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
				// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
				///////////////////////////////////////////////////////////////////////////////////



				const CONSTANTS = __webpack_require__(0);
				const TEXTURE_FORMAT_DEFAULTS = __webpack_require__(1);
				const Cubemap = __webpack_require__(6);
				const DrawCall = __webpack_require__(7);
				const Framebuffer = __webpack_require__(8);
				const Program = __webpack_require__(9);
				const Shader = __webpack_require__(2);
				const Texture = __webpack_require__(11);
				const Timer = __webpack_require__(12);
				const TransformFeedback = __webpack_require__(13);
				const UniformBuffer = __webpack_require__(14);
				const VertexArray = __webpack_require__(15);
				const VertexBuffer = __webpack_require__(16);
				const Query = __webpack_require__(3);

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
				class App {

					constructor(canvas, contextAttributes) {
						this.canvas = canvas;
						this.gl = canvas.getContext("webgl2", contextAttributes);
						this.width = this.gl.drawingBufferWidth;
						this.height = this.gl.drawingBufferHeight;
						this.viewportX = 0;
						this.viewportY = 0;
						this.viewportWidth = 0;
						this.viewportHeight = 0;
						this.currentDrawCalls = null;
						this.emptyFragmentShader = null;

						this.state = {
							program: null,
							vertexArray : null,
							transformFeedback : null,
							activeTexture : -1,
							textures : new Array(CONSTANTS.WEBGL_INFO.MAX_TEXTURE_UNITS),
							uniformBuffers : new Array(CONSTANTS.WEBGL_INFO.MAX_UNIFORM_BUFFERS),
							freeUniformBufferBases : [] ,
							drawFramebuffer : null,
							readFramebuffer : null
						};

						this.clearBits = this.gl.COLOR_BUFFER_BIT | this.gl.DEPTH_BUFFER_BIT | this.gl.STENCIL_BUFFER_BIT;

						this.cpuTime = 0;
						this.gpuTime = 0;

						// Extensions
						this.floatRenderTargetsEnabled = false;
						this.linearFloatTexturesEnabled = false;
						this.s3tcTexturesEnabled = false;
						this.s3tcSRGBTexturesEnabled = false;
						this.etcTexturesEnabled = false;
						this.astcTexturesEnabled = false;
						this.pvrtcTexturesEnabled = false;

						this.viewport(0, 0, this.width, this.height);
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
					colorMask(r, g, b, a) {
						this.gl.colorMask(r, g, b, a);

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
					clearColor(r, g, b, a) {
						this.gl.clearColor(r, g, b, a);

						return this;
					}

					/**
						Set the clear mask bits to use when calling clear().
						E.g. app.clearMask(PicoGL.COLOR_BUFFER_BIT).

						@method
						@param {GLEnum} mask Bit mask of buffers to clear.
						@return {App} The App object.
					*/
					clearMask(mask) {
						this.clearBits = mask;

						return this;
					}

					/**
						Clear the canvas

						@method
						@return {App} The App object.
					*/
					clear() {
						this.gl.clear(this.clearBits);

						return this;
					}

					/**
						Bind a draw framebuffer to the WebGL context.

						@method
						@param {Framebuffer} framebuffer The Framebuffer object to bind.
						@see Framebuffer
						@return {App} The App object.
					*/
					drawFramebuffer(framebuffer) {
						framebuffer.bindForDraw();

						return this;
					}

					/**
						Bind a read framebuffer to the WebGL context.

						@method
						@param {Framebuffer} framebuffer The Framebuffer object to bind.
						@see Framebuffer
						@return {App} The App object.
					*/
					readFramebuffer(framebuffer) {
						framebuffer.bindForRead();

						return this;
					}

					/**
						Switch back to the default framebuffer for drawing (i.e. draw to the screen).
						Note that this method resets the viewport to match the default framebuffer.

						@method
						@return {App} The App object.
					*/
					defaultDrawFramebuffer() {
						if (this.state.drawFramebuffer != = null) {
							this.gl.bindFramebuffer(this.gl.DRAW_FRAMEBUFFER, null);
							this.state.drawFramebuffer = null;
						}

						return this;
					}

					/**
						Switch back to the default framebuffer for reading (i.e. read from the screen).

						@method
						@return {App} The App object.
					*/
					defaultReadFramebuffer() {
						if (this.state.readFramebuffer != = null) {
							this.gl.bindFramebuffer(this.gl.READ_FRAMEBUFFER, null);
							this.state.readFramebuffer = null;
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
					depthRange(near, far) {
						this.gl.depthRange(near, far);

						return this;
					}

					/**
						Enable depth testing.

						@method
						@return {App} The App object.
					*/
					depthTest() {
						this.gl.enable(this.gl.DEPTH_TEST);

						return this;
					}

					/**
						Disable depth testing.

						@method
						@return {App} The App object.
					*/
					noDepthTest() {
						this.gl.disable(this.gl.DEPTH_TEST);

						return this;
					}

					/**
						Enable or disable writing to the depth buffer.

						@method
						@param {Boolean} mask The depth mask.
						@return {App} The App object.
					*/
					depthMask(mask) {
						this.gl.depthMask(mask);

						return this;
					}

					/**
						Set the depth test function. E.g. app.depthFunc(PicoGL.LEQUAL).

						@method
						@param {GLEnum} func The depth testing function to use.
						@return {App} The App object.
					*/
					depthFunc(func) {
						this.gl.depthFunc(func);

						return this;
					}

					/**
						Enable blending.

						@method
						@return {App} The App object.
					*/
					blend() {
						this.gl.enable(this.gl.BLEND);

						return this;
					}

					/**
						Disable blending

						@method
						@return {App} The App object.
					*/
					noBlend() {
						this.gl.disable(this.gl.BLEND);

						return this;
					}

					/**
						Set the blend function. E.g. app.blendFunc(PicoGL.ONE, PicoGL.ONE_MINUS_SRC_ALPHA).

						@method
						@param {GLEnum} src The source blending weight.
						@param {GLEnum} dest The destination blending weight.
						@return {App} The App object.
					*/
					blendFunc(src, dest) {
						this.gl.blendFunc(src, dest);

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
					blendFuncSeparate(csrc, cdest, asrc, adest) {
						this.gl.blendFuncSeparate(csrc, cdest, asrc, adest);

						return this;
					}

					/**
						Enable stencil testing.
						NOTE: Only works if { stencil: true } passed as a
						context attribute when creating the App!

						@method
						@return {App} The App object.
					*/
					stencilTest() {
						this.gl.enable(this.gl.STENCIL_TEST);

						return this;
					}

					/**
						Disable stencil testing.

						@method
						@return {App} The App object.
					*/
					noStencilTest() {
						this.gl.disable(this.gl.STENCIL_TEST);

						return this;
					}


					/**
						Enable scissor testing.

						@method
						@return {App} The App object.
					*/
					scissorTest() {
						this.gl.enable(this.gl.SCISSOR_TEST);

						return this;
					}

					/**
						Disable scissor testing.

						@method
						@return {App} The App object.
					*/
					noScissorTest() {
						this.gl.disable(this.gl.SCISSOR_TEST);

						return this;
					}

					/**
						Define the scissor box.

						@method
						@return {App} The App object.
					*/
					scissor(x, y, width, height) {
						this.gl.scissor(x, y, width, height);

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
					stencilMask(mask) {
						this.gl.stencilMask(mask);

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
					stencilMaskSeparate(face, mask) {
						this.gl.stencilMaskSeparate(face, mask);

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
						@param {GLEnum} mask The bitmask to use against tested values before applying
							the stencil function.
						@return {App} The App object.
					*/
					stencilFunc(func, ref, mask) {
						this.gl.stencilFunc(func, ref, mask);

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
						@param {GLEnum} mask The bitmask to use against tested values before applying
							the stencil function.
						@return {App} The App object.
					*/
					stencilFuncSeparate(face, func, ref, mask) {
						this.gl.stencilFuncSeparate(face, func, ref, mask);

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
					stencilOp(stencilFail, depthFail, pass) {
						this.gl.stencilOp(stencilFail, depthFail, pass);

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
					stencilOpSeparate(face, stencilFail, depthFail, pass) {
						this.gl.stencilOpSeparate(face, stencilFail, depthFail, pass);

						return this;
					}

					/**
						Enable rasterization step.

						@method
						@return {App} The App object.
					*/
					rasterize() {
						this.gl.disable(this.gl.RASTERIZER_DISCARD);

						return this;
					}

					/**
						Disable rasterization step.

						@method
						@return {App} The App object.
					*/
					noRasterize() {
						this.gl.enable(this.gl.RASTERIZER_DISCARD);

						return this;
					}

					/**
						Enable backface culling.

						@method
						@return {App} The App object.
					*/
					cullBackfaces() {
						this.gl.enable(this.gl.CULL_FACE);

						return this;
					}

					/**
						Disable backface culling.

						@method
						@return {App} The App object.
					*/
					drawBackfaces() {
						this.gl.disable(this.gl.CULL_FACE);

						return this;
					}

					/**
						Enable the EXT_color_buffer_float extension. Allows for creating float textures as
						render targets on FrameBuffer objects.

						@method
						@see Framebuffer
						@return {App} The App object.
					*/
					floatRenderTargets() {
						this.floatRenderTargetsEnabled = !!this.gl.getExtension("EXT_color_buffer_float");

						return this;
					}

					/**
						Enable the OES_texture_float_linear extension. Allows for linear blending on float textures.

						@method
						@see Framebuffer
						@return {App} The App object.
					*/
					linearFloatTextures() {
						this.linearFloatTexturesEnabled = !!this.gl.getExtension("OES_texture_float_linear");

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
					s3tcTextures() {
						let ext = this.gl.getExtension("WEBGL_compressed_texture_s3tc");
						this.s3tcTexturesEnabled = !!ext;

						if (this.s3tcTexturesEnabled) {
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_RGB_S3TC_DXT1_EXT] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_RGBA_S3TC_DXT1_EXT] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_RGBA_S3TC_DXT3_EXT] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_RGBA_S3TC_DXT5_EXT] = true;
						}

						ext = this.gl.getExtension("WEBGL_compressed_texture_s3tc_srgb");
						this.s3tcSRGBTexturesEnabled = !!ext;

						if (this.s3tcSRGBTexturesEnabled) {
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_SRGB_S3TC_DXT1_EXT] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT] = true;
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
					etcTextures() {
						let ext = this.gl.getExtension("WEBGL_compressed_texture_etc");
						this.etcTexturesEnabled = !!ext;

						if (this.etcTexturesEnabled) {
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_R11_EAC] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_SIGNED_R11_EAC] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_RG11_EAC] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_SIGNED_RG11_EAC] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_RGB8_ETC2] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_SRGB8_ETC2] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_RGBA8_ETC2_EAC] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_SRGB8_ALPHA8_ETC2_EAC] = true;
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
					astcTextures() {
						let ext = this.gl.getExtension("WEBGL_compressed_texture_astc");
						this.astcTexturesEnabled = !!ext;

						if (this.astcTexturesEnabled) {
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_RGBA_ASTC_4x4_KHR] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_RGBA_ASTC_5x4_KHR] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_RGBA_ASTC_5x5_KHR] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_RGBA_ASTC_6x5_KHR] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_RGBA_ASTC_6x6_KHR] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_RGBA_ASTC_8x5_KHR] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_RGBA_ASTC_8x6_KHR] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_RGBA_ASTC_8x8_KHR] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_RGBA_ASTC_10x5_KHR] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_RGBA_ASTC_10x6_KHR] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_RGBA_ASTC_10x8_KHR] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_RGBA_ASTC_10x10_KHR] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_RGBA_ASTC_12x10_KHR] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_RGBA_ASTC_12x12_KHR] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR] = true;
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

						@method
						@return {App} The App object.
					*/
					pvrtcTextures() {
						let ext = this.gl.getExtension("WEBGL_compressed_texture_pvrtc");
						this.pvrtcTexturesEnabled = !!ext;

						if (this.pvrtcTexturesEnabled) {
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_RGB_PVRTC_4BPPV1_IMG] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_RGB_PVRTC_2BPPV1_IMG] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_RGBA_PVRTC_4BPPV1_IMG] = true;
							TEXTURE_FORMAT_DEFAULTS.COMPRESSED_TYPES[CONSTANTS.COMPRESSED_RGBA_PVRTC_2BPPV1_IMG] = true;
						}

						return this;
					}

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
					readPixel(x, y, outColor, options = CONSTANTS.DUMMY_OBJECT) {
						let{
							format = CONSTANTS.RGBA,
							type = CONSTANTS.UNSIGNED_BYTE
						} = options;

						this.gl.readPixels(x, y, 1, 1, format, type, outColor);

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
					viewport(x, y, width, height) {

						if (this.viewportWidth != = width || this.viewportHeight != = height ||
							this.viewportX != = x || this.viewportY != = y) {
							this.viewportX = x;
							this.viewportY = y;
							this.viewportWidth = width;
							this.viewportHeight = height;
							this.gl.viewport(x, y, this.viewportWidth, this.viewportHeight);
						}

						return this;
					}

					/**
						Set the viewport to the full canvas.

						@method
						@return {App} The App object.
					*/
					defaultViewport() {
						this.viewport(0, 0, this.width, this.height);

						return this;
					}

					/**
						Resize the drawing surface.

						@method
						@param {number} width The new canvas width.
						@param {number} height The new canvas height.
						@return {App} The App object.
					*/
					resize(width, height) {
						this.canvas.width = width;
						this.canvas.height = height;

						this.width = this.gl.drawingBufferWidth;
						this.height = this.gl.drawingBufferHeight;
						this.viewport(0, 0, this.width, this.height);

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
					createProgram(vsSource, fsSource, xformFeedbackVars) {
						return new Program(this.gl, this.state, vsSource, fsSource, xformFeedbackVars);
					}

					/**
						Create a shader. Creating a shader separately from a program allows for
						shader reuse.

						@method
						@param {GLEnum} type Shader type.
						@param {string} source Shader source.
						@return {Shader} New Shader object.
					*/
					createShader(type, source) {
						return new Shader(this.gl, type, source);
					}

					/**
						Create a vertex array.

						@method
						@return {VertexArray} New VertexArray object.
					*/
					createVertexArray() {
						return new VertexArray(this.gl, this.state);
					}

					/**
						Create a transform feedback object.

						@method
						@return {TransformFeedback} New TransformFeedback object.
					*/
					createTransformFeedback() {
						return new TransformFeedback(this.gl, this.state);
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
					createVertexBuffer(type, itemSize, data, usage) {
						return new VertexBuffer(this.gl, this.state, type, itemSize, data, usage);
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
					createMatrixBuffer(type, data, usage) {
						return new VertexBuffer(this.gl, this.state, type, 0, data, usage);
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
					createIndexBuffer(type, itemSize, data, usage) {
						return new VertexBuffer(this.gl, this.state, type, itemSize, data, usage, true);
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
					createUniformBuffer(layout, usage) {
						return new UniformBuffer(this.gl, this.state, layout, usage);
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
					createTexture2D(image, width, height, options) {
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

						return new Texture(this.gl, this.state, this.gl.TEXTURE_2D, image, width, height, undefined, false, options);
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
					createTextureArray(image, width, height, depth, options) {
						if (typeof image == = "number") {
							// Create empty texture just give width/height/depth.
							options = depth;
							depth = height;
							height = width;
							width = image;
							image = null;
						}
						return new Texture(this.gl, this.state, this.gl.TEXTURE_2D_ARRAY, image, width, height, depth, true, options);
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
					createTexture3D(image, width, height, depth, options) {
						if (typeof image == = "number") {
							// Create empty texture just give width/height/depth.
							options = depth;
							depth = height;
							height = width;
							width = image;
							image = null;
						}
						return new Texture(this.gl, this.state, this.gl.TEXTURE_3D, image, width, height, depth, true, options);
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
					createCubemap(options) {
						return new Cubemap(this.gl, this.state, options);
					}

					/**
						Create a framebuffer.

						@method
						@return {Framebuffer} New Framebuffer object.
					*/
					createFramebuffer() {
						return new Framebuffer(this.gl, this.state);
					}

					/**
						Create a query.

						@method
						@param {GLEnum} target Information to query.
						@return {Query} New Query object.
					*/
					createQuery(target) {
						return new Query(this.gl, target);
					}

					/**
						Create a timer.

						@method
						@return {Timer} New Timer object.
					*/
					createTimer() {
						return new Timer(this.gl);
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
					createDrawCall(program, vertexArray, primitive) {
						return new DrawCall(this.gl, this.state, program, vertexArray, primitive);
					}

				}

				module.exports = App;


				/***/
			}),
				/* 6 */
				/***/ (function(module, exports, __webpack_require__) {

				"use strict";
				///////////////////////////////////////////////////////////////////////////////////
				// The MIT License (MIT)
				//
				// Copyright (c) 2017 Tarek Sherif
				//
				// Permission is hereby granted, free of charge, to any person obtaining a copy of
				// this software and associated documentation files (the "Software"), to deal in
				// the Software without restriction, including without limitation the rights to
				// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
				// the Software, and to permit persons to whom the Software is furnished to do so,
				// subject to the following conditions:
				//
				// The above copyright notice and this permission notice shall be included in all
				// copies or substantial portions of the Software.
				//
				// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
				// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
				// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
				// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
				// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
				// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
				///////////////////////////////////////////////////////////////////////////////////



				const CONSTANTS = __webpack_require__(0);
				const TEXTURE_FORMAT_DEFAULTS = __webpack_require__(1);

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
				class Cubemap {

					constructor(gl, appState, options) {
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

					}

					/**
						Delete this cubemap.

						@method
						@return {Cubemap} The Cubemap object.
					*/
					delete() {
						if (this.texture) {
							this.gl.deleteTexture(this.texture);
							this.texture = null;
							this.appState.textures[this.currentUnit] = null;
							this.currentUnit = -1;
						}

						return this;
					}

					/**
						Bind this cubemap to a texture unit.

						@method
						@ignore
						@return {Cubemap} The Cubemap object.
					*/
					bind(unit) {
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
					}

				}

				module.exports = Cubemap;


				/***/
			}),
				/* 7 */
				/***/ (function(module, exports, __webpack_require__) {

				"use strict";
				///////////////////////////////////////////////////////////////////////////////////
				// The MIT License (MIT)
				//
				// Copyright (c) 2017 Tarek Sherif
				//
				// Permission is hereby granted, free of charge, to any person obtaining a copy of
				// this software and associated documentation files (the "Software"), to deal in
				// the Software without restriction, including without limitation the rights to
				// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
				// the Software, and to permit persons to whom the Software is furnished to do so,
				// subject to the following conditions:
				//
				// The above copyright notice and this permission notice shall be included in all
				// copies or substantial portions of the Software.
				//
				// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
				// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
				// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
				// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
				// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
				// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
				///////////////////////////////////////////////////////////////////////////////////



				const CONSTANTS = __webpack_require__(0);

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
				class DrawCall {

					constructor(gl, appState, program, vertexArray, primitive = CONSTANTS.TRIANGLES) {
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
					}

					/**
						Set the current TransformFeedback object for draw

						@method
						@param {TransformFeedback} transformFeedback Transform Feedback to set.
						@return {DrawCall} The DrawCall object.
					*/
					transformFeedback(transformFeedback) {
						this.currentTransformFeedback = transformFeedback;

						return this;
					}

					/**
						Set the value for a uniform. Array uniforms are supported by
						using appending "[0]" to the array name and passing a flat array
						with all required values.

						@method
						@param {string} name Uniform name.
						@param {any} value Uniform value.
						@return {DrawCall} The DrawCall object.
					*/
					uniform(name, value) {
						let index = this.uniformIndices[name];
						if (index == = undefined) {
							index = this.uniformCount++;
							this.uniformIndices[name] = index;
							this.uniformNames[index] = name;
						}
						this.uniformValues[index] = value;

						return this;
					}

					/**
						Set texture to bind to a sampler uniform.

						@method
						@param {string} name Sampler uniform name.
						@param {Texture} texture Texture to bind.
						@return {DrawCall} The DrawCall object.
					*/
					texture(name, texture) {
						let unit = this.currentProgram.samplers[name];
						this.textures[unit] = texture;

						return this;
					}

					/**
						Set uniform buffer to bind to a uniform block.

						@method
						@param {string} name Uniform block name.
						@param {UniformBuffer} buffer Uniform buffer to bind.
						@return {DrawCall} The DrawCall object.
					*/
					uniformBlock(name, buffer) {
						let base = this.currentProgram.uniformBlocks[name];
						this.uniformBuffers[base] = buffer;

						return this;
					}

					/**
						Set numElements property to allow number of elements to be drawn

						@method
						@param {GLsizei} [count=0] Number of element to draw, 0 set to all.
						@return {DrawCall} The DrawCall object.
					*/
					elementCount(count = 0) {
						if (count > 0) {
							this.numElements = Math.min(count, this.currentVertexArray.numElements);
						}
						else {
							this.numElements = this.currentVertexArray.numElements;
						}

						return this;
					}

					/**
						Set numInstances property to allow number of instances be drawn

						@method
						@param {GLsizei} [count=0] Number of instance to draw, 0 set to all.
						@return {DrawCall} The DrawCall object.
					*/
					instanceCount(count = 0) {
						if (count > 0) {
							this.numInstances = Math.min(count, this.currentVertexArray.numInstances);
						}
						else {
							this.numInstances = this.currentVertexArray.numInstances;
						}

						return this;
					}

					/**
						Draw based on current state.

						@method
						@return {DrawCall} The DrawCall object.
					*/
					draw() {
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
					}

				}

				module.exports = DrawCall;

				/***/
			}),
				/* 8 */
				/***/ (function(module, exports, __webpack_require__) {

				"use strict";
				///////////////////////////////////////////////////////////////////////////////////
				// The MIT License (MIT)
				//
				// Copyright (c) 2017 Tarek Sherif
				//
				// Permission is hereby granted, free of charge, to any person obtaining a copy of
				// this software and associated documentation files (the "Software"), to deal in
				// the Software without restriction, including without limitation the rights to
				// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
				// the Software, and to permit persons to whom the Software is furnished to do so,
				// subject to the following conditions:
				//
				// The above copyright notice and this permission notice shall be included in all
				// copies or substantial portions of the Software.
				//
				// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
				// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
				// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
				// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
				// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
				// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
				///////////////////////////////////////////////////////////////////////////////////



				const CONSTANTS = __webpack_require__(0);

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
				class Framebuffer {

					constructor(gl, appState) {
						this.gl = gl;
						this.framebuffer = gl.createFramebuffer();
						this.appState = appState;

						this.numColorTargets = 0;

						this.colorTextures = [];
						this.colorAttachments = [];
						this.colorTextureTargets = [];
						this.depthTexture = null;
						this.depthTextureTarget = null;
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
					colorTarget(index, texture, target = texture.is3D ? 0 : CONSTANTS.TEXTURE_2D) {

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
					}

					/**
						Attach a depth target to this framebuffer.

						@method
						@param {Texture} texture The texture to attach.
						@param {GLEnum} [target] The texture target or layer to attach. If the texture is 3D or a texture array,
							defaults to 0, otherwise to TEXTURE_2D.
						@return {Framebuffer} The Framebuffer object.
					*/
					depthTarget(texture, target = texture.is3D ? 0 : CONSTANTS.TEXTURE_2D) {

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
					}

					/**
						Resize all currently attached textures.

						@method
						@param {number} [width=app.width] New width of the framebuffer.
						@param {number} [height=app.height] New height of the framebuffer.
						@return {Framebuffer} The Framebuffer object.
					*/
					resize(width = this.gl.drawingBufferWidth, height = this.gl.drawingBufferHeight, depth) {

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
					}

					/**
						Delete this framebuffer.

						@method
						@return {Framebuffer} The Framebuffer object.
					*/
					delete() {
						if (this.framebuffer) {
							this.gl.deleteFramebuffer(this.framebuffer);
							this.framebuffer = null;
						}

						return this;
					}

					/**
						Bind as the draw framebuffer

						@method
						@ignore
						@return {Framebuffer} The Framebuffer object.
					*/
					bindForDraw() {
						if (this.appState.drawFramebuffer != = this) {
							this.gl.bindFramebuffer(this.gl.DRAW_FRAMEBUFFER, this.framebuffer);
							this.appState.drawFramebuffer = this;
						}

						return this;
					}

					/**
						Bind as the read framebuffer

						@method
						@ignore
						@return {Framebuffer} The Framebuffer object.
					*/
					bindForRead() {
						if (this.appState.readFramebuffer != = this) {
							this.gl.bindFramebuffer(this.gl.READ_FRAMEBUFFER, this.framebuffer);
							this.appState.readFramebuffer = this;
						}

						return this;
					}

					/**
						Bind for a framebuffer state update.
						Capture current binding so we can restore it later.

						@method
						@ignore
						@return {Framebuffer} The Framebuffer object.
					*/
					bindAndCaptureState() {
						let currentFramebuffer = this.appState.drawFramebuffer;

						if (currentFramebuffer != = this) {
							this.gl.bindFramebuffer(this.gl.DRAW_FRAMEBUFFER, this.framebuffer);
						}

						return currentFramebuffer;
					}

					/**
						Bind restore previous binding after state update

						@method
						@ignore
						@return {Framebuffer} The Framebuffer object.
					*/
					restoreState(framebuffer) {
						if (framebuffer != = this) {
							this.gl.bindFramebuffer(this.gl.DRAW_FRAMEBUFFER, framebuffer ? framebuffer.framebuffer : null);
						}

						return this;
					}

				}

				module.exports = Framebuffer;


				/***/
			}),
				/* 9 */
				/***/ (function(module, exports, __webpack_require__) {

				"use strict";
				///////////////////////////////////////////////////////////////////////////////////
				// The MIT License (MIT)
				//
				// Copyright (c) 2017 Tarek Sherif
				//
				// Permission is hereby granted, free of charge, to any person obtaining a copy of
				// this software and associated documentation files (the "Software"), to deal in
				// the Software without restriction, including without limitation the rights to
				// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
				// the Software, and to permit persons to whom the Software is furnished to do so,
				// subject to the following conditions:
				//
				// The above copyright notice and this permission notice shall be included in all
				// copies or substantial portions of the Software.
				//
				// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
				// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
				// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
				// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
				// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
				// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
				///////////////////////////////////////////////////////////////////////////////////



				const CONSTANTS = __webpack_require__(0);
				const Shader = __webpack_require__(2);
				const Uniforms = __webpack_require__(10);

				const SingleComponentUniform = Uniforms.SingleComponentUniform;
				const MultiNumericUniform = Uniforms.MultiNumericUniform;
				const MultiBoolUniform = Uniforms.MultiBoolUniform;
				const MatrixUniform = Uniforms.MatrixUniform;

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
				class Program {

					constructor(gl, appState, vsSource, fsSource, xformFeebackVars) {
						let i;

						let vShader, fShader;

						let ownVertexShader = false;
						let ownFragmentShader = false;
						if (typeof vsSource == = "string") {
							vShader = new Shader(gl, gl.VERTEX_SHADER, vsSource);
							ownVertexShader = true;
						}
						else {
							vShader = vsSource;
						}

						if (typeof fsSource == = "string") {
							fShader = new Shader(gl, gl.FRAGMENT_SHADER, fsSource);
							ownFragmentShader = true;
						}
						else {
							fShader = fsSource;
						}

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
					}

					/**
						Delete this program.

						@method
						@return {Program} The Program object.
					*/
					delete() {
						if (this.program) {
							this.gl.deleteProgram(this.program);
							this.program = null;
						}

						return this;
					}

					/**
						Set the value of a uniform.

						@method
						@ignore
						@return {Program} The Program object.
					*/
					uniform(name, value) {
						this.uniforms[name].set(value);

						return this;
					}

					// 
					/**
						Use this program.

						@method
						@ignore
						@return {Program} The Program object.
					*/
					bind() {
						if (this.appState.program != = this) {
							this.gl.useProgram(this.program);
							this.appState.program = this;
						}

						return this;
					}
				}

				module.exports = Program;


				/***/
			}),
				/* 10 */
				/***/ (function(module, exports, __webpack_require__) {

				"use strict";
				///////////////////////////////////////////////////////////////////////////////////
				// The MIT License (MIT)
				//
				// Copyright (c) 2017 Tarek Sherif
				//
				// Permission is hereby granted, free of charge, to any person obtaining a copy of
				// this software and associated documentation files (the "Software"), to deal in
				// the Software without restriction, including without limitation the rights to
				// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
				// the Software, and to permit persons to whom the Software is furnished to do so,
				// subject to the following conditions:
				//
				// The above copyright notice and this permission notice shall be included in all
				// copies or substantial portions of the Software.
				//
				// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
				// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
				// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
				// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
				// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
				// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
				///////////////////////////////////////////////////////////////////////////////////



				const CONSTANTS = __webpack_require__(0);

				// Classes to manage uniform value updates, including
				// caching current values.

				const UNIFORM_FUNC_NAME = {};
				UNIFORM_FUNC_NAME[CONSTANTS.BOOL] = "uniform1i";
				UNIFORM_FUNC_NAME[CONSTANTS.INT] = "uniform1i";
				UNIFORM_FUNC_NAME[CONSTANTS.SAMPLER_2D] = "uniform1i";
				UNIFORM_FUNC_NAME[CONSTANTS.INT_SAMPLER_2D] = "uniform1i";
				UNIFORM_FUNC_NAME[CONSTANTS.UNSIGNED_INT_SAMPLER_2D] = "uniform1i";
				UNIFORM_FUNC_NAME[CONSTANTS.SAMPLER_2D_SHADOW] = "uniform1i";
				UNIFORM_FUNC_NAME[CONSTANTS.SAMPLER_2D_ARRAY] = "uniform1i";
				UNIFORM_FUNC_NAME[CONSTANTS.INT_SAMPLER_2D_ARRAY] = "uniform1i";
				UNIFORM_FUNC_NAME[CONSTANTS.UNSIGNED_INT_SAMPLER_2D_ARRAY] = "uniform1i";
				UNIFORM_FUNC_NAME[CONSTANTS.SAMPLER_2D_ARRAY_SHADOW] = "uniform1i";
				UNIFORM_FUNC_NAME[CONSTANTS.SAMPLER_CUBE] = "uniform1i";
				UNIFORM_FUNC_NAME[CONSTANTS.INT_SAMPLER_CUBE] = "uniform1i";
				UNIFORM_FUNC_NAME[CONSTANTS.UNSIGNED_INT_SAMPLER_CUBE] = "uniform1i";
				UNIFORM_FUNC_NAME[CONSTANTS.SAMPLER_CUBE_SHADOW] = "uniform1i";
				UNIFORM_FUNC_NAME[CONSTANTS.SAMPLER_3D] = "uniform1i";
				UNIFORM_FUNC_NAME[CONSTANTS.INT_SAMPLER_3D] = "uniform1i";
				UNIFORM_FUNC_NAME[CONSTANTS.UNSIGNED_INT_SAMPLER_3D] = "uniform1i";
				UNIFORM_FUNC_NAME[CONSTANTS.UNSIGNED_INT] = "uniform1ui";
				UNIFORM_FUNC_NAME[CONSTANTS.FLOAT] = "uniform1f";
				UNIFORM_FUNC_NAME[CONSTANTS.FLOAT_VEC2] = "uniform2f";
				UNIFORM_FUNC_NAME[CONSTANTS.FLOAT_VEC3] = "uniform3f";
				UNIFORM_FUNC_NAME[CONSTANTS.FLOAT_VEC4] = "uniform4f";
				UNIFORM_FUNC_NAME[CONSTANTS.INT_VEC2] = "uniform2i";
				UNIFORM_FUNC_NAME[CONSTANTS.INT_VEC3] = "uniform3i";
				UNIFORM_FUNC_NAME[CONSTANTS.INT_VEC4] = "uniform4i";
				UNIFORM_FUNC_NAME[CONSTANTS.UNSIGNED_INT_VEC2] = "uniform2ui";
				UNIFORM_FUNC_NAME[CONSTANTS.UNSIGNED_INT_VEC3] = "uniform3ui";
				UNIFORM_FUNC_NAME[CONSTANTS.UNSIGNED_INT_VEC4] = "uniform4ui";
				UNIFORM_FUNC_NAME[CONSTANTS.BOOL_VEC2] = "uniform2i";
				UNIFORM_FUNC_NAME[CONSTANTS.BOOL_VEC3] = "uniform3i";
				UNIFORM_FUNC_NAME[CONSTANTS.BOOL_VEC4] = "uniform4i";
				UNIFORM_FUNC_NAME[CONSTANTS.FLOAT_MAT2] = "uniformMatrix2fv";
				UNIFORM_FUNC_NAME[CONSTANTS.FLOAT_MAT3] = "uniformMatrix3fv";
				UNIFORM_FUNC_NAME[CONSTANTS.FLOAT_MAT4] = "uniformMatrix4fv";
				UNIFORM_FUNC_NAME[CONSTANTS.FLOAT_MAT2x3] = "uniformMatrix2x3fv";
				UNIFORM_FUNC_NAME[CONSTANTS.FLOAT_MAT2x4] = "uniformMatrix2x4fv";
				UNIFORM_FUNC_NAME[CONSTANTS.FLOAT_MAT3x2] = "uniformMatrix3x2fv";
				UNIFORM_FUNC_NAME[CONSTANTS.FLOAT_MAT3x4] = "uniformMatrix3x4fv";
				UNIFORM_FUNC_NAME[CONSTANTS.FLOAT_MAT4x2] = "uniformMatrix4x2fv";
				UNIFORM_FUNC_NAME[CONSTANTS.FLOAT_MAT4x3] = "uniformMatrix4x3fv";

				const UNIFORM_COMPONENT_COUNT = {};
				UNIFORM_COMPONENT_COUNT[CONSTANTS.BOOL] = 1;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.INT] = 1;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.SAMPLER_2D] = 1;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.INT_SAMPLER_2D] = 1;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.UNSIGNED_INT_SAMPLER_2D] = 1;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.SAMPLER_2D_SHADOW] = 1;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.SAMPLER_2D_ARRAY] = 1;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.INT_SAMPLER_2D_ARRAY] = 1;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.UNSIGNED_INT_SAMPLER_2D_ARRAY] = 1;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.SAMPLER_2D_ARRAY_SHADOW] = 1;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.SAMPLER_CUBE] = 1;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.INT_SAMPLER_CUBE] = 1;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.UNSIGNED_INT_SAMPLER_CUBE] = 1;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.SAMPLER_CUBE_SHADOW] = 1;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.SAMPLER_3D] = 1;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.INT_SAMPLER_3D] = 1;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.UNSIGNED_INT_SAMPLER_3D] = 1;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.UNSIGNED_INT] = 1;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.FLOAT] = 1;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.FLOAT_VEC2] = 2;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.FLOAT_VEC3] = 3;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.FLOAT_VEC4] = 4;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.INT_VEC2] = 2;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.INT_VEC3] = 3;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.INT_VEC4] = 4;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.UNSIGNED_INT_VEC2] = 2;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.UNSIGNED_INT_VEC3] = 3;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.UNSIGNED_INT_VEC4] = 4;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.BOOL_VEC2] = 2;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.BOOL_VEC3] = 3;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.BOOL_VEC4] = 4;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.FLOAT_MAT2] = 4;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.FLOAT_MAT3] = 9;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.FLOAT_MAT4] = 16;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.FLOAT_MAT2x3] = 6;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.FLOAT_MAT2x4] = 8;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.FLOAT_MAT3x2] = 6;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.FLOAT_MAT3x4] = 12;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.FLOAT_MAT4x2] = 8;
				UNIFORM_COMPONENT_COUNT[CONSTANTS.FLOAT_MAT4x3] = 12;

				const UNIFORM_CACHE_CLASS = {};
				UNIFORM_CACHE_CLASS[CONSTANTS.INT] = Int32Array;
				UNIFORM_CACHE_CLASS[CONSTANTS.SAMPLER_2D] = Int32Array;
				UNIFORM_CACHE_CLASS[CONSTANTS.INT_SAMPLER_2D] = Int32Array;
				UNIFORM_CACHE_CLASS[CONSTANTS.UNSIGNED_INT_SAMPLER_2D] = Int32Array;
				UNIFORM_CACHE_CLASS[CONSTANTS.SAMPLER_2D_SHADOW] = Int32Array;
				UNIFORM_CACHE_CLASS[CONSTANTS.SAMPLER_2D_ARRAY] = Int32Array;
				UNIFORM_CACHE_CLASS[CONSTANTS.INT_SAMPLER_2D_ARRAY] = Int32Array;
				UNIFORM_CACHE_CLASS[CONSTANTS.UNSIGNED_INT_SAMPLER_2D_ARRAY] = Int32Array;
				UNIFORM_CACHE_CLASS[CONSTANTS.SAMPLER_2D_ARRAY_SHADOW] = Int32Array;
				UNIFORM_CACHE_CLASS[CONSTANTS.SAMPLER_CUBE] = Int32Array;
				UNIFORM_CACHE_CLASS[CONSTANTS.INT_SAMPLER_CUBE] = Int32Array;
				UNIFORM_CACHE_CLASS[CONSTANTS.UNSIGNED_INT_SAMPLER_CUBE] = Int32Array;
				UNIFORM_CACHE_CLASS[CONSTANTS.SAMPLER_CUBE_SHADOW] = Int32Array;
				UNIFORM_CACHE_CLASS[CONSTANTS.SAMPLER_3D] = Int32Array;
				UNIFORM_CACHE_CLASS[CONSTANTS.INT_SAMPLER_3D] = Int32Array;
				UNIFORM_CACHE_CLASS[CONSTANTS.UNSIGNED_INT_SAMPLER_3D] = Int32Array;
				UNIFORM_CACHE_CLASS[CONSTANTS.UNSIGNED_INT] = Uint32Array;
				UNIFORM_CACHE_CLASS[CONSTANTS.FLOAT] = Float32Array;
				UNIFORM_CACHE_CLASS[CONSTANTS.FLOAT_VEC2] = Float32Array;
				UNIFORM_CACHE_CLASS[CONSTANTS.FLOAT_VEC3] = Float32Array;
				UNIFORM_CACHE_CLASS[CONSTANTS.FLOAT_VEC4] = Float32Array;
				UNIFORM_CACHE_CLASS[CONSTANTS.INT_VEC2] = Int32Array;
				UNIFORM_CACHE_CLASS[CONSTANTS.INT_VEC3] = Int32Array;
				UNIFORM_CACHE_CLASS[CONSTANTS.INT_VEC4] = Int32Array;
				UNIFORM_CACHE_CLASS[CONSTANTS.UNSIGNED_INT_VEC2] = Uint32Array;
				UNIFORM_CACHE_CLASS[CONSTANTS.UNSIGNED_INT_VEC3] = Uint32Array;
				UNIFORM_CACHE_CLASS[CONSTANTS.UNSIGNED_INT_VEC4] = Uint32Array;

				class SingleComponentUniform {

					constructor(gl, handle, type) {
						this.gl = gl;
						this.handle = handle;
						this.glFuncName = UNIFORM_FUNC_NAME[type];
						this.cache = type == = CONSTANTS.BOOL ? false : 0;
					}

					set(value) {
						if (this.cache != = value) {
							this.gl[this.glFuncName](this.handle, value);
							this.cache = value;
						}
					}

				}

				class MultiNumericUniform {

					constructor(gl, handle, type, count) {
						this.gl = gl;
						this.handle = handle;
						this.glFuncName = UNIFORM_FUNC_NAME[type] + "v";
						this.count = count;
						this.cache = new UNIFORM_CACHE_CLASS[type](UNIFORM_COMPONENT_COUNT[type] * count);
					}

					set(value) {
						for (let i = 0, len = value.length; i < len; ++i) {
							if (this.cache[i] != = value[i]) {
								this.gl[this.glFuncName](this.handle, value);
								this.cache.set(value);
								return;
							}
						}
					}

				}

				class MultiBoolUniform {

					constructor(gl, handle, type, count) {
						this.gl = gl;
						this.handle = handle;
						this.glFuncName = UNIFORM_FUNC_NAME[type] + "v";
						this.count = count;
						this.cache = new Array(UNIFORM_COMPONENT_COUNT[type] * count).fill(false);
					}

					set(value) {
						for (let i = 0, len = value.length; i < len; ++i) {
							if (this.cache[i] != = value[i]) {
								this.gl[this.glFuncName](this.handle, value);
								for (let j = i; j < len; j++) {
									this.cache[j] = value[j];
								}
								return;
							}
						}
					}

				}

				class MatrixUniform {

					constructor(gl, handle, type, count) {
						this.gl = gl;
						this.handle = handle;
						this.glFuncName = UNIFORM_FUNC_NAME[type];
						this.count = count;
						this.cache = new Float32Array(UNIFORM_COMPONENT_COUNT[type] * count);
					}

					set(value) {
						for (let i = 0, len = value.length; i < len; ++i) {
							if (this.cache[i] != = value[i]) {
								this.gl[this.glFuncName](this.handle, false, value);
								this.cache.set(value);
								return;
							}
						}
					}

				}

				module.exports.SingleComponentUniform = SingleComponentUniform;
				module.exports.MultiNumericUniform = MultiNumericUniform;
				module.exports.MultiBoolUniform = MultiBoolUniform;
				module.exports.MatrixUniform = MatrixUniform;


				/***/
			}),
				/* 11 */
				/***/ (function(module, exports, __webpack_require__) {

				"use strict";
				///////////////////////////////////////////////////////////////////////////////////
				// The MIT License (MIT)
				//
				// Copyright (c) 2017 Tarek Sherif
				//
				// Permission is hereby granted, free of charge, to any person obtaining a copy of
				// this software and associated documentation files (the "Software"), to deal in
				// the Software without restriction, including without limitation the rights to
				// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
				// the Software, and to permit persons to whom the Software is furnished to do so,
				// subject to the following conditions:
				//
				// The above copyright notice and this permission notice shall be included in all
				// copies or substantial portions of the Software.
				//
				// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
				// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
				// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
				// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
				// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
				// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
				///////////////////////////////////////////////////////////////////////////////////



				const CONSTANTS = __webpack_require__(0);
				const TEXTURE_FORMAT_DEFAULTS = __webpack_require__(1);

				const DUMMY_ARRAY = new Array(1);

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
				class Texture {
					constructor(gl, appState, binding, image, width = image.width, height = image.height, depth, is3D, options = CONSTANTS.DUMMY_OBJECT) {
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
					}

					/**
						Re-allocate texture storage.

						@method
						@param {number} width Image width.
						@param {number} height Image height.
						@param {number} [depth] Image depth or number of images. Required when passing 3D or texture array data.
						@return {Texture} The Texture object.
					*/
					resize(width, height, depth) {
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
					data(data) {
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
					}

					/**
						Delete this texture.

						@method
						@return {Texture} The Texture object.
					*/
					delete() {
						if (this.texture) {
							this.gl.deleteTexture(this.texture);
							this.texture = null;

							if (this.currentUnit != = -1 && this.appState.textures[this.currentUnit] == = this) {
								this.appState.textures[this.currentUnit] = null;
								this.currentUnit = -1;
							}
						}

						return this;
					}

					/**
						Bind this texture to a texture unit.

						@method
						@ignore
						@return {Texture} The Texture object.
					*/
					bind(unit) {
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
					}

				}

				module.exports = Texture;


				/***/
			}),
				/* 12 */
				/***/ (function(module, exports, __webpack_require__) {

				"use strict";
				///////////////////////////////////////////////////////////////////////////////////
				// The MIT License (MIT)
				//
				// Copyright (c) 2017 Tarek Sherif
				//
				// Permission is hereby granted, free of charge, to any person obtaining a copy of
				// this software and associated documentation files (the "Software"), to deal in
				// the Software without restriction, including without limitation the rights to
				// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
				// the Software, and to permit persons to whom the Software is furnished to do so,
				// subject to the following conditions:
				//
				// The above copyright notice and this permission notice shall be included in all
				// copies or substantial portions of the Software.
				//
				// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
				// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
				// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
				// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
				// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
				// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
				///////////////////////////////////////////////////////////////////////////////////



				const CONSTANTS = __webpack_require__(0);
				const Query = __webpack_require__(3);

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
				class Timer {

					constructor(gl) {
						this.gl = gl;
						this.cpuTimer = window.performance || window.Date;

						// Note(Tarek): Firefox for some reason only supports EXT_disjoint_timer_query, so have to try both
						var gpuTimerExtension = this.gl.getExtension("EXT_disjoint_timer_query_webgl2") || this.gl.getExtension("EXT_disjoint_timer_query");
						if (gpuTimerExtension) {
							this.gpuTimer = true;
							this.gpuTimerQuery = new Query(this.gl, CONSTANTS.TIME_ELAPSED_EXT);
						}
						else {
							this.gpuTimer = false;
							this.gpuTimerQuery = null;
						}

						this.cpuStartTime = 0;
						this.cpuTime = 0;
						this.gpuTime = 0;
					}


					/**
						Start timing.

						@method
						@return {Timer} The Timer object.
					*/
					start() {
						if (this.gpuTimer) {
							if (!this.gpuTimerQuery.active) {
								this.gpuTimerQuery.begin();
								this.cpuStartTime = this.cpuTimer.now();
							}
						}
						else {
							this.cpuStartTime = this.cpuTimer.now();
						}

						return this;
					}


					/**
						Stop timing.

						@method
						@return {Timer} The Timer object.
					*/
					end() {
						if (this.gpuTimer) {
							if (!this.gpuTimerQuery.active) {
								this.gpuTimerQuery.end();
								this.cpuTime = this.cpuTimer.now() - this.cpuStartTime;
							}
						}
						else {
							this.cpuTime = this.cpuTimer.now() - this.cpuStartTime;
						}

						return this;
					}

					/**
						Check if timing results are available. If
						this method returns true, the cpuTime and
						gpuTime properties will be set to valid
						values.

						@method
						@return {boolean} If results are available.
					*/
					ready() {
						if (this.gpuTimer) {
							if (!this.gpuTimerQuery.active) {
								return false;
							}

							var gpuTimerAvailable = this.gpuTimerQuery.ready();
							var gpuTimerDisjoint = this.gl.getParameter(CONSTANTS.GPU_DISJOINT_EXT);

							if (gpuTimerAvailable && !gpuTimerDisjoint) {
								this.gpuTime = this.gpuTimerQuery.result / 1000000;
								return true;
							}
							else {
								return false;
							}
						}
						else {
							return !!this.cpuStartTime;
						}
					}

					/**
						Delete this timer.

						@method
						@return {Timer} The Timer object.
					*/
					delete() {
						if (this.gpuTimerQuery) {
							this.gpuTimerQuery.delete();
							this.gpuTimerQuery = null;
							this.gpuTimer = false;
						}

						return this;
					}

				}

				module.exports = Timer;


				/***/
			}),
				/* 13 */
				/***/ (function(module, exports, __webpack_require__) {

				"use strict";
				///////////////////////////////////////////////////////////////////////////////////
				// The MIT License (MIT)
				//
				// Copyright (c) 2017 Tarek Sherif
				//
				// Permission is hereby granted, free of charge, to any person obtaining a copy of
				// this software and associated documentation files (the "Software"), to deal in
				// the Software without restriction, including without limitation the rights to
				// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
				// the Software, and to permit persons to whom the Software is furnished to do so,
				// subject to the following conditions:
				//
				// The above copyright notice and this permission notice shall be included in all
				// copies or substantial portions of the Software.
				//
				// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
				// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
				// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
				// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
				// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
				// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
				///////////////////////////////////////////////////////////////////////////////////



				/**
					Tranform feedback object.

					@class
					@prop {WebGLRenderingContext} gl The WebGL context.
					@prop {WebGLTransformFeedback} transformFeedback Transform feedback object.
					@prop {Object} appState Tracked GL state.
				*/
				class TransformFeedback {

					constructor(gl, appState) {
						this.gl = gl;
						this.transformFeedback = gl.createTransformFeedback();
						this.appState = appState;

						// TODO(Tarek): Need to rebind buffers due to bug in ANGLE.
						// Remove this when that's fixed.
						this.angleBugBuffers = [];
					}

					/**
						Bind a feedback buffer to capture transform output.

						@method
						@param {number} index Index of transform feedback varying to capture.
						@param {VertexBuffer} buffer Buffer to record output into.
						@return {TransformFeedback} The TransformFeedback object.
					*/
					feedbackBuffer(index, buffer) {
						this.gl.bindTransformFeedback(this.gl.TRANSFORM_FEEDBACK, this.transformFeedback);
						this.gl.bindBufferBase(this.gl.TRANSFORM_FEEDBACK_BUFFER, index, buffer.buffer);
						this.gl.bindTransformFeedback(this.gl.TRANSFORM_FEEDBACK, null);
						this.gl.bindBufferBase(this.gl.TRANSFORM_FEEDBACK_BUFFER, index, null);

						this.angleBugBuffers[index] = buffer;

						return this;
					}

					/**
						Delete this transform feedback.

						@method
						@return {TransformFeedback} The TransformFeedback object.
					*/
					delete() {
						if (this.transformFeedback) {
							this.gl.deleteTransformFeedback(this.transformFeedback);
							this.transformFeedback = null;
						}

						return this;
					}

					/**
						Bind this transform feedback.

						@method
						@ignore
						@return {TransformFeedback} The TransformFeedback object.
					*/
					bind() {
						if (this.appState.transformFeedback != = this) {
							this.gl.bindTransformFeedback(this.gl.TRANSFORM_FEEDBACK, this.transformFeedback);

							for (let i = 0, len = this.angleBugBuffers.length; i < len; ++i) {
								this.gl.bindBufferBase(this.gl.TRANSFORM_FEEDBACK_BUFFER, i, this.angleBugBuffers[i].buffer);
							}

							this.appState.transformFeedback = this;
						}

						return this;
					}

				}

				module.exports = TransformFeedback;


				/***/
			}),
				/* 14 */
				/***/ (function(module, exports, __webpack_require__) {

				"use strict";
				///////////////////////////////////////////////////////////////////////////////////
				// The MIT License (MIT)
				//
				// Copyright (c) 2017 Tarek Sherif
				//
				// Permission is hereby granted, free of charge, to any person obtaining a copy of
				// this software and associated documentation files (the "Software"), to deal in
				// the Software without restriction, including without limitation the rights to
				// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
				// the Software, and to permit persons to whom the Software is furnished to do so,
				// subject to the following conditions:
				//
				// The above copyright notice and this permission notice shall be included in all
				// copies or substantial portions of the Software.
				//
				// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
				// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
				// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
				// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
				// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
				// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
				///////////////////////////////////////////////////////////////////////////////////



				const CONSTANTS = __webpack_require__(0);

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
				class UniformBuffer {

					constructor(gl, appState, layout, usage = gl.DYNAMIC_DRAW) {
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
					}

					/**
						Update data for a given item in the buffer. NOTE: Data is not
						sent the the GPU until the update() method is called!

						@method
						@param {number} index Index in the layout of item to set.
						@param {ArrayBufferView} value Value to store at the layout location.
						@return {UniformBuffer} The UniformBuffer object.
					*/
					set(index, value) {
						let view = this.dataViews[this.types[index]];

						if (this.sizes[index] == = 1) {
							view[this.offsets[index]] = value;
						}
						else {
							view.set(value, this.offsets[index]);
						}

						return this;
					}

					/**
						Send stored buffer data to the GPU.

						@method
						@param {number} [index] Index in the layout of item to send to the GPU. If ommited, entire buffer is sent.
						@return {UniformBuffer} The UniformBuffer object.
					*/
					update(index) {
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
					}

					/**
						Delete this uniform buffer.

						@method
						@return {UniformBuffer} The UniformBuffer object.
					*/
					delete() {
						if (this.buffer) {
							this.gl.deleteBuffer(this.buffer);
							this.buffer = null;

							if (this.currentBase != = -1 && this.appState.uniformBuffers[this.currentBase] == = this) {
								this.appState.uniformBuffers[this.currentBase] = null;
							}
						}

						return this;
					}

					/**
						Bind this uniform buffer to the given base.

						@method
						@ignore
						@return {UniformBuffer} The UniformBuffer object.
					*/
					bind(base) {
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
					}

				}

				module.exports = UniformBuffer;


				/***/
			}),
				/* 15 */
				/***/ (function(module, exports, __webpack_require__) {

				"use strict";
				// Copyright (c) 2017 Tarek Sherif
				//
				// Permission is hereby granted, free of charge, to any person obtaining a copy of
				// this software and associated documentation files (the "Software"), to deal in
				// the Software without restriction, including without limitation the rights to
				// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
				// the Software, and to permit persons to whom the Software is furnished to do so,
				// subject to the following conditions:
				//
				// The above copyright notice and this permission notice shall be included in all
				// copies or substantial portions of the Software.
				//
				// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
				// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
				// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
				// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
				// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
				// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
				///////////////////////////////////////////////////////////////////////////////////



				const CONSTANTS = __webpack_require__(0);

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
				class VertexArray {

					constructor(gl, appState) {
						this.gl = gl;
						this.vertexArray = gl.createVertexArray();
						this.appState = appState;
						this.numElements = 0;
						this.indexType = null;
						this.instancedBuffers = 0;
						this.indexed = false;
						this.numInstances = 0;
					}

					/**
						Bind an per-vertex attribute buffer to this vertex array.

						@method
						@param {number} attributeIndex The attribute location to bind to.
						@param {VertexBuffer} vertexBuffer The VertexBuffer to bind.
						@return {VertexArray} The VertexArray object.
					*/
					vertexAttributeBuffer(attributeIndex, vertexBuffer) {
						this.attributeBuffer(attributeIndex, vertexBuffer, false, false, false);

						return this;
					}

					/**
						Bind an per-instance attribute buffer to this vertex array.

						@method
						@param {number} attributeIndex The attribute location to bind to.
						@param {VertexBuffer} vertexBuffer The VertexBuffer to bind.
						@return {VertexArray} The VertexArray object.
					*/
					instanceAttributeBuffer(attributeIndex, vertexBuffer) {
						this.attributeBuffer(attributeIndex, vertexBuffer, true, false, false);

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
					vertexIntegerAttributeBuffer(attributeIndex, vertexBuffer) {
						this.attributeBuffer(attributeIndex, vertexBuffer, false, true, false);

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
					instanceIntegerAttributeBuffer(attributeIndex, vertexBuffer) {
						this.attributeBuffer(attributeIndex, vertexBuffer, true, true, false);

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
					vertexNormalizedAttributeBuffer(attributeIndex, vertexBuffer) {
						this.attributeBuffer(attributeIndex, vertexBuffer, false, false, true);

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
					instanceNormalizedAttributeBuffer(attributeIndex, vertexBuffer) {
						this.attributeBuffer(attributeIndex, vertexBuffer, true, false, true);

						return this;
					}

					/**
						Bind an index buffer to this vertex array.

						@method
						@param {VertexBuffer} vertexBuffer The VertexBuffer to bind.
						@return {VertexArray} The VertexArray object.
					*/
					indexBuffer(vertexBuffer) {
						this.gl.bindVertexArray(this.vertexArray);
						this.gl.bindBuffer(vertexBuffer.binding, vertexBuffer.buffer);

						this.numElements = vertexBuffer.numItems * 3;
						this.indexType = vertexBuffer.type;
						this.indexed = true;

						this.gl.bindVertexArray(null);
						this.gl.bindBuffer(vertexBuffer.binding, null);

						return this;
					}

					/**
						Delete this vertex array.

						@method
						@return {VertexArray} The VertexArray object.
					*/
					delete() {
						if (this.vertexArray) {
							this.gl.deleteVertexArray(this.vertexArray);
							this.vertexArray = null;
						}
						this.gl.bindVertexArray(null);

						return this;
					}

					/**
						Bind this vertex array.

						@method
						@ignore
						@return {VertexArray} The VertexArray object.
					*/
					bind() {
						if (this.appState.vertexArray != = this) {
							this.gl.bindVertexArray(this.vertexArray);
							this.appState.vertexArray = this;
						}

						return this;
					}

					/**
						Attach an attribute buffer

						@method
						@ignore
						@return {VertexArray} The VertexArray object.
					*/
					attributeBuffer(attributeIndex, vertexBuffer, instanced, integer, normalized) {
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
					}

				}

				module.exports = VertexArray;


				/***/
			}),
				/* 16 */
				/***/ (function(module, exports, __webpack_require__) {

				"use strict";
				///////////////////////////////////////////////////////////////////////////////////
				// The MIT License (MIT)
				//
				// Copyright (c) 2017 Tarek Sherif
				//
				// Permission is hereby granted, free of charge, to any person obtaining a copy of
				// this software and associated documentation files (the "Software"), to deal in
				// the Software without restriction, including without limitation the rights to
				// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
				// the Software, and to permit persons to whom the Software is furnished to do so,
				// subject to the following conditions:
				//
				// The above copyright notice and this permission notice shall be included in all
				// copies or substantial portions of the Software.
				//
				// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
				// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
				// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
				// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
				// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
				// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
				///////////////////////////////////////////////////////////////////////////////////



				const CONSTANTS = __webpack_require__(0);

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
				class VertexBuffer {

					constructor(gl, appState, type, itemSize, data, usage = gl.STATIC_DRAW, indexArray) {
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
					}

					/**
						Update data in this buffer. NOTE: the data must fit
						the originally-allocated buffer!

						@method
						@param {VertexBufferView} data Data to store in the buffer.
						@return {VertexBuffer} The VertexBuffer object.
					*/
					data(data) {
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
					}

					/**
						Delete this array buffer.

						@method
						@return {VertexBuffer} The VertexBuffer object.
					*/
					delete() {
						if (this.buffer) {
							this.gl.deleteBuffer(this.buffer);
							this.buffer = null;
						}

						return this;
					}

				}

				module.exports = VertexBuffer;


				/***/
			})
				/******/ ]);
});

#endif