// FlappyBird by Ben Raziel. Feb 2014

// Based on the "Super Mario Bros" shader by HLorenzi
// https://www.shadertoy.com/view/Msj3zD

// Helper functions for drawing sprites
#define RGB(r,g,b) vec4(float(r)/255.0,float(g)/255.0,float(b)/255.0,1.0)
#define SPRROW(x,a,b,c,d,e,f,g,h, i,j,k,l,m,n,o,p) (x <= 7 ? SPRROW_H(a,b,c,d,e,f,g,h) : SPRROW_H(i,j,k,l,m,n,o,p))
#define SPRROW_H(a,b,c,d,e,f,g,h) (a+4.0*(b+4.0*(c+4.0*(d+4.0*(e+4.0*(f+4.0*(g+4.0*(h))))))))
#define SECROW(x,a,b,c,d,e,f,g,h) (x <= 3 ? SECROW_H(a,b,c,d) : SECROW_H(e,f,g,h))
#define SECROW_H(a,b,c,d) (a+8.0*(b+8.0*(c+8.0*(d))))
#define SELECT(x,i) mod(floor(i/pow(4.0,float(x))),4.0)
#define SELECTSEC(x,i) mod(floor(i/pow(8.0,float(x))),8.0)

// drawing consts
const float PIPE_WIDTH = 26.0; // px
const float PIPE_BOTTOM = 39.0; // px
const float PIPE_HOLE_HEIGHT = 12.0; // px
const vec4 PIPE_OUTLINE_COLOR = RGB(84, 56, 71);

// gameplay consts
const float HORZ_PIPE_DISTANCE = 100.0; // px;
const float VERT_PIPE_DISTANCE = 55.0; // px;
const float PIPE_MIN = 20.0;
const float PIPE_MAX = 70.0;	
const float PIPE_PER_CYCLE = 8.0;	

vec4 fragColor;

void drawHorzRect(float yCoord, float minY, float maxY, vec4 color)
{
	if ((yCoord >= minY) && (yCoord < maxY)) {
		fragColor = color;		
	}
}

void drawLowBush(int x, int y)
{
	if (y < 0 || y > 3 || x < 0 || x > 15) {
		return;
	}
	
	float col = 0.0; // 0 = transparent

	if (y ==  3) col = SPRROW(x,0.,0.,0.,0.,0.,0.,1.,1., 1.,1.,0.,0.,0.,0.,0.,0.);
	if (y ==  2) col = SPRROW(x,0.,0.,0.,0.,1.,1.,2.,2., 2.,2.,1.,1.,0.,0.,0.,0.);
	if (y ==  1) col = SPRROW(x,0.,0.,0.,1.,1.,2.,2.,2., 2.,2.,2.,1.,1.,0.,0.,0.);
	if (y ==  0) col = SPRROW(x,0.,0.,1.,2.,2.,2.,2.,2., 2.,2.,2.,2.,2.,1.,0.,0.);
	
	col = SELECT(mod(float(x),8.0),col);
	if (col == 1.0) {
		fragColor = RGB(87,201,111);
	}
	else if (col == 2.0) {
		fragColor = RGB(100,224,117);
	}
}

void drawHighBush(int x, int y)
{
	if (y < 0 || y > 6 || x < 0 || x > 15) {
		return;
	}
	
	float col = 0.0; // 0 = transparent

	if (y ==  6) col = SPRROW(x,0.,0.,0.,0.,0.,0.,1.,1., 1.,1.,0.,0.,0.,0.,0.,0.);
	if (y ==  5) col = SPRROW(x,0.,0.,0.,0.,1.,1.,2.,2., 2.,2.,1.,1.,0.,0.,0.,0.);
	if (y ==  4) col = SPRROW(x,0.,0.,1.,1.,2.,2.,2.,2., 2.,2.,2.,2.,1.,1.,0.,0.);
	if (y ==  3) col = SPRROW(x,0.,1.,2.,2.,2.,2.,2.,2., 2.,2.,2.,2.,2.,2.,1.,0.);
	if (y ==  2) col = SPRROW(x,0.,1.,2.,2.,2.,2.,2.,2., 2.,2.,2.,2.,2.,2.,1.,0.);
	if (y ==  1) col = SPRROW(x,1.,2.,2.,2.,2.,2.,2.,2., 2.,2.,2.,2.,2.,2.,2.,1.);
	if (y ==  0) col = SPRROW(x,1.,2.,2.,2.,2.,2.,2.,2., 2.,2.,2.,2.,2.,2.,2.,1.);
		
	col = SELECT(mod(float(x),8.0),col);
	if (col == 1.0) {
		fragColor = RGB(87,201,111);
	}
	else if (col == 2.0) {
		fragColor = RGB(100,224,117);
	}
}

