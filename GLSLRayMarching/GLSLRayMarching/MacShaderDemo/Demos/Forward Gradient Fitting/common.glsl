

// fit a random cloud of points instead
#define FIT_POINTS 64
// use triangle wave (PSIREN) rather than sinusoid (SIREN)
#define USE_TRI 0

// if 0, project random vector; if 1, compute full gradient (slow, O(n^2) for n weights)
// empirically, stochastic descent takes longer to ramp up speed, but appears to take
// twice as many steps, but converges much faster in this shader, simply because the
// framerate is higher.
// using newton stepmethods requires a full gradient
#define FULL_GRADIENT 0

// forward gradient descent (https://arxiv.org/abs/2202.08587)
#define METHOD_FGD 0
// Adam gradient descent (https://arxiv.org/abs/1412.6980, algorithm 1)
#define METHOD_ADAM 1
// AdaMax gradient descent (https://arxiv.org/abs/1412.6980, algorithm 2)
#define METHOD_ADAMAX 2

//#define METHOD METHOD_ADAM
#define METHOD METHOD_FGD

// step by negative gradient
#define STEPMETHOD_GRADIENT 0
// step by newton's method, unbounded
#define STEPMETHOD_NEWTON 1
// step by newton's method, clamped (this one is quite good for functions with discontinuities)
#define STEPMETHOD_CLAMP_NEWTON 2
const float newton_clamp_limit = 10.0;
// step by newton's method, softclamped (same)
#define STEPMETHOD_SOFTCLAMP_NEWTON 3

#define STEPMETHOD STEPMETHOD_GRADIENT
//#define STEPMETHOD STEPMETHOD_CLAMP_NEWTON

// if 1, smooth result with exponential moving average; needs restart
// (https://arxiv.org/abs/1412.6980, 7.2)
#define EMA 0

#if (METHOD == METHOD_ADAMAX)
const float alpha = 0.002;
#elif (METHOD == METHOD_ADAM)
const float alpha = 0.001;
#else
const float alpha = 0.001;
#endif
#if FULL_GRADIENT
const float beta1 = 0.9;
const float beta2 = 0.999;
#else
const float beta1 = 0.95;
const float beta2 = 0.9995;
#endif
const float epsilon = 10.0 * 1e-8;

const float max_float = 3.402e+38;

// for stochastic descent, if set to 1, clamp the random gradient
// close to infinity and normalize.
#define NORMALIZE_MC_GRADIENT 0
#if NORMALIZE_MC_GRADIENT
const float gradient_clamp = 3.402e+38;
#else
// for stochastic descent, clamp the generated gaussian amplitudes
// not doing so can cause sudden inf/nan death.
const float gradient_clamp = 1.0;
#endif

float smoothReLU(float x, float r) {
    float xa = abs(x);
    float c = max(r - xa, 0.0);
    return 0.5*x + 0.5*xa + 0.25*c*c/r;
}
float smoothReLUdx(float x, float r) {
    return clamp(0.5 + 0.5*x/r,0.0,1.0);
}

vec2 explu(vec2 x) {
    float w = exp(x.x);
    return vec2(w, x.y*w);
}

vec2 relu(vec2 x) {
    return vec2(
        max(0.0, x.x),
        x.y*step(0.0, x.x));
}

vec2 gelu(float x) {
    float w = exp(x);
    float ww = w + 1.0;
    return vec2(
        x*w/(1.0 + w),
        w*(x + w + 1.0) / (ww*ww));
}

float s_K = 1.0;

vec2 clamped_relu(vec2 x) {
    return vec2(
        clamp(x.x, 0.0, 1.0),
        x.y*step(0.0,x.x)*step(x.x,1.0));
}

vec2 logistic(vec2 x) {
    float w = exp(-x.x);
    float w1 = w + 1.0;
    return vec2(
        1.0 / (1.0 + w),
        x.y*w/(w1*w1));
}

vec2 tanhlu(vec2 x) {
    float w = tanh(x.x);
    return vec2(w, x.y*(1.0 - w*w));
}

// logistic function over 0..1, with unit rate of change
// the smooth version of clamped_relu()
vec2 logistic_unit(vec2 x) {
    float w = exp(-4.0*x.x + 2.0);
    float w1 = w + 1.0;
    return vec2(
        1.0 / (1.0 + w),
        4.0*x.y*w/(w1*w1));
}

// logistic unit clamped to zero 
vec2 clamped_logistic_unit(vec2 x) {
    const float K = exp(0.01);
    vec2 q = x;
    q.x -= 0.5;
    q /= K;
    q.x += 0.5;
    q = logistic_unit(x);
    q.x -= 0.5;
    q *= K;
    q.x += 0.5;
    return clamped_relu(q);
}

// inverse of logistic unit
vec2 inv_logistic_unit(vec2 x) {
    return vec2(
        0.5 - 0.25*log(1.0/x.x - 1.0),
        x.y*0.25/((1.0 / x.x - 1.0)*x.x*x.x));
}

vec2 lerp_logistic_unit_to_clamped_relu(vec2 x) {
    vec2 b = clamped_relu(x);
    if (s_K < 1e-3)
        return b;
    vec2 a = logistic_unit(x);
    return mix(b, a, s_K);
}

vec2 crazy(vec2 x) {
    float w = exp(-x.x*x.x);
    float ws = w*sin(x.x);
    float wc = w*cos(x.x);
    return vec2(
        w,
        x.y*w*(cos(x.x) - 2.0*sin(x.x)*x.x));
}

void setup_s_K(int frame) {
    // after 100 seconds, lower K towards zero, approximating the sharp ReLU function
    float t = float(frame) / 60.0;
    //s_K = 1.0 / (1.0 + pow(float(t)/100.0,2.0));    
    //Random rng = seed(frame);
    s_K = exp(-t/5.0);
    //s_K = 1.0 / (1.0 + t/100.0);
}

/////////////////////////////////////////////////////////////////////////

bool isbad(float x) {
    return isinf(x) || isnan(x);
}

vec2 ad_const(float c) {
    return vec2(c, 0.0);
}

vec2 ad_max(vec2 a, vec2 b) {
    return (a.x > b.x)?a:b;
}

