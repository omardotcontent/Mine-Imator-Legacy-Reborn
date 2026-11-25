uniform sampler2D uTexture; // static

uniform float uSampleIndex;
uniform int uAlphaHash;
uniform int uSkipTranslucent; // static

varying vec3 vPosition;
varying vec2 vTexCoord;
varying float vDepth;
varying vec4 vColor;

vec4 packDepth(float f)
{
	float q = floor(clamp(f, 0.0, 1.0) * 16581375.0 + 0.5);
	float r = floor(q / 65025.0);
	if (r * 65025.0 > q)
		r -= 1.0;
	q -= r * 65025.0;
	float g = floor(q / 255.0);
	if (g * 255.0 > q)
		g -= 1.0;
	float b = q - g * 255.0;
	return vec4(r, g, b, 255.0) / 255.0;
}

float hash(vec2 c)
{
	return fract(10000.0 * sin(17.0 * c.x + 0.1 * c.y) *
	(0.1 + abs(sin(13.0 * c.y + c.x))));
}

void main()
{
	vec2 tex = vTexCoord;
	vec4 texCol = texture2D(uTexture, tex);
	vec4 col = texCol * vColor;
	if (texCol.a < 0.05 || col.a < 0.1)
		discard;
	if (uSkipTranslucent > 0 && col.a < 0.96)
		discard;
	
	if (uAlphaHash > 0 && (col.a < hash(vec2(hash(vPosition.xy + (uSampleIndex / 255.0)), vPosition.z + (uSampleIndex / 255.0)))))
		discard;
	
	gl_FragColor = packDepth(vDepth);
}