void drawCloud(int x, int y)
{
	if (y < 0 || y > 6 || x < 0 || x > 15) {
		return;
	}
	
	float col = 0.0; // 0 = transparent

	if (y ==  6) col = SPRROW(x,0.,0.,0.,0.,0.,0.,1.,1., 1.,1.,0.,0.,0.,0.,0.,0.);
	if (y ==  5) col = SPRROW(x,0.,0.,0.,0.,1.,1.,2.,2., 2.,2.,1.,1.,0.,0.,0.,0.);
	if (y ==  4) col = SPRROW(x,0.,0.,1.,1.,2.,2.,2.,2., 2.,2.,2.,2.,1.,1.,0.,0.);
	if (y ==  3) col = SPRROW(x,0.,1.,2.,2.,2.,2.,2.,2., 2.,2.,2.,2.,2.,2.,1.,0.);
	if (y ==  2) col = SPRROW(x,0.,1.,2.,2.,2.,2.,2.,2., 2.,2.,2.,2.,2.,2.,1.,0.);
	if (y ==  1) col = SPRROW(x,1.,2.,2.,2.,2.,2.,2.,2., 2.,2.,2.,2.,2.,2.,2.,1.);
	if (y ==  0) col = SPRROW(x,1.,2.,2.,2.,2.,2.,2.,2., 2.,2.,2.,2.,2.,2.,2.,1.);
		
	col = SELECT(mod(float(x),8.0),col);
	if (col == 1.0) {
		fragColor = RGB(218,246,216);
	}
	else if (col == 2.0) {
		fragColor = RGB(233,251,218);
	}
}

void drawBirdF0(int x, int y)
{
	if (y < 0 || y > 11 || x < 0 || x > 15) {
		return;
	}
	
	// pass 0 - draw black, white and yellow
	float col = 0.0; // 0 = transparent
	if (y == 11) col = SPRROW(x,0.,0.,0.,0.,0.,0.,1.,1., 1.,1.,1.,1.,0.,0.,0.,0.);
	if (y == 10) col = SPRROW(x,0.,0.,0.,0.,1.,1.,3.,3., 3.,1.,2.,2.,1.,0.,0.,0.);
	if (y ==  9) col = SPRROW(x,0.,0.,0.,1.,3.,3.,3.,3., 1.,2.,2.,2.,2.,1.,0.,0.);
	if (y ==  8) col = SPRROW(x,0.,0.,1.,3.,3.,3.,3.,3., 1.,2.,2.,2.,1.,2.,1.,0.);
	if (y ==  7) col = SPRROW(x,0.,1.,3.,3.,3.,3.,3.,3., 1.,2.,2.,2.,1.,2.,1.,0.);
	if (y ==  6) col = SPRROW(x,0.,1.,3.,3.,3.,3.,3.,3., 3.,1.,2.,2.,2.,2.,1.,0.);
	if (y ==  5) col = SPRROW(x,0.,1.,1.,1.,1.,1.,3.,3., 3.,3.,1.,1.,1.,1.,1.,1.);
	if (y ==  4) col = SPRROW(x,1.,2.,2.,2.,2.,2.,1.,3., 3.,1.,2.,2.,2.,2.,2.,1.);
	if (y ==  3) col = SPRROW(x,1.,2.,2.,2.,2.,1.,3.,3., 1.,2.,1.,1.,1.,1.,1.,1.);
	if (y ==  2) col = SPRROW(x,1.,2.,2.,2.,1.,3.,3.,3., 3.,1.,2.,2.,2.,2.,1.,0.);
	if (y ==  1) col = SPRROW(x,0.,1.,1.,1.,1.,3.,3.,3., 3.,3.,1.,1.,1.,1.,1.,0.);
	if (y ==  0) col = SPRROW(x,0.,0.,0.,0.,0.,1.,1.,1., 1.,1.,0.,0.,0.,0.,0.,0.);
		
	col = SELECT(mod(float(x),8.0),col);
	if (col == 1.0) {
		fragColor = RGB(82,56,70); // outline color (black)
	}
	else if (col == 2.0) {
		fragColor = RGB(250,250,250); // eye color (white)
	}
	else if (col == 3.0) {
		fragColor = RGB(247, 182, 67); // normal yellow color
	}
	
	// pass 1 - draw red, light yellow and dark yellow
	col = 0.0; // 0 = transparent
	if (y == 11) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y == 10) col = SPRROW(x,0.,0.,0.,0.,0.,0.,3.,3., 3.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  9) col = SPRROW(x,0.,0.,0.,0.,3.,3.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  8) col = SPRROW(x,0.,0.,0.,3.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  7) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  6) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  5) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  4) col = SPRROW(x,0.,3.,0.,0.,0.,3.,0.,0., 0.,0.,1.,1.,1.,1.,1.,0.);
	if (y ==  3) col = SPRROW(x,0.,0.,0.,0.,0.,0.,2.,2., 0.,1.,0.,0.,0.,0.,0.,0.);
	if (y ==  2) col = SPRROW(x,0.,0.,0.,3.,0.,2.,2.,2., 2.,0.,1.,1.,1.,1.,0.,0.);
	if (y ==  1) col = SPRROW(x,0.,0.,0.,0.,0.,2.,2.,2., 2.,2.,0.,0.,0.,0.,0.,0.);
	if (y ==  0) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);	
	
	col = SELECT(mod(float(x),8.0),col);
	if (col == 1.0) {
		fragColor = RGB(249, 58, 28); // mouth color (red)	
	}
	else if (col == 2.0) {
		fragColor = RGB(222, 128, 55); // brown
	}
	else if (col == 3.0) {
		fragColor = RGB(249, 214, 145); // light yellow			
	}		
}