vec2 ad_mul(vec2 a, vec2 b) {
    return vec2(a.x * b.x, a.x*b.y + a.y*b.x);
}
vec2 ad_mul(vec2 a, float b) {
    return a * b;
}
vec2 ad_neg(vec2 a) {
    return -a;
}
vec2 ad_sq(vec2 a) {
    return vec2(a.x * a.x, 2.0*a.x*a.y);
}
vec2 ad_sqrt(vec2 a) {
    float w = sqrt(a.x);
    return vec2(w, 0.5 * a.y / w);
}
vec2 ad_abs(vec2 a) {
    return vec2(abs(a.x), sign(a.x)*a.y);
}
vec2 ad_add(vec2 a, vec2 b) {
    return a + b;
}
vec2 ad_add(vec2 a, float b) {
    return vec2(a.x + b, a.y);
}
vec2 ad_sub(vec2 a, float b) {
    return vec2(a.x - b, a.y);
}
vec2 ad_div(vec2 a, vec2 b) {
    return vec2(a.x / b.x, a.y/b.x - a.x*b.y/(b.x*b.x));
}
vec2 ad_sin(vec2 a) {
    return vec2(sin(a.x), a.y*cos(a.x));
}
const float pi = 3.14159265359;
vec2 ad_sin_L1T(vec2 a) {
    return vec2(
        (abs(2.0-abs(fract(a.x/(2.0*pi))*4.0-1.0))-1.0)*pi/2.0,
        a.y*sign(1.0-fract(a.x/(2.0*pi) + 1.0/4.0)*2.0));
}
vec2 ad_sin_L1(vec2 a) {
    return vec2(
        (abs(2.0-abs(fract(a.x/(2.0*pi))*4.0-1.0))-1.0),
        a.y*sign(1.0-fract(a.x/(2.0*pi) + 1.0/4.0)*2.0))*2.0/pi;
}
vec2 ad_fract(vec2 a) {
    return vec2(
        fract(a.x),
        a.y);
}
vec2 ad_tri(vec2 a) {
    float w = fract(a.x);
    return vec2(
        abs(0.5-w),
        a.y*sign(w-0.5));
}
vec2 ad_mf(vec2 a) {
    float w = fract(a.x);
    return vec2(
        min(w, 0.5),
        step(w, 0.5));
}
vec2 ad_exp2(vec2 a) {
    float w = exp2(a.x);
    return vec2(w, a.y*w*log(2.0));
}
vec2 ad_gfloor(vec2 a) {
    float k = exp2(-4.0);
    float w = floor(a.x/k)*k;
    //return vec2(a.x + w, a.y);
    return vec2(w, a.y);
}

// edit target_func() at the very bottom of this file to define the target to fit


// 2d vector graphics library (https://www.shadertoy.com/view/lslXW8)
// after Cairo API, with anti-aliasing
// by Leonard Ritter (@paniq)
// v0.16

// I release this into the public domain.
// some estimators have been lifted from other shaders and are not
// necessarily PD licensed, note the links in the source code comments below.

// 2020-12-02: 0.16
// * support for drawing concentric rings

// 2020-11-30: 0.15
// * support for drawing orthogonal grids
// * adjusted uv so corners are centered on pixels
// * small adjustment to line pixel width computation

// 2020-11-12: 0.14
// * added support for depth testing

// 2020-11-11: 0.13
// * fixed 2D graphs not filling
// * added circle_px()

// 2019-06-06: 0.12
// * split implementation and demo into common and image tab

// 2017-10-05: 0.11
// * anti-aliasing is gamma-correct

// 2017-10-01: 0.10
// * added experimental letter() function

// 2017-09-30: 0.9
// * save() is now a declarative macro

// 2017-09-11: 0.8
// * added ellipse()

// 2017-09-10: 0.7
// * paths painted with line_to/curve_to can be filled.

// 2017-09-09: 0.6
// * added rounded_rectangle()
// * added set_source_linear_gradient()
// * added set_source_radial_gradient()
// * added set_source_blend_mode()
// * added support for non-uniform scaling

// undefine if you are running on glslsandbox.com
// #define GLSLSANDBOX

#ifdef GLSLSANDBOX
#ifdef GL_ES
#endif
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
#define iTime time
#define iResolution resolution
#define iMouse mouse
#endif

// interface
//////////////////////////////////////////////////////////

// set color source for stroke / fill / clear
void set_source_rgba(vec4 c);
void set_source_rgba(float r, float g, float b, float a);
void set_source_rgb(vec3 c);
void set_source_rgb(float r, float g, float b);
void set_source_linear_gradient(vec3 color0, vec3 color1, vec2 p0, vec2 p1);
void set_source_linear_gradient(vec4 color0, vec4 color1, vec2 p0, vec2 p1);
void set_source_radial_gradient(vec3 color0, vec3 color1, vec2 p, float r);
void set_source_radial_gradient(vec4 color0, vec4 color1, vec2 p, float r);
void set_source(sampler2D image);
void set_source_depth(float depth);
// control how source changes are applied
const int Replace = 0; // default: replace the old source with the new one
const int Alpha = 1; // alpha-blend the new source on top of the old one
const int Multiply = 2; // multiply the new source with the old one
void set_source_blend_mode(int mode);
// if enabled, blends using premultiplied alpha instead of
// regular alpha blending.
void premultiply_alpha(bool enable);
// if enabled, use the depth value for testing;
// smaller values win
void depth_test(bool enable);

// set line width in normalized units for stroke
void set_line_width(float w);
// set line width in pixels for stroke
void set_line_width_px(float w);
// set blur strength for strokes in normalized units
void set_blur(float b);

// add a circle path at P with radius R
void circle(vec2 p, float r);
void circle(float x, float y, float r);
// add a circle path at P with pixel radius R
void circle_px(vec2 p, float r);
void circle_px(float x, float y, float r);
// add an ellipse path at P with radii RW and RH
void ellipse(vec2 p, vec2 r);
void ellipse(float x, float y, float rw, float rh);
// add a rectangle at O with size S
void rectangle(vec2 o, vec2 s);
void rectangle(float ox, float oy, float sx, float sy);
// add a rectangle at O with size S and rounded corner of radius R
void rounded_rectangle(vec2 o, vec2 s, float r);
void rounded_rectangle(float ox, float oy, float sx, float sy, float r);

// add an orthogonal grid with cell size S
void grid(vec2 s);
void grid(float w, float h);
void grid(float s);
// draw concentric rings around origin p, with spacing r and offset phase
void rings(vec2 p, float r, float phase);

// set starting point for curves and lines to P
void move_to(vec2 p);
void move_to(float x, float y);
// draw straight line from starting point to P,
// and set new starting point to P
void line_to(vec2 p);
void line_to(float x, float y);
// draw quadratic bezier curve from starting point
// over B1 to B2 and set new starting point to B2
void curve_to(vec2 b1, vec2 b2);
void curve_to(float b1x, float b1y, float b2x, float b2y);
// connect current starting point with first
// drawing point.
void close_path();

// clear screen in the current source color
void clear();
// fill paths and clear the path buffer
void fill();
// fill paths and preserve them for additional ops
void fill_preserve();
// stroke paths and clear the path buffer
void stroke_preserve();
// stroke paths and preserve them for additional ops
void stroke();
// clears the path buffer
void new_path();

// draw a letter with the given texture coordinate
void letter(sampler2D font_texture_source, ivec2 l);
void letter(sampler2D font_texture_source, int lx, int ly);
    
// return rgb color for given hue (0..1)
vec3 hue(float hue);
// return rgb color for given hue, saturation and lightness
vec3 hsl(float h, float s, float l);
vec4 hsl(float h, float s, float l, float a);

