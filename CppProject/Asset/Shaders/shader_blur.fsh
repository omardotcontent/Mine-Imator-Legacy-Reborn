#define MAX_SAMPLES 65

varying vec2 vTexCoord;

uniform vec2 uScreenSize;
uniform float uRadius;
uniform vec2 uDirection;
uniform int uBlurMode;

uniform vec2 uKernel[MAX_SAMPLES];
uniform int uSamples;

vec4 getColor(vec2 txcoord)
{
	float xcoord = txcoord.x;
	float ycoord = txcoord.y;

	if (xcoord > 1.0)
		xcoord = 1.0 - (xcoord - 1.0);
		
	if (xcoord < 0.0)
		xcoord = xcoord * -1.0;
		
	if (ycoord > 1.0)
		ycoord = 1.0 - (ycoord - 1.0);
		
	if (ycoord < 0.0)
		ycoord = ycoord * -1.0;

	return texture2D(/* lod0 */gm_BaseTexture, vec2(xcoord, ycoord));
}

float karisWeight(vec3 col)
{
	vec3 luma = col * vec3(0.2126, 0.7152, 0.0722);
	float lum = luma.r + luma.g + luma.b;
	return 1.0 / (1.0 + max(lum, 0.0));
}

void main()
{
	if (uBlurMode == 1)
	{
		// 13-tap Jimenez dual-filter downsample with Karis firefly suppression on first mip
		vec2 texel = 1.0 / max(uScreenSize, vec2(1.0, 1.0));
		float x = texel.x;
		float y = texel.y;
		
		vec3 a = texture2D(/* lod0 */gm_BaseTexture, clamp(vTexCoord + vec2(-2.0 * x,  2.0 * y), vec2(0.0), vec2(1.0))).rgb;
		vec3 b = texture2D(/* lod0 */gm_BaseTexture, clamp(vTexCoord + vec2( 0.0,      2.0 * y), vec2(0.0), vec2(1.0))).rgb;
		vec3 c = texture2D(/* lod0 */gm_BaseTexture, clamp(vTexCoord + vec2( 2.0 * x,  2.0 * y), vec2(0.0), vec2(1.0))).rgb;
		vec3 d = texture2D(/* lod0 */gm_BaseTexture, clamp(vTexCoord + vec2(-2.0 * x,  0.0),     vec2(0.0), vec2(1.0))).rgb;
		vec3 e = texture2D(/* lod0 */gm_BaseTexture, clamp(vTexCoord,                             vec2(0.0), vec2(1.0))).rgb;
		vec3 f = texture2D(/* lod0 */gm_BaseTexture, clamp(vTexCoord + vec2( 2.0 * x,  0.0),     vec2(0.0), vec2(1.0))).rgb;
		vec3 g = texture2D(/* lod0 */gm_BaseTexture, clamp(vTexCoord + vec2(-2.0 * x, -2.0 * y), vec2(0.0), vec2(1.0))).rgb;
		vec3 h = texture2D(/* lod0 */gm_BaseTexture, clamp(vTexCoord + vec2( 0.0,     -2.0 * y), vec2(0.0), vec2(1.0))).rgb;
		vec3 j = texture2D(/* lod0 */gm_BaseTexture, clamp(vTexCoord + vec2( 2.0 * x, -2.0 * y), vec2(0.0), vec2(1.0))).rgb;
		vec3 k = texture2D(/* lod0 */gm_BaseTexture, clamp(vTexCoord + vec2(-x,  y), vec2(0.0), vec2(1.0))).rgb;
		vec3 l = texture2D(/* lod0 */gm_BaseTexture, clamp(vTexCoord + vec2( x,  y), vec2(0.0), vec2(1.0))).rgb;
		vec3 m = texture2D(/* lod0 */gm_BaseTexture, clamp(vTexCoord + vec2(-x, -y), vec2(0.0), vec2(1.0))).rgb;
		vec3 n = texture2D(/* lod0 */gm_BaseTexture, clamp(vTexCoord + vec2( x, -y), vec2(0.0), vec2(1.0))).rgb;
		
		vec3 g0 = (a + b + d + e) * 0.25;
		vec3 g1 = (b + c + e + f) * 0.25;
		vec3 g2 = (d + e + g + h) * 0.25;
		vec3 g3 = (e + f + h + j) * 0.25;
		vec3 g4 = (k + l + m + n) * 0.25;
		
		vec3 downCol;
		if (uRadius > 0.5)
		{
			float kw0 = karisWeight(g0) * 0.125;
			float kw1 = karisWeight(g1) * 0.125;
			float kw2 = karisWeight(g2) * 0.125;
			float kw3 = karisWeight(g3) * 0.125;
			float kw4 = karisWeight(g4) * 0.5;
			downCol = (g0 * kw0 + g1 * kw1 + g2 * kw2 + g3 * kw3 + g4 * kw4) / max(kw0 + kw1 + kw2 + kw3 + kw4, 0.0001);
		}
		else
		{
			downCol = g4 * 0.5 + (g0 + g1 + g2 + g3) * 0.125;
		}
		gl_FragColor = vec4(max(downCol, vec3(0.0)), 1.0);
		return;
	}
	else if (uBlurMode == 2)
	{
		// 9-tap 3x3 tent upsample
		vec2 d = (1.0 / max(uScreenSize, vec2(1.0, 1.0))) * max(uRadius, 0.25);
		vec3 a = texture2D(/* lod0 */gm_BaseTexture, clamp(vTexCoord + vec2(-d.x,  d.y), vec2(0.0), vec2(1.0))).rgb;
		vec3 b = texture2D(/* lod0 */gm_BaseTexture, clamp(vTexCoord + vec2( 0.0,  d.y), vec2(0.0), vec2(1.0))).rgb;
		vec3 c = texture2D(/* lod0 */gm_BaseTexture, clamp(vTexCoord + vec2( d.x,  d.y), vec2(0.0), vec2(1.0))).rgb;
		vec3 e = texture2D(/* lod0 */gm_BaseTexture, clamp(vTexCoord + vec2(-d.x,  0.0), vec2(0.0), vec2(1.0))).rgb;
		vec3 f = texture2D(/* lod0 */gm_BaseTexture, clamp(vTexCoord,                      vec2(0.0), vec2(1.0))).rgb;
		vec3 g = texture2D(/* lod0 */gm_BaseTexture, clamp(vTexCoord + vec2( d.x,  0.0), vec2(0.0), vec2(1.0))).rgb;
		vec3 h = texture2D(/* lod0 */gm_BaseTexture, clamp(vTexCoord + vec2(-d.x, -d.y), vec2(0.0), vec2(1.0))).rgb;
		vec3 j = texture2D(/* lod0 */gm_BaseTexture, clamp(vTexCoord + vec2( 0.0, -d.y), vec2(0.0), vec2(1.0))).rgb;
		vec3 k = texture2D(/* lod0 */gm_BaseTexture, clamp(vTexCoord + vec2( d.x, -d.y), vec2(0.0), vec2(1.0))).rgb;
		vec3 upCol = (f * 4.0 + (b + e + g + j) * 2.0 + (a + c + h + k)) * (1.0 / 16.0);
		gl_FragColor = vec4(max(upCol, vec3(0.0)), 1.0);
		return;
	}
	
	vec4 blurResult = vec4(0.0);
	vec2 blurAmount = (uRadius / max(uScreenSize, vec2(1.0, 1.0))) * uDirection;
	
	// Separable Gaussian filter
	for (int i = 0; i < MAX_SAMPLES; i++)
	{
		if (i >= uSamples)
			break;
		
		blurResult += uKernel[i].x * getColor(vTexCoord + (uKernel[i].y * blurAmount));
	}

	gl_FragColor = blurResult;
}