void drawBirdF1(int x, int y)
{
	if (y < 0 || y > 11 || x < 0 || x > 15) {
		return;
	}
	
	// pass 0 - draw black, white and yellow
	float col = 0.0; // 0 = transparent
	if (y == 11) col = SPRROW(x,0.,0.,0.,0.,0.,0.,1.,1., 1.,1.,1.,1.,0.,0.,0.,0.);
	if (y == 10) col = SPRROW(x,0.,0.,0.,0.,1.,1.,3.,3., 3.,1.,2.,2.,1.,0.,0.,0.);
	if (y ==  9) col = SPRROW(x,0.,0.,0.,1.,3.,3.,3.,3., 1.,2.,2.,2.,2.,1.,0.,0.);
	if (y ==  8) col = SPRROW(x,0.,0.,1.,3.,3.,3.,3.,3., 1.,2.,2.,2.,1.,2.,1.,0.);
	if (y ==  7) col = SPRROW(x,0.,1.,3.,3.,3.,3.,3.,3., 1.,2.,2.,2.,1.,2.,1.,0.);
	if (y ==  6) col = SPRROW(x,0.,1.,1.,1.,1.,1.,3.,3., 3.,1.,2.,2.,2.,2.,1.,0.);
	if (y ==  5) col = SPRROW(x,1.,2.,2.,2.,2.,2.,1.,3., 3.,3.,1.,1.,1.,1.,1.,1.);
	if (y ==  4) col = SPRROW(x,1.,2.,2.,2.,2.,2.,1.,3., 3.,1.,2.,2.,2.,2.,2.,1.);
	if (y ==  3) col = SPRROW(x,0.,1.,1.,1.,1.,1.,3.,3., 1.,2.,1.,1.,1.,1.,1.,1.);
	if (y ==  2) col = SPRROW(x,0.,0.,1.,3.,3.,3.,3.,3., 3.,1.,2.,2.,2.,2.,1.,0.);
	if (y ==  1) col = SPRROW(x,0.,0.,0.,1.,1.,3.,3.,3., 3.,3.,1.,1.,1.,1.,1.,0.);
	if (y ==  0) col = SPRROW(x,0.,0.,0.,0.,0.,1.,1.,1., 1.,1.,0.,0.,0.,0.,0.,0.);
		
	col = SELECT(mod(float(x),8.0),col);
	if (col == 1.0) {
		fragColor = RGB(82,56,70); // outline color (black)
	}
	else if (col == 2.0) {
		fragColor = RGB(250,250,250); // eye color (white)
	}
	else if (col == 3.0) {
		fragColor = RGB(247, 182, 67); // normal yellow color
	}
	
	// pass 1 - draw red, light yellow and dark yellow
	col = 0.0; // 0 = transparent
	if (y == 11) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y == 10) col = SPRROW(x,0.,0.,0.,0.,0.,0.,3.,3., 3.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  9) col = SPRROW(x,0.,0.,0.,0.,3.,3.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  8) col = SPRROW(x,0.,0.,0.,3.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  7) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  6) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  5) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  4) col = SPRROW(x,0.,3.,0.,0.,0.,3.,0.,0., 0.,0.,1.,1.,1.,1.,1.,0.);
	if (y ==  3) col = SPRROW(x,0.,0.,0.,0.,0.,0.,2.,2., 0.,1.,0.,0.,0.,0.,0.,0.);
	if (y ==  2) col = SPRROW(x,0.,0.,0.,2.,2.,2.,2.,2., 2.,0.,1.,1.,1.,1.,0.,0.);
	if (y ==  1) col = SPRROW(x,0.,0.,0.,0.,0.,2.,2.,2., 2.,2.,0.,0.,0.,0.,0.,0.);
	if (y ==  0) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);	
	
	col = SELECT(mod(float(x),8.0),col);
	if (col == 1.0) {
		fragColor = RGB(249, 58, 28); // mouth color (red)	
	}
	else if (col == 2.0) {
		fragColor = RGB(222, 128, 55); // brown
	}
	else if (col == 3.0) {
		fragColor = RGB(249, 214, 145); // light yellow			
	}		
}