// rotate the context by A in radians
void rotate(float a);
// uniformly scale the context by S
void scale(float s);
// non-uniformly scale the context by S
void scale(vec2 s);
void scale(float sx, float sy);
// translate the context by offset P
void translate(vec2 p);
void translate(float x, float y);
// clear all transformations for the active context
void identity_matrix();
// transform the active context by the given matrix
void transform(mat3 mtx);
// set the transformation matrix for the active context
void set_matrix(mat3 mtx);

// return the active query position for in_fill/in_stroke
// by default, this is the mouse position
vec2 get_query();
// set the query position for subsequent calls to
// in_fill/in_stroke; clears the query path
void set_query(vec2 p);
// true if the query position is inside the current path
bool in_fill();
// true if the query position is inside the current stroke
bool in_stroke();

// return the transformed coordinate of the current pixel
vec2 get_origin();
// draw a 1D graph from coordinate p, result f(p.x),
// and gradient1D(f,p.x)
void graph(vec2 p, float f_x, float df_x);
// draw a 2D graph from coordinate p, result f(p),
// and gradient2D(f,p)
void graph(vec2 p, float f_x, vec2 df_x);
// adds a custom distance field as path
// this field will not be testable by queries
void add_field(float c);

// returns a gradient for 1D graph function f at position x
#define gradient1D(f,x) (f(x + get_gradient_eps()) - f(x - get_gradient_eps())) / (2.0*get_gradient_eps())
// returns a gradient for 2D graph function f at position x
#define gradient2D(f,x) vec2(f(x + vec2(get_gradient_eps(),0.0)) - f(x - vec2(get_gradient_eps(),0.0)),f(x + vec2(0.0,get_gradient_eps())) - f(x - vec2(0.0,get_gradient_eps()))) / (2.0*get_gradient_eps())
// draws a 1D graph at the current position
#define graph1D(f) { vec2 pp = get_origin(); graph(pp, f(pp.x), gradient1D(f,pp.x)); }
// draws a 2D graph at the current position
#define graph2D(f) { vec2 pp = get_origin(); graph(pp, f(pp), gradient2D(f,pp)); }

// represents the current drawing context
// you usually don't need to change anything here
struct Context {
    // screen position, query position
    vec4 position;
    vec2 shape;
    vec2 clip;
    vec2 scale;
    float line_width;
    bool premultiply;
    bool depth_test;
    vec2 blur;
    vec4 source;
    vec2 start_pt;
    vec2 last_pt;
    int source_blend;
    bool has_clip;
    float source_z;
};

// save current stroke width, starting
// point and blend mode from active context.
Context _save();
#define save(name) Context name = _save();
// restore stroke width, starting point
// and blend mode to a context previously returned by save()
void restore(Context ctx);

// draws a half-transparent debug gradient for the
// active path
void debug_gradient();
void debug_clip_gradient();
// returns the gradient epsilon width
float get_gradient_eps();


// implementation
//////////////////////////////////////////////////////////

vec2 aspect;
vec2 uv;
vec2 position;
vec2 query_position;
float ScreenH;
float AA;
float AAINV;

//////////////////////////////////////////////////////////

float det(vec2 a, vec2 b) { return a.x*b.y-b.x*a.y; }

//////////////////////////////////////////////////////////

vec3 hue(float hue) {
    return clamp(
        abs(mod(hue * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0,
        0.0, 1.0);
}

vec3 hsl(float h, float s, float l) {
    vec3 rgb = hue(h);
    return l + s * (rgb - 0.5) * (1.0 - abs(2.0 * l - 1.0));
}

vec4 hsl(float h, float s, float l, float a) {
    return vec4(hsl(h,s,l),a);
}

//////////////////////////////////////////////////////////

#define DEFAULT_SHAPE_V 1e+20
#define DEFAULT_CLIP_V -1e+20
#define DEFAULT_DEPTH 1e+30

Context _stack;

void init (vec2 fragCoord, vec2 mouse, vec2 resolution) {
	aspect = vec2(resolution.x / resolution.y, 1.0);
	ScreenH = min(resolution.x,resolution.y);
	AA = ScreenH*0.5;
	AAINV = 1.0 / AA;
    
    uv = (fragCoord.xy - 0.5) / resolution;
    vec2 m = mouse / resolution;

    position = (uv*2.0-1.0)*aspect;
    query_position = (m*2.0-1.0)*aspect;

    _stack = Context(
        vec4(position, query_position),
        vec2(DEFAULT_SHAPE_V),
        vec2(DEFAULT_CLIP_V),
        vec2(1.0),
        1.0,
        false,
        false,
        vec2(0.0,1.0),
        vec4(vec3(0.0),1.0),
        vec2(0.0),
        vec2(0.0),
        Replace,
        false,
        DEFAULT_DEPTH
    );
}

vec3 _color = vec3(1);
float _depth = DEFAULT_DEPTH;

vec2 get_origin() {
    return _stack.position.xy;
}

vec2 get_query() {
    return _stack.position.zw;
}

void set_query(vec2 p) {
    _stack.position.zw = p;
    _stack.shape.y = DEFAULT_SHAPE_V;
    _stack.clip.y = DEFAULT_CLIP_V;
}

Context _save() {
    return _stack;
}

void restore(Context ctx) {
    // preserve shape
    vec2 shape = _stack.shape;
    vec2 clip = _stack.clip;
    bool has_clip = _stack.has_clip;
    // preserve source
    vec4 source = _stack.source;
    _stack = ctx;
    _stack.shape = shape;
    _stack.clip = clip;
    _stack.source = source;
    _stack.has_clip = has_clip;
}

mat3 mat2x3_invert(mat3 s)
{
    float d = det(s[0].xy,s[1].xy);
    d = (d != 0.0)?(1.0 / d):d;

    return mat3(
        s[1].y*d, -s[0].y*d, 0.0,
        -s[1].x*d, s[0].x*d, 0.0,
        det(s[1].xy,s[2].xy)*d,
        det(s[2].xy,s[0].xy)*d,
        1.0);
}

void identity_matrix() {
    _stack.position = vec4(position, query_position);
    _stack.scale = vec2(1.0);
}

void set_matrix(mat3 mtx) {
    mtx = mat2x3_invert(mtx);
    _stack.position.xy = (mtx * vec3(position,1.0)).xy;
    _stack.position.zw = (mtx * vec3(query_position,1.0)).xy;
    _stack.scale = vec2(length(mtx[0].xy), length(mtx[1].xy));
}

void transform(mat3 mtx) {
    mtx = mat2x3_invert(mtx);
    _stack.position.xy = (mtx * vec3(_stack.position.xy,1.0)).xy;
    _stack.position.zw = (mtx * vec3(_stack.position.zw,1.0)).xy;
    _stack.scale *= vec2(length(mtx[0].xy), length(mtx[1].xy));
}

void rotate(float a) {
    float cs = cos(a), sn = sin(a);
    transform(mat3(
        cs, sn, 0.0,
        -sn, cs, 0.0,
        0.0, 0.0, 1.0));
}

void scale(vec2 s) {
    transform(mat3(s.x,0.0,0.0,0.0,s.y,0.0,0.0,0.0,1.0));
}

void scale(float sx, float sy) {
    scale(vec2(sx, sy));
}

void scale(float s) {
    scale(vec2(s));
}

void translate(vec2 p) {
    transform(mat3(1.0,0.0,0.0,0.0,1.0,0.0,p.x,p.y,1.0));
}

void translate(float x, float y) { translate(vec2(x,y)); }

void clear() {
    _color.rgb = mix(_color.rgb, _stack.source.rgb, _stack.source.a);
    _depth = (_stack.source.a == 1.0)?_stack.source_z:_depth;
}

void blit(out vec4 dest) {
    dest = vec4(pow(_color.rgb, vec3(1.0/2.2)), 1.0);
}

void blit(out vec3 dest) {
    dest = _color.rgb;
}

void add_clip(vec2 d) {
    d = d / _stack.scale;
    _stack.clip = max(_stack.clip, d);
    _stack.has_clip = true;
}

void add_field(vec2 d) {
    d = d / _stack.scale;
    _stack.shape = min(_stack.shape, d);
}

void add_field(float c) {
    _stack.shape.x = min(_stack.shape.x, c);
}

void new_path() {
    _stack.shape = vec2(DEFAULT_SHAPE_V);
    _stack.clip = vec2(DEFAULT_CLIP_V);
    _stack.has_clip = false;
}

void debug_gradient() {
    vec2 d = _stack.shape;
    _color.rgb = mix(_color.rgb,
        hsl(d.x * 6.0,
            1.0, (d.x>=0.0)?0.5:0.3),
        0.5);
}

void debug_clip_gradient() {
    vec2 d = _stack.clip;
    _color.rgb = mix(_color.rgb,
        hsl(d.x * 6.0,
            1.0, (d.x>=0.0)?0.5:0.3),
        0.5);
}

void set_blur(float b) {
    if (b == 0.0) {
        _stack.blur = vec2(0.0, 1.0);
    } else {
        _stack.blur = vec2(
            b,
            0.0);
    }
}

void write_color(vec4 rgba, float w) {
    if (_stack.depth_test) {
        if ((w == 1.0) && (_stack.source_z <= _depth)) {
            _depth = _stack.source_z;
        } else if ((w == 0.0) || (_stack.source_z > _depth)) {            
            return;
        }
    }
    float src_a = w * rgba.a;
    float dst_a = _stack.premultiply?w:src_a;
    _color.rgb = _color.rgb * (1.0 - src_a) + rgba.rgb * dst_a;
}


void depth_test(bool enable) {
    _stack.depth_test = enable;
}

void premultiply_alpha(bool enable) {
    _stack.premultiply = enable;
}

float min_uniform_scale() {
    return min(_stack.scale.x, _stack.scale.y);
}

float uniform_scale_for_aa() {
    return min(1.0, _stack.scale.x / _stack.scale.y);
}

float calc_aa_blur(float w) {
    vec2 blur = _stack.blur;
    w -= blur.x;
    float wa = clamp(-w*AA*uniform_scale_for_aa(), 0.0, 1.0);
    float wb = clamp(-w / blur.x + blur.y, 0.0, 1.0);
	return wa * wb;
}

void fill_preserve() {
    write_color(_stack.source, calc_aa_blur(_stack.shape.x));
    if (_stack.has_clip) {
	    write_color(_stack.source, calc_aa_blur(_stack.clip.x));        
    }
}

void fill() {
    fill_preserve();
    new_path();
}

void set_line_width(float w) {
    _stack.line_width = w;
}

void set_line_width_px(float w) {
    _stack.line_width = w*min_uniform_scale() * AAINV;
}

float get_gradient_eps() {
    return (1.0 / min_uniform_scale()) * AAINV;
}

vec2 stroke_shape() {
    return abs(_stack.shape) - _stack.line_width/_stack.scale;
}

void stroke_preserve() {
    float w = stroke_shape().x;
    write_color(_stack.source, calc_aa_blur(w));
}

void stroke() {
    stroke_preserve();
    new_path();
}

bool in_fill() {
    return (_stack.shape.y <= 0.0);
}

bool in_stroke() {
    float w = stroke_shape().y;
    return (w <= 0.0);
}

void set_source_rgba(vec4 c) {
    //c.rgb *= c.rgb;
    c *= c;
    if (_stack.source_blend == Multiply) {
        _stack.source *= c;
    } else if (_stack.source_blend == Alpha) {
    	float src_a = c.a;
    	float dst_a = _stack.premultiply?1.0:src_a;
	    _stack.source =
            vec4(_stack.source.rgb * (1.0 - src_a) + c.rgb * dst_a,
                 max(_stack.source.a, c.a));
    } else {
    	_stack.source = c;
    }
}

void set_source_depth(float depth) {
    _stack.source_z = depth;
}

void set_source_rgba(float r, float g, float b, float a) {
    set_source_rgba(vec4(r,g,b,a)); }

void set_source_rgb(vec3 c) {
    set_source_rgba(vec4(c,1.0));
}

void set_source_rgb(float r, float g, float b) { set_source_rgb(vec3(r,g,b)); }

void set_source(sampler2D image) {
    set_source_rgba(texture(image, _stack.position.xy));
}

void set_source_linear_gradient(vec4 color0, vec4 color1, vec2 p0, vec2 p1) {
    vec2 pa = _stack.position.xy - p0;
    vec2 ba = p1 - p0;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    set_source_rgba(mix(color0, color1, h));
}

void set_source_linear_gradient(vec3 color0, vec3 color1, vec2 p0, vec2 p1) {
    set_source_linear_gradient(vec4(color0, 1.0), vec4(color1, 1.0), p0, p1);
}

void set_source_radial_gradient(vec4 color0, vec4 color1, vec2 p, float r) {
    float h = clamp( length(_stack.position.xy - p) / r, 0.0, 1.0 );
    set_source_rgba(mix(color0, color1, h));
}

void set_source_radial_gradient(vec3 color0, vec3 color1, vec2 p, float r) {
    set_source_radial_gradient(vec4(color0, 1.0), vec4(color1, 1.0), p, r);
}

void set_source_blend_mode(int mode) {
    _stack.source_blend = mode;
}

vec2 length2(vec4 a) {
    return vec2(length(a.xy),length(a.zw));
}

vec2 dot2(vec4 a, vec2 b) {
    return vec2(dot(a.xy,b),dot(a.zw,b));
}

void letter(sampler2D font_texture_source, ivec2 l) {
  vec2 p = vec2(l);
  vec3 tx;
  vec2 ip;
  float d;
  int ic;
  ip = vec2(l);
  p += clamp(_stack.position.xy, 0.0, 1.0);
  ic = 0x21 + int (mod (16. + ip.x + 2. * ip.y, 94.));
  tx = texture (font_texture_source, mod ((vec2 (mod (float (ic), 16.),
     15. - floor (float (ic) / 16.)) + fract (p)) * (1. / 16.), 1.)).gba - 0.5;
  d = tx.b + 1. / 256.;
  add_field(d / min_uniform_scale());
}

void letter(sampler2D font_texture_source, int lx, int ly) {
    letter(font_texture_source, ivec2(lx,ly));
}

void rounded_rectangle(vec2 o, vec2 s, float r) {
    s = (s * 0.5);
    r = min(r, min(s.x, s.y));
    o += s;
    s -= r;
    vec4 d = abs(o.xyxy - _stack.position) - s.xyxy;
    vec4 dmin = min(d,0.0);
    vec4 dmax = max(d,0.0);
    vec2 df = max(dmin.xz, dmin.yw) + length2(dmax);
    add_field(df - r);
}

void rounded_rectangle(float ox, float oy, float sx, float sy, float r) {
    rounded_rectangle(vec2(ox,oy), vec2(sx,sy), r);
}

void rectangle(vec2 o, vec2 s) {
    rounded_rectangle(o, s, 0.0);
}

void rectangle(float ox, float oy, float sx, float sy) {
    rounded_rectangle(vec2(ox,oy), vec2(sx,sy), 0.0);
}

void grid(vec2 size) {
    vec4 f = abs(fract(_stack.position/size.xyxy+0.5)-0.5)*size.xyxy;
    add_field(vec2(min(f.x,f.y),min(f.z,f.w)));
}
void grid(float w, float h) {
    grid(vec2(w,h));
}
void grid(float s) {
    grid(vec2(s));
}
void rings(vec2 p, float r, float phase) {
    vec4 q = _stack.position - p.xyxy;
    vec2 f = abs(fract(vec2(length(q.xy),length(q.zw))/r-phase+0.5)-0.5)*r;
    add_field(f);
}

void circle(vec2 p, float r) {
    vec4 c = _stack.position - p.xyxy;
    add_field(vec2(length(c.xy),length(c.zw)) - r);
}
void circle(float x, float y, float r) { circle(vec2(x,y),r); }

void circle_px(vec2 p, float r) {
    circle(p, r/(0.5*ScreenH));
}
void circle_px(float x, float y, float r) {
    circle_px(vec2(x,y), r);
}

// from https://www.shadertoy.com/view/4sS3zz
float sdEllipse( vec2 p, in vec2 ab )
{
	p = abs( p ); if( p.x > p.y ){ p=p.yx; ab=ab.yx; }
	
	float l = ab.y*ab.y - ab.x*ab.x;
    if (l == 0.0) {
        return length(p) - ab.x;
    }
	
    float m = ab.x*p.x/l; 
	float n = ab.y*p.y/l; 
	float m2 = m*m;
	float n2 = n*n;
	
    float c = (m2 + n2 - 1.0)/3.0; 
	float c3 = c*c*c;

    float q = c3 + m2*n2*2.0;
    float d = c3 + m2*n2;
    float g = m + m*n2;

    float co;

    if( d<0.0 )
    {
        float p = acos(q/c3)/3.0;
        float s = cos(p);
        float t = sin(p)*sqrt(3.0);
        float rx = sqrt( -c*(s + t + 2.0) + m2 );
        float ry = sqrt( -c*(s - t + 2.0) + m2 );
        co = ( ry + sign(l)*rx + abs(g)/(rx*ry) - m)/2.0;
    }
    else
    {
        float h = 2.0*m*n*sqrt( d );
        float s = sign(q+h)*pow( abs(q+h), 1.0/3.0 );
        float u = sign(q-h)*pow( abs(q-h), 1.0/3.0 );
        float rx = -s - u - c*4.0 + 2.0*m2;
        float ry = (s - u)*sqrt(3.0);
        float rm = sqrt( rx*rx + ry*ry );
        float p = ry/sqrt(rm-rx);
        co = (p + 2.0*g/rm - m)/2.0;
    }

    float si = sqrt( 1.0 - co*co );
 
    vec2 r = vec2( ab.x*co, ab.y*si );
	
    return length(r - p ) * sign(p.y-r.y);
}

void ellipse(vec2 p, vec2 r) {
    vec4 c = _stack.position - p.xyxy;
    add_field(vec2(sdEllipse(c.xy, r), sdEllipse(c.zw, r)));
}

void ellipse(float x, float y, float rw, float rh) {
    ellipse(vec2(x,y), vec2(rw, rh));
}

void move_to(vec2 p) {
    _stack.start_pt = p;
    _stack.last_pt = p;
}

void move_to(float x, float y) { move_to(vec2(x,y)); }

// stroke only
void line_to(vec2 p) {
    vec4 pa = _stack.position - _stack.last_pt.xyxy;
    vec2 ba = p - _stack.last_pt;
    vec2 h = clamp(dot2(pa, ba)/dot(ba,ba), 0.0, 1.0);
    vec2 s = sign(pa.xz*ba.y-pa.yw*ba.x);
    vec2 d = length2(pa - ba.xyxy*h.xxyy);
    add_field(d);
    add_clip(d * s);
    _stack.last_pt = p;
}

void line_to(float x, float y) { line_to(vec2(x,y)); }

void close_path() {
    line_to(_stack.start_pt);
}

// from https://www.shadertoy.com/view/ltXSDB

// Test if point p crosses line (a, b), returns sign of result
float test_cross(vec2 a, vec2 b, vec2 p) {
    return sign((b.y-a.y) * (p.x-a.x) - (b.x-a.x) * (p.y-a.y));
}

// Determine which side we're on (using barycentric parameterization)
float bezier_sign(vec2 A, vec2 B, vec2 C, vec2 p) {
    vec2 a = C - A, b = B - A, c = p - A;
    vec2 bary = vec2(c.x*b.y-b.x*c.y,a.x*c.y-c.x*a.y) / (a.x*b.y-b.x*a.y);
    vec2 d = vec2(bary.y * 0.5, 0.0) + 1.0 - bary.x - bary.y;
    return mix(sign(d.x * d.x - d.y), mix(-1.0, 1.0,
        step(test_cross(A, B, p) * test_cross(B, C, p), 0.0)),
        step((d.x - d.y), 0.0)) * test_cross(A, C, B);
}

// Solve cubic equation for roots
vec3 bezier_solve(float a, float b, float c) {
    float p = b - a*a / 3.0, p3 = p*p*p;
    float q = a * (2.0*a*a - 9.0*b) / 27.0 + c;
    float d = q*q + 4.0*p3 / 27.0;
    float offset = -a / 3.0;
    if(d >= 0.0) {
        float z = sqrt(d);
        vec2 x = (vec2(z, -z) - q) / 2.0;
        vec2 uv = sign(x)*pow(abs(x), vec2(1.0/3.0));
        return vec3(offset + uv.x + uv.y);
    }
    float v = acos(-sqrt(-27.0 / p3) * q / 2.0) / 3.0;
    float m = cos(v), n = sin(v)*1.732050808;
    return vec3(m + m, -n - m, n - m) * sqrt(-p / 3.0) + offset;
}

// Find the signed distance from a point to a quadratic bezier curve
float bezier(vec2 A, vec2 B, vec2 C, vec2 p)
{
    B = mix(B + vec2(1e-4), B, abs(sign(B * 2.0 - A - C)));
    vec2 a = B - A, b = A - B * 2.0 + C, c = a * 2.0, d = A - p;
    vec3 k = vec3(3.*dot(a,b),2.*dot(a,a)+dot(d,b),dot(d,a)) / dot(b,b);
    vec3 t = clamp(bezier_solve(k.x, k.y, k.z), 0.0, 1.0);
    vec2 pos = A + (c + b*t.x)*t.x;
    float dis = length(pos - p);
    pos = A + (c + b*t.y)*t.y;
    dis = min(dis, length(pos - p));
    pos = A + (c + b*t.z)*t.z;
    dis = min(dis, length(pos - p));
    return dis * bezier_sign(A, B, C, p);
}

void curve_to(vec2 b1, vec2 b2) {
    vec2 shape = vec2(
        bezier(_stack.last_pt, b1, b2, _stack.position.xy),
        bezier(_stack.last_pt, b1, b2, _stack.position.zw));
    add_field(abs(shape));
    add_clip(shape);
	_stack.last_pt = b2;
}

void curve_to(float b1x, float b1y, float b2x, float b2y) {
    curve_to(vec2(b1x,b1y),vec2(b2x,b2y));
}

void graph(vec2 p, float f_x, float df_x) {
    add_field(abs(f_x - p.y) / sqrt(1.0 + (df_x * df_x)));
}

void graph(vec2 p, float f_x, vec2 df_x) {
    add_field(f_x / length(df_x));
}

// random number generator library (https://www.shadertoy.com/view/ssGXDd)
// by Leonard Ritter (@leonard_ritter)

// based on https://www.shadertoy.com/view/MdcfDj
// license: https://unlicense.org/

// comment out for faster but lower quality hashing
#define RNGL_HIGH_QUALITY

struct Random { uint s0; uint s1; };

// constructors; note that constructors are wilfully unique,
// i.e. calling a different constructor with the same arguments will not
// necessarily produce the same state.
uint uhash(uint a, uint b);
Random seed(uint s) { return Random(s, uhash(0x1ef7c663u, s)); }
Random seed(uvec2 s) { return Random(s.y, uhash(s.x, s.y)); }
Random seed(Random a, uint b) { return Random(b, uhash(a.s1, b)); }
Random seed(Random a, uvec2 b) { return seed(a, uhash(b.x, b.y)); }
Random seed(Random a, uvec3 b) { return seed(a, uhash(uhash(b.x, b.y), b.z)); }
Random seed(Random a, uvec4 b) { return seed(a, uhash(uhash(b.x, b.y), uhash(b.z, b.w))); }
Random seed(uvec3 s) { return seed(seed(s.xy), s.z); }
Random seed(uvec4 s) { return seed(seed(s.xy), s.zw); }
Random seed(int s) { return seed(uint(s)); }
Random seed(ivec2 s) { return seed(uvec2(s)); }
Random seed(ivec3 s) { return seed(uvec3(s)); }
Random seed(ivec4 s) { return seed(uvec4(s)); }
Random seed(Random a, int b) { return seed(a, uint(b)); }
Random seed(Random a, ivec2 b) { return seed(a, uvec2(b)); }
Random seed(Random a, ivec3 b) { return seed(a, uvec3(b)); }
Random seed(Random a, ivec4 b) { return seed(a, uvec4(b)); }
Random seed(float s) { return seed(floatBitsToUint(s)); }
Random seed(vec2 s) { return seed(floatBitsToUint(s)); }
Random seed(vec3 s) { return seed(floatBitsToUint(s)); }
Random seed(vec4 s) { return seed(floatBitsToUint(s)); }
Random seed(Random a, float b) { return seed(a, floatBitsToUint(b)); }
Random seed(Random a, vec2 b) { return seed(a, floatBitsToUint(b)); }
Random seed(Random a, vec3 b) { return seed(a, floatBitsToUint(b)); }
Random seed(Random a, vec4 b) { return seed(a, floatBitsToUint(b)); }

// fundamental functions to fetch a new random number
// the last static call to the rng will be optimized out
uint urandom(inout Random rng) {
    uint last = rng.s1;
    uint next = uhash(rng.s0, rng.s1);
    rng.s0 = rng.s1; rng.s1 = next;
    return last;
}
uvec2 urandom2(inout Random rng) { return uvec2(urandom(rng),urandom(rng)); }
uvec3 urandom3(inout Random rng) { return uvec3(urandom2(rng),urandom(rng)); }
uvec4 urandom4(inout Random rng) { return uvec4(urandom2(rng),urandom2(rng)); }
int irandom(inout Random rng) { return int(urandom(rng)); }
ivec2 irandom2(inout Random rng) { return ivec2(urandom2(rng)); }
ivec3 irandom3(inout Random rng) { return ivec3(urandom3(rng)); }
ivec4 irandom4(inout Random rng) { return ivec4(urandom4(rng)); }

float unorm(uint n);
float random(inout Random rng) { return unorm(urandom(rng)); }
vec2 random2(inout Random rng) { return vec2(random(rng),random(rng)); }
vec3 random3(inout Random rng) { return vec3(random2(rng),random(rng)); }
vec4 random4(inout Random rng) { return vec4(random2(rng),random2(rng)); }

// ranged random value < maximum value
int range(inout Random rng, int mn, int mx) { return mn + (irandom(rng) % (mx - mn)); }
ivec2 range(inout Random rng, ivec2 mn, ivec2 mx) { return mn + (irandom2(rng) % (mx - mn)); }
ivec3 range(inout Random rng, ivec3 mn, ivec3 mx) { return mn + (irandom3(rng) % (mx - mn)); }
ivec4 range(inout Random rng, ivec4 mn, ivec4 mx) { return mn + (irandom4(rng) % (mx - mn)); }
uint range(inout Random rng, uint mn, uint mx) { return mn + (urandom(rng) % (mx - mn)); }
uvec2 range(inout Random rng, uvec2 mn, uvec2 mx) { return mn + (urandom2(rng) % (mx - mn)); }
uvec3 range(inout Random rng, uvec3 mn, uvec3 mx) { return mn + (urandom3(rng) % (mx - mn)); }
uvec4 range(inout Random rng, uvec4 mn, uvec4 mx) { return mn + (urandom4(rng) % (mx - mn)); }
float range(inout Random rng, float mn, float mx) { float x=random(rng); return mn*(1.0-x) + mx*x; }
vec2 range(inout Random rng, vec2 mn, vec2 mx) { vec2 x=random2(rng); return mn*(1.0-x) + mx*x; }
vec3 range(inout Random rng, vec3 mn, vec3 mx) { vec3 x=random3(rng); return mn*(1.0-x) + mx*x; }
vec4 range(inout Random rng, vec4 mn, vec4 mx) { vec4 x=random4(rng); return mn*(1.0-x) + mx*x; }

// marshalling functions for storage in image buffer and rng replay
vec2 marshal(Random a) { return uintBitsToFloat(uvec2(a.s0,a.s1)); }
Random unmarshal(vec2 a) { uvec2 u = floatBitsToUint(a); return Random(u.x, u.y); }

//// specific distributions

// normal/gaussian distribution
// see https://en.wikipedia.org/wiki/Normal_distribution
float gaussian(inout Random rng, float mu, float sigma) {
    vec2 q = random2(rng);
    float g2rad = sqrt(-2.0 * (log(1.0 - q.y)));
    float z = cos(q.x*6.28318530718) * g2rad;
    return mu + z * sigma;
}

// triangular distribution
// see https://en.wikipedia.org/wiki/Triangular_distribution
// mode is a mixing argument in the range 0..1
float triangular(inout Random rng, float low, float high, float mode) {
    float u = random(rng);
    if (u > mode) {
        return high + (low - high) * (sqrt ((1.0 - u) * (1.0 - mode)));
    } else {
        return low + (high - low) * (sqrt (u * mode));
    }
}
float triangular(inout Random rng, float low, float high) { return triangular(rng, low, high, 0.5); }

// after https://www.shadertoy.com/view/4t2SDh
// triangle distribution in the range -0.5 .. 1.5
float triangle(inout Random rng) {
    float u = random(rng);
    float o = u * 2.0 - 1.0;
    return max(-1.0, o / sqrt(abs(o))) - sign(o) + 0.5;
}

//// geometric & euclidean distributions

// uniformly random point on the edge of a unit circle
// produces 2d normal vector as well
vec2 uniform_circle_edge (inout Random rng) {
    float u = random(rng);
    float phi = 6.28318530718*u;
    return vec2(cos(phi),sin(phi));
}

// uniformly random point in unit circle
vec2 uniform_circle_area (inout Random rng) {
    return uniform_circle_edge(rng)*sqrt(random(rng));
}

// gaussian random point in unit circle
vec2 gaussian_circle_area (inout Random rng, float k) {
    return uniform_circle_edge(rng)*sqrt(-k*log(random(rng)));
}
vec2 gaussian_circle_area (inout Random rng) { return gaussian_circle_area(rng, 0.5); }

// barycentric coordinates of a uniformly random point within a triangle
vec3 uniform_triangle_area (inout Random rng) {
    vec2 u = random2(rng);
    if (u.x + u.y > 1.0) {
        u = 1.0 - u;
    }
    return vec3(u.x, u.y, 1.0-u.x-u.y);
}

// uniformly random on the surface of a sphere
// produces normal vectors as well
vec3 uniform_sphere_area (inout Random rng) {
    vec2 u = random2(rng);
    float phi = 6.28318530718*u.x;
    float rho_c = 2.0 * u.y - 1.0;
    float rho_s = sqrt(1.0 - (rho_c * rho_c));
    return vec3(rho_s * cos(phi), rho_s * sin(phi), rho_c);
}

// uniformly random within the volume of a sphere
vec3 uniform_sphere_volume (inout Random rng) {
    return uniform_sphere_area(rng) * pow(random(rng), 1.0/3.0);
}

// barycentric coordinates of a uniformly random point within a 3-simplex
// based on "Generating Random Points in a Tetrahedron" by Rocchini et al
vec4 uniform_simplex_volume (inout Random rng) {
    vec3 u = random3(rng);
    if(u.x + u.y > 1.0) {
        u = 1.0 - u;
    }
    if(u.y + u.z > 1.0) {
        u.yz = vec2(1.0 - u.z, 1.0 - u.x - u.y);
    } else if(u.x + u.y + u.z > 1.0) {
        u.xz = vec2(1.0 - u.y - u.z, u.x + u.y + u.z - 1.0);
    }
    return vec4(1.0 - u.x - u.y - u.z, u); 
}

// for differential evolution, in addition to index K, we need to draw three more
// indices a,b,c for a list of N items, without any collisions between k,a,b,c.
// this is the O(1) hardcoded fisher-yates shuffle for this situation.
ivec3 sample_k_3(inout Random rng, int N, int K) {
    ivec3 t = range(rng, ivec3(1,2,3), ivec3(N));
    int db = (t.y == t.x)?1:t.y;
    int dc = (t.z == t.y)?((t.x != 2)?2:1):((t.z == t.x)?1:t.z);
    return (K + ivec3(t.x, db, dc)) % N;
}

/////////////////////////////////////////////////////////////////////////

// if it turns out that you are unhappy with the distribution or performance
// it is possible to exchange this function without changing the interface
uint uhash(uint a, uint b) { 
    uint x = ((a * 1597334673U) ^ (b * 3812015801U));
#ifdef RNGL_HIGH_QUALITY
    // from https://nullprogram.com/blog/2018/07/31/
    x = x ^ (x >> 16u);
    x = x * 0x7feb352du;
    x = x ^ (x >> 15u);
    x = x * 0x846ca68bu;
    x = x ^ (x >> 16u);
#else
    x = x * 0x7feb352du;
    x = x ^ (x >> 15u);
    x = x * 0x846ca68bu;
#endif
    return x;
}
float unorm(uint n) { return float(n) * (1.0 / float(0xffffffffU)); }

/////////////////////////////////////////////////////////////////////////

float gain(float x, float P) {
    if (x > 0.5)
        return 1.0 - 0.5*pow(2.0-2.0*x, P);
    else
        return 0.5*pow(2.0*x, P);
}

float target_func(float x) {
#if 0
    Random rng = seed(4);
    float y = random(rng);
    for (int i = 1; i < 16; ++i) {
        y = x*y + random(rng);
    }
    return y * 0.5 - 0.5;
#elif 0
    return sin(x*pi)*0.7;
#elif 0
    return sqrt(x*0.5+0.5) - 0.5;
#elif 0
    return 4.0*x*x-0.5;
#elif 0
    return tanh(x*10.0) * 0.5;
#elif 0
    return tanh(1.0 / (x*10.0)) * 0.5;
#elif 0
    return smoothstep(-0.25, 0.25, x)-0.5;
#elif 1
    return fract(x*1.0 + 0.5) - 0.5 + sin(x*pi)*0.1;
#elif 0
    return 1.0 / (x + 1.5) - 1.0;
#elif 1
    return abs(fract(x) - 0.5);
#elif 1
    return min(fract(x), 0.5);
#elif 1
    //return step(0.0, x)-0.9 + x*x;
    return step(0.5, fract(x*0.5)) - 0.5;
#else
    return smoothstep(-0.1, 0.1, x)-0.5;
#endif
}

#ifdef FIT_POINTS
vec2 get_point(int i, int s) {
    Random rng = seed(seed(i),0);
    vec2 p = random2(rng);
    //p.x = gaussian(rng, 0.5, 0.5);
    p.x = float(i) / float(FIT_POINTS-1);
    #if 1
    //p.x = gain(p.x, 1.0/2.0); // distribute more samples at the border
    //p.x = p.x*p.x;
    p = p*2.0 - 1.0;
    p.y = p.y * abs(p.x) * 0.0 + target_func(p.x);
    #else
    p = p*2.0 - 1.0;
    #endif
    return p;
}
#endif

float pow2(float x) { return x*x; }

struct ModelSetup {
    int input_count;
    int layer_count;
    int node_count;
    int output_count;
};

//Model, ModelIO, model_setup, ModelSize, 1, 5, 2, 1

#define NUM_MODEL_WEIGHTS(M) (M.node_count*(M.node_count*(M.layer_count - 1) + M.layer_count + M.input_count + M.output_count) + M.output_count)
#define DEFINE_MODEL(NAME, IONAME, CFGNAME, SIZENAME, INPUTS, LAYERS, NODES, OUTPUTS) \
    const ModelSetup CFGNAME = ModelSetup(INPUTS, LAYERS, NODES, OUTPUTS); \
    const int SIZENAME = NUM_MODEL_WEIGHTS(CFGNAME); \
    struct NAME { \
        /* float c[SIZENAME]; */ \
        float c[128]; \
    }; \
    struct IONAME { \
        vec2 i[INPUTS]; \
        vec2 o[OUTPUTS]; \
    };

// for layer 0, node is in the range 0..NUM_NODES-1, edge is 0..NUM_INPUTS
// for layer 1..NUM_LAYERS-1, node is in the range 0..NUM_NODES-1, edge is 0..NUM_NODES
// for layer NUM_LAYERS, node is in the range 0..NUM_OUTPUTS-1, edge is 0..NUM_NODES
// edge NUM_NODES is always the bias
int weight_index(const ModelSetup setup, int layer, int node, int edge) {
    int index = 0;
    if (layer > 0) {
        index = setup.node_count * ((setup.input_count + 1) + (setup.node_count + 1) * (layer - 1)) + node * (setup.node_count + 1) + edge;
    } else {
        index = node * (setup.input_count + 1) + edge;
    }
    return index;
}
#if USE_TRI
#define ACTIVATE ad_tri
#else
#define ACTIVATE ad_sin
#endif
#define N(L, K, J) vec2(c.c[weight_index(setup, L, K, J)], v.c[weight_index(setup, L, K, J)])
#define DEFINE_MODEL_EVAL_GRAD(NAME, MODELNAME, IONAME, CFGNAME) \
void NAME(MODELNAME c, MODELNAME v, inout IONAME io) { \
    const ModelSetup setup = CFGNAME; \
    /* first hidden layer */ \
    /* vec2 tmp0[CFGNAME.node_count];*/ \
    vec2 tmp0[128]; \
    for (int k = 0; k < CFGNAME.node_count; ++k) { \
        tmp0[k] = N(0, k, CFGNAME.input_count); \
        for (int j = 0; j < CFGNAME.input_count; ++j) { \
            tmp0[k] = ad_add(tmp0[k], ad_mul(N(0, k, j), io.i[j])); \
        } \
        tmp0[k] = ACTIVATE(tmp0[k]); \
    } \
    /* rest of hidden layers */ \
    /* vec2 tmp1[CFGNAME.node_count];*/ \
    vec2 tmp1[128]; \
    for (int l = 1; l < CFGNAME.layer_count; ++l) { \
        for (int k = 0; k < CFGNAME.node_count; ++k) { \
            tmp1[k] = N(l, k, CFGNAME.node_count); \
            for (int j = 0; j < CFGNAME.node_count; ++j) { \
                tmp1[k] = ad_add(tmp1[k], ad_mul(N(l, k, j), tmp0[j])); \
            } \
            tmp1[k] = ACTIVATE(tmp1[k]); \
        } \
        tmp0 = tmp1; \
    } \
    /* assemble output */ \
    for (int k = 0; k < CFGNAME.output_count; ++k) { \
        io.o[k] = N(CFGNAME.layer_count, k, CFGNAME.node_count); \
        for (int j = 0; j < CFGNAME.node_count; ++j) { \
            io.o[k] = ad_add(io.o[k], ad_mul(N(CFGNAME.layer_count, k, j), tmp0[j])); \
        } \
    } \
}

#if USE_TRI
#define DECLARE_INIT_CONSTANTS() \
    const float W_I = 15.0; \
    const float W_L = 1.0; \
    const float W_B = 1.0;
#else
#define DECLARE_INIT_CONSTANTS() \
    const float w0 = 30.0; \
    const float W_I = sqrt(6.0 / float(setup.input_count)) * w0; \
    const float W_L = sqrt(6.0 / (w0*w0*float(setup.node_count))) * w0; \
    const float W_B = 3.14159265359;
#endif

#define INITN(L, K, J) c.c[weight_index(setup, L, K, J)]
#define DEFINE_MODEL_INIT(NAME, MODELNAME, CFGNAME) \
void NAME (inout MODELNAME c, inout Random rng) { \
    const ModelSetup setup = CFGNAME; \
    DECLARE_INIT_CONSTANTS(); \
    /* first hidden layer */ \
    for (int k = 0; k < CFGNAME.node_count; ++k) { \
        for (int j = 0; j < CFGNAME.input_count; ++j) { \
            INITN(0, k, j) = (random(rng)*2.0-1.0)*W_I; \
        } \
        /* init bias */ \
        INITN(0, k, CFGNAME.input_count) = (random(rng)*2.0-1.0)*W_B; \
    } \
    /* rest of hidden layers */ \
    for (int l = 1; l < CFGNAME.layer_count; ++l) { \
        for (int k = 0; k < CFGNAME.node_count; ++k) { \
            for (int j = 0; j < CFGNAME.node_count; ++j) { \
                INITN(l, k, j) = (random(rng)*2.0-1.0)*W_L; \
            } \
            /* init bias */ \
            INITN(l, k, CFGNAME.node_count) = (random(rng)*2.0-1.0)*W_B; \
        } \
    } \
    /* output weights */ \
    for (int k = 0; k < CFGNAME.output_count; ++k) { \
        for (int j = 0; j < CFGNAME.node_count; ++j) { \
            INITN(CFGNAME.layer_count, k, j) = random(rng)*2.0-1.0; \
        } \
        /* init bias */ \
        INITN(CFGNAME.layer_count, k, CFGNAME.node_count) = random(rng)*2.0-1.0; \
    } \
}

DEFINE_MODEL(Model, ModelIO, model_setup, ModelSize, 1, 5, 2, 1)
DEFINE_MODEL_EVAL_GRAD(model_eval, Model, ModelIO, model_setup)
DEFINE_MODEL_INIT(model_init, Model, model_setup)