void drawBirdF2(int x, int y)
{
	if (y < 0 || y > 11 || x < 0 || x > 15) {
		return;
	}
	
	// pass 0 - draw black, white and yellow
	float col = 0.0; // 0 = transparent
	if (y == 11) col = SPRROW(x,0.,0.,0.,0.,0.,0.,1.,1., 1.,1.,1.,1.,0.,0.,0.,0.);
	if (y == 10) col = SPRROW(x,0.,0.,0.,0.,1.,1.,3.,3., 3.,1.,2.,2.,1.,0.,0.,0.);
	if (y ==  9) col = SPRROW(x,0.,0.,0.,1.,3.,3.,3.,3., 1.,2.,2.,2.,2.,1.,0.,0.);
	if (y ==  8) col = SPRROW(x,0.,1.,1.,1.,3.,3.,3.,3., 1.,2.,2.,2.,1.,2.,1.,0.);
	if (y ==  7) col = SPRROW(x,1.,2.,2.,2.,1.,3.,3.,3., 1.,2.,2.,2.,1.,2.,1.,0.);
	if (y ==  6) col = SPRROW(x,1.,2.,2.,2.,2.,1.,3.,3., 3.,1.,2.,2.,2.,2.,1.,0.);
	if (y ==  5) col = SPRROW(x,1.,2.,2.,2.,2.,1.,3.,3., 3.,3.,1.,1.,1.,1.,1.,1.);
	if (y ==  4) col = SPRROW(x,0.,1.,2.,2.,2.,1.,3.,3., 3.,1.,2.,2.,2.,2.,2.,1.);
	if (y ==  3) col = SPRROW(x,0.,1.,1.,1.,1.,3.,3.,3., 1.,2.,1.,1.,1.,1.,1.,1.);
	if (y ==  2) col = SPRROW(x,0.,0.,1.,3.,3.,3.,3.,3., 3.,1.,2.,2.,2.,2.,1.,0.);
	if (y ==  1) col = SPRROW(x,0.,0.,0.,1.,1.,3.,3.,3., 3.,3.,1.,1.,1.,1.,1.,0.);
	if (y ==  0) col = SPRROW(x,0.,0.,0.,0.,0.,1.,1.,1., 1.,1.,0.,0.,0.,0.,0.,0.);
		
	col = SELECT(mod(float(x),8.0),col);
	if (col == 1.0) {
		fragColor = RGB(82,56,70); // outline color (black)
	}
	else if (col == 2.0) {
		fragColor = RGB(250,250,250); // eye color (white)
	}
	else if (col == 3.0) {
		fragColor = RGB(247, 182, 67); // normal yellow color
	}
	
	// pass 1 - draw red, light yellow and dark yellow
	col = 0.0; // 0 = transparent
	if (y == 11) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y == 10) col = SPRROW(x,0.,0.,0.,0.,0.,0.,3.,3., 3.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  9) col = SPRROW(x,0.,0.,0.,0.,3.,3.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  8) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  7) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  6) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  5) col = SPRROW(x,0.,3.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  4) col = SPRROW(x,0.,0.,3.,3.,3.,0.,0.,0., 0.,0.,1.,1.,1.,1.,1.,0.);
	if (y ==  3) col = SPRROW(x,0.,0.,0.,0.,0.,2.,2.,2., 0.,1.,0.,0.,0.,0.,0.,0.);
	if (y ==  2) col = SPRROW(x,0.,0.,0.,2.,2.,2.,2.,2., 2.,0.,1.,1.,1.,1.,0.,0.);
	if (y ==  1) col = SPRROW(x,0.,0.,0.,0.,0.,2.,2.,2., 2.,2.,0.,0.,0.,0.,0.,0.);
	if (y ==  0) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);	
	
	col = SELECT(mod(float(x),8.0),col);
	if (col == 1.0) {
		fragColor = RGB(249, 58, 28); // mouth color (red)	
	}
	else if (col == 2.0) {
		fragColor = RGB(222, 128, 55); // brown
	}
	else if (col == 3.0) {
		fragColor = RGB(249, 214, 145); // light yellow			
	}		
}

vec2 getLevelPixel(vec2 fragCoord)
{
	// Get the current game pixel
	// (Each game pixel is two screen pixels)
	//  (or four, if the screen is larger)
	float x = fragCoord.x / 2.0;
	float y = fragCoord.y / 2.0;
	
	if (iResolution.y >= 640.0) {
		x /= 2.0;
		y /= 2.0;
	}
	
	if (iResolution.y < 200.0) {
		x *= 2.0;
		y *= 2.0;
	}
	
	return vec2(x,y);
}

vec2 getLevelBounds()
{
	// same logic as getLevelPixel, but returns the boundaries of the screen

	float x = iResolution.x / 2.0;
	float y = iResolution.y / 2.0;
	
	if (iResolution.y >= 640.0) {
		x /= 2.0;
		y /= 2.0;
	}
	
	if (iResolution.y < 200.0) {
		x *= 2.0;
		y *= 2.0;
	}
	
	return vec2(x,y);
}

void drawGround(vec2 co)
{
	drawHorzRect(co.y, 0.0, 31.0, RGB(221, 216, 148));
	drawHorzRect(co.y, 31.0, 32.0, RGB(208, 167, 84)); // shadow below the green sprites
}

void drawGreenStripes(vec2 co)
{
	int f = int(mod(iTime * 60.0, 6.0));
	
	drawHorzRect(co.y, 32.0, 33.0, RGB(86, 126, 41)); // shadow blow
	
	const float MIN_Y = 33.0;
	const float HEIGHT = 6.0;
	
	vec4 darkGreen  = RGB(117, 189, 58);
	vec4 lightGreen = RGB(158, 228, 97);
	
	// draw diagonal stripes, and animate them
	if ((co.y >= MIN_Y) && (co.y < MIN_Y+HEIGHT)) {
		float yPos = co.y - MIN_Y - float(f);
		float xPos = mod((co.x - yPos), HEIGHT);
		
		if (xPos >= HEIGHT / 2.0) {
			fragColor = darkGreen;
		}
		else {
			fragColor = lightGreen;
		}
	}
	
	drawHorzRect(co.y, 37.0, 38.0, RGB(228, 250, 145)); // shadow highlight above
	drawHorzRect(co.y, 38.0, 39.0, RGB(84, 56, 71)); // black separator	
}
	
void drawTile(int type, vec2 tileCorner, vec2 co)
{
	if ((co.x < tileCorner.x) || (co.x > (tileCorner.x + 16.0)) ||
		(co.y < tileCorner.y) || (co.y > (tileCorner.y + 16.0)))
	{
		return;	
	}
	
	int modX = int(mod(co.x - tileCorner.x, 16.0));
	int modY = int(mod(co.y - tileCorner.y, 16.0));
				
	if (type == 0){
		drawLowBush(modX, modY);
	}
	else if (type == 1) {
		drawHighBush(modX, modY);
	}
	else if (type == 2) {
		drawCloud(modX, modY);
	}
	else if (type == 3) {
		drawBirdF0(modX, modY);
	}
	else if (type == 4) {
		drawBirdF1(modX, modY);
	}
	else if (type == 5) {
		drawBirdF2(modX, modY);
	}
}

void drawVertLine(vec2 co, float xPos, float yStart, float yEnd, vec4 color)
{
	if ((co.x >= xPos) && (co.x < (xPos + 1.0)) && (co.y >= yStart) && (co.y < yEnd)) {
		fragColor = color;
	}
}

void drawHorzLine(vec2 co, float yPos, float xStart, float xEnd, vec4 color)
{
	if ((co.y >= yPos) && (co.y < (yPos + 1.0)) && (co.x >= xStart) && (co.x < xEnd)) {
		fragColor = color;
	}
}

void drawHorzGradientRect(vec2 co, vec2 bottomLeft, vec2 topRight, vec4 leftColor, vec4 rightColor)
{
	if ((co.x < bottomLeft.x) || (co.y < bottomLeft.y) ||
		(co.x > topRight.x) || (co.y > topRight.y))
	{
		return;	
	}
	
	float distanceRatio = (co.x - bottomLeft.x) / (topRight.x - bottomLeft.x); 
	
	fragColor = (1.0 - distanceRatio) * leftColor + distanceRatio * rightColor;
}

void drawBottomPipe(vec2 co, float xPos, float height)
{	
	if ((co.x < xPos) || (co.x > (xPos + PIPE_WIDTH)) ||
		(co.y < PIPE_BOTTOM) || (co.y > (PIPE_BOTTOM + height)))
	{
		return;
	}
	
	// draw the bottom part of the pipe
	// outlines
	float bottomPartEnd = PIPE_BOTTOM - PIPE_HOLE_HEIGHT + height;
	drawVertLine(co, xPos+1.0, PIPE_BOTTOM, bottomPartEnd, PIPE_OUTLINE_COLOR);
	drawVertLine(co, xPos+PIPE_WIDTH-2.0, PIPE_WIDTH, bottomPartEnd, PIPE_OUTLINE_COLOR);
	
	// gradient fills
	drawHorzGradientRect(co, vec2(xPos+2.0, PIPE_BOTTOM), vec2(xPos + 10.0, bottomPartEnd), RGB(133, 168, 75), RGB(228, 250, 145)); 
	drawHorzGradientRect(co, vec2(xPos+10.0, PIPE_BOTTOM), vec2(xPos + 20.0, bottomPartEnd), RGB(228, 250, 145), RGB(86, 126, 41)); 
	drawHorzGradientRect(co, vec2(xPos+20.0, PIPE_BOTTOM), vec2(xPos + 24.0, bottomPartEnd), RGB(86, 126, 41), RGB(86, 126, 41));
	
	// shadows
	drawHorzLine(co, bottomPartEnd - 1.0, xPos + 2.0, xPos+PIPE_WIDTH-2.0, RGB(86, 126, 41));
	
	// draw the pipe opening
	// outlines
	drawVertLine(co, xPos, bottomPartEnd, bottomPartEnd + PIPE_HOLE_HEIGHT, PIPE_OUTLINE_COLOR);
	drawVertLine(co, xPos+PIPE_WIDTH-1.0, bottomPartEnd, bottomPartEnd + PIPE_HOLE_HEIGHT, PIPE_OUTLINE_COLOR);	
	drawHorzLine(co, bottomPartEnd, xPos, xPos+PIPE_WIDTH-1.0, PIPE_OUTLINE_COLOR);
	drawHorzLine(co, bottomPartEnd + PIPE_HOLE_HEIGHT-1.0, xPos, xPos+PIPE_WIDTH-1.0, PIPE_OUTLINE_COLOR);

	// gradient fills
	float gradientBottom = bottomPartEnd + 1.0;
	float gradientTop = bottomPartEnd + PIPE_HOLE_HEIGHT - 1.0;
	drawHorzGradientRect(co, vec2(xPos+1.0, gradientBottom), vec2(xPos + 5.0, gradientTop), RGB(221, 234, 131), RGB(228, 250, 145)); 
	drawHorzGradientRect(co, vec2(xPos+5.0, gradientBottom), vec2(xPos + 22.0, gradientTop), RGB(228, 250, 145), RGB(86, 126, 41)); 
	drawHorzGradientRect(co, vec2(xPos+22.0, gradientBottom), vec2(xPos + 25.0, gradientTop), RGB(86, 126, 41), RGB(86, 126, 41));
	
	// shadows
	drawHorzLine(co, gradientBottom, xPos+1.0, xPos+25.0, RGB(86, 126, 41));
	drawHorzLine(co, gradientTop-1.0, xPos+1.0, xPos+25.0, RGB(122, 158, 67));
}

void drawTopPipe(vec2 co, float xPos, float height)
{	
	vec2 bounds = getLevelBounds();
	
	if ((co.x < xPos) || (co.x > (xPos + PIPE_WIDTH)) ||
		(co.y < (bounds.y - height)) || (co.y > bounds.y))
	{
		return;
	}
	
	// draw the bottom part of the pipe
	// outlines
	float bottomPartEnd = bounds.y + PIPE_HOLE_HEIGHT - height;
	drawVertLine(co, xPos+1.0, bottomPartEnd, bounds.y, PIPE_OUTLINE_COLOR);
	drawVertLine(co, xPos+PIPE_WIDTH-2.0, bottomPartEnd, bounds.y, PIPE_OUTLINE_COLOR);
	
	// gradient fills
	drawHorzGradientRect(co, vec2(xPos+2.0, bottomPartEnd), vec2(xPos + 10.0, bounds.y), RGB(133, 168, 75), RGB(228, 250, 145)); 
	drawHorzGradientRect(co, vec2(xPos+10.0, bottomPartEnd), vec2(xPos + 20.0, bounds.y), RGB(228, 250, 145), RGB(86, 126, 41)); 
	drawHorzGradientRect(co, vec2(xPos+20.0, bottomPartEnd), vec2(xPos + 24.0, bounds.y), RGB(86, 126, 41), RGB(86, 126, 41));
	
	// shadows
	drawHorzLine(co, bottomPartEnd+1.0, xPos + 2.0, xPos+PIPE_WIDTH-2.0, RGB(86, 126, 41));
	
	// draw the pipe opening
	// outlines
	drawVertLine(co, xPos, bottomPartEnd - PIPE_HOLE_HEIGHT, bottomPartEnd, PIPE_OUTLINE_COLOR);
	drawVertLine(co, xPos+PIPE_WIDTH-1.0, bottomPartEnd - PIPE_HOLE_HEIGHT, bottomPartEnd, PIPE_OUTLINE_COLOR);	
	drawHorzLine(co, bottomPartEnd, xPos, xPos+PIPE_WIDTH, PIPE_OUTLINE_COLOR);
	drawHorzLine(co, bottomPartEnd - PIPE_HOLE_HEIGHT, xPos, xPos+PIPE_WIDTH-1.0, PIPE_OUTLINE_COLOR);
		
	// gradient fills
	float gradientBottom = bottomPartEnd - PIPE_HOLE_HEIGHT + 1.0;
	float gradientTop = bottomPartEnd;
	drawHorzGradientRect(co, vec2(xPos+1.0, gradientBottom), vec2(xPos + 5.0, gradientTop), RGB(221, 234, 131), RGB(228, 250, 145)); 
	drawHorzGradientRect(co, vec2(xPos+5.0, gradientBottom), vec2(xPos + 22.0, gradientTop), RGB(228, 250, 145), RGB(86, 126, 41)); 
	drawHorzGradientRect(co, vec2(xPos+22.0, gradientBottom), vec2(xPos + 25.0, gradientTop), RGB(86, 126, 41), RGB(86, 126, 41));
	
	// shadows
	drawHorzLine(co, gradientBottom, xPos+1.0, xPos+25.0, RGB(122, 158, 67));
	drawHorzLine(co, gradientTop-1.0, xPos+1.0, xPos+25.0, RGB(86, 126, 41));
}

void drawBushGroup(vec2 bottomCorner, vec2 co)
{
	drawTile(0, bottomCorner, co);
	bottomCorner.x += 13.0;
	
	drawTile(1, bottomCorner, co);
	bottomCorner.x += 13.0;
	
	drawTile(0, bottomCorner, co);	
}

void drawBushes(vec2 co)
{
	drawHorzRect(co.y, 39.0, 70.0, RGB(100, 224, 117));
	
	for (int i = 0; i < 20; i++) {
		float xOffset = float(i) * 45.0;
		drawBushGroup(vec2(xOffset, 70.0), co);
		drawBushGroup(vec2(xOffset+7.0, 68.0), co);
		drawBushGroup(vec2(xOffset-16.0, 65.0), co);
	}
}

void drawClouds(vec2 co)
{
	for (int i = 0; i < 20; i++) {
		float xOffset = float(i) * 40.0;
		drawTile(2, vec2(xOffset, 95.0), co);
		drawTile(2, vec2(xOffset+14.0, 91.0), co);
		drawTile(2, vec2(xOffset+28.0, 93.0), co);
	}

	drawHorzRect(co.y, 70.0, 95.0, RGB(233,251,218));
}

void drawPipePair(vec2 co, float xPos, float bottomPipeHeight)
{
	vec2 bounds = getLevelBounds();
	float topPipeHeight = bounds.y - (VERT_PIPE_DISTANCE + PIPE_BOTTOM + bottomPipeHeight);
	
	drawBottomPipe(co, xPos, bottomPipeHeight);
	drawTopPipe(co, xPos, topPipeHeight);	
}

void drawPipes(vec2 co)
{
	// calculate the starting position of the pipes according to the current frame
	float animationCycleLength = HORZ_PIPE_DISTANCE * PIPE_PER_CYCLE; // the number of frames after which the animation should repeat itself
	int f = int(mod(iTime * 60.0, animationCycleLength));
	float xPos = -float(f);
	
	float center = (PIPE_MAX + PIPE_MIN) / 2.0; 
	float halfTop = (center + PIPE_MAX) / 2.0;
	float halfBottom = (center + PIPE_MIN) / 2.0;	
	
	for (int i = 0; i < 12; i++)
	{	
		float yPos = center;
		int cycle = int(mod(float(i),8.0));
		
		if ((cycle == 1) || (cycle == 3)){
			yPos = halfTop;
		}
		else if (cycle == 2) {
			yPos = PIPE_MAX;	
		}
		else if ((cycle == 5) || (cycle == 7)) {
			yPos = halfBottom;
		}
		else if (cycle == 6){
			yPos = PIPE_MIN;
		}
			
		drawPipePair(co, xPos, yPos);
		xPos += HORZ_PIPE_DISTANCE;
	}
}

void drawBird(vec2 co)
{
	float animationCycleLength = HORZ_PIPE_DISTANCE * PIPE_PER_CYCLE; // the number of frames after which the animation should repeat itself
	int cycleFrame = int(mod(iTime * 60.0, animationCycleLength));
	float fCycleFrame = float(cycleFrame);	
	
	const float START_POS = 110.0;
	const float SPEED = 2.88;
	const float UPDOWN_DELTA = 0.16;
	const float ACCELERATION = -0.0975;
	float jumpFrame = float(int(mod(iTime * 60.0, 30.0)));
	int horzDist = int(HORZ_PIPE_DISTANCE);
	
	// calculate the "jumping" effect on the Y axis.
	// Using equations of motion, const acceleration: x = x0 + v0*t + 1/2at^2  
	float yPos = START_POS + SPEED * jumpFrame + ACCELERATION * pow(jumpFrame, 2.0);
	
	float speedDelta = UPDOWN_DELTA * mod(fCycleFrame, HORZ_PIPE_DISTANCE);
	int prevUpCycles = 0;
	int prevDownCycles = 0;
	
	// count the number of pipes we've already passed. 
	// for each such pipe, we deduce if we went "up" or "down" in Y
	int cycleCount = int(fCycleFrame / HORZ_PIPE_DISTANCE);
	
	for (int i = 0; i < 10; i++) {
		if (i <= cycleCount) {
			if (i == 1) {
				prevUpCycles++;
			}
			
			if ((i >= 2) && (i < 6)) {
				prevDownCycles++;	
			}
			if (i >= 6) {
				prevUpCycles++;
			}		
		}
	}
	
	// add up/down delta from all the previous pipes
	yPos += ((float(prevUpCycles - prevDownCycles)) * HORZ_PIPE_DISTANCE * UPDOWN_DELTA);
	
	// calculate the up/down delta for the current two pipes, and add it to the previous result
	if (((cycleFrame >= 0) && (cycleFrame < horzDist)) ||
		((cycleFrame >= 5*horzDist) && (cycleFrame < 9*horzDist))) {
		yPos += speedDelta;
	}
	else {
		yPos -= speedDelta;	
	}	
	
	int animFrame = int(mod(iTime * 7.0, 3.0));
	if (animFrame == 0) drawTile(3, vec2(105, int(yPos)), co);
	if (animFrame == 1) drawTile(4, vec2(105, int(yPos)), co);
	if (animFrame == 2) drawTile(5, vec2(105, int(yPos)), co);
}

void mainImage( out vec4 iFragColor, in vec2 fragCoord )
{	
	vec2 levelPixel = getLevelPixel(fragCoord);
	
	fragColor = RGB(113, 197, 207); 	// draw the blue sky background
	
	drawGround(levelPixel);	
	drawGreenStripes(levelPixel);
	drawClouds(levelPixel);
	drawBushes(levelPixel);
	drawPipes(levelPixel);
	drawBird(levelPixel);
    
    iFragColor = fragColor;
}