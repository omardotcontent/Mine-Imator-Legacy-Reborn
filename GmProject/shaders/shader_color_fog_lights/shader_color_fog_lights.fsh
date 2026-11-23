uniform sampler2D uTexture; // static
uniform vec2 uTextureSize;

uniform sampler2D uGlintTexture; // static
uniform vec2 uGlintOffset;
uniform vec2 uGlintSize;
uniform int uGlintEnabled;
uniform float uGlintStrength;

uniform int uColorsExt;
uniform vec4 uRGBAdd;
uniform vec4 uRGBSub;
uniform vec4 uHSBAdd;
uniform vec4 uHSBSub;
uniform vec4 uHSBMul;
uniform vec4 uMixColor;

uniform int uFogShow;
uniform vec4 uFogColor; // static
uniform float uFogDistance; // static
uniform float uFogSize; // static
uniform float uFogHeight; // static

uniform vec3 uCameraPosition; // static
uniform int uIsSky;

uniform int uIsPlanarMirror;
uniform float uMirrorStrength;
uniform vec4 uMirrorVPX; // static
uniform vec4 uMirrorVPY; // static
uniform vec4 uMirrorVPW; // static
uniform sampler2D uMirrorTexture; // static
uniform vec4 uMirrorClipPlane; // static

varying vec3 vPosition;
varying float vDepth;
varying vec4 vColor;
varying vec2 vTexCoord;
varying vec3 vDiffuse;

vec4 rgbtohsb(vec4 c)
{
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec4(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x, c.a);
}

vec4 hsbtorgb(vec4 c)
{
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return vec4(c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y), c.a);
}

float getFog()
{
	float fog;
	if (uFogShow > 0)
	{
		float fogDepth = distance(vPosition, uCameraPosition);
		
		fog = clamp(1.0 - (uFogDistance - fogDepth) / uFogSize, 0.0, 1.0);
		fog *= clamp(1.0 - (vPosition.z - uFogHeight) / uFogSize, 0.0, 1.0);
	}
	else
		fog = 0.0;
	
	return fog;
}

void main()
{
	if (uIsSky < 1 && dot(uMirrorClipPlane.xyz, uMirrorClipPlane.xyz) > 0.25)
	{
		if (dot(vPosition, uMirrorClipPlane.xyz) + uMirrorClipPlane.w < -0.25)
			discard;
	}
	vec2 tex = vTexCoord;
	vec4 baseColor = vColor * texture2D(uTexture, tex);
	
	vec4 col;
	if (uColorsExt > 0)
	{
		col = clamp(baseColor + uRGBAdd - uRGBSub, 0.0, 1.0);
		col = hsbtorgb(clamp(rgbtohsb(col) + uHSBAdd - uHSBSub, 0.0, 1.0) * uHSBMul);
		col = mix(col, uMixColor, uMixColor.a);
	}
	else
		col = baseColor;
	
	col.rgb *= vDiffuse;
	if (uIsPlanarMirror > 0 && baseColor.a > 0.01)
	{
		vec4 wp4 = vec4(vPosition, 1.0);
		float mw = max(0.0001, dot(uMirrorVPW, wp4));
		vec2 muv = vec2(dot(uMirrorVPX, wp4), dot(uMirrorVPY, wp4)) / mw * 0.5 + 0.5;
		muv.y = 1.0 - muv.y;
		muv = clamp(muv, 0.001, 0.999);
		vec4 reflCol = texture2D(uMirrorTexture, muv);
		col.rgb = mix(col.rgb, reflCol.rgb * vColor.rgb, clamp(uMirrorStrength, 0.0, 1.0));
	}
	
	if (uGlintEnabled > 0 && baseColor.a > 0.0)
		col.rgb += texture2D(uGlintTexture, (tex * (uTextureSize / uGlintSize)) + uGlintOffset).rgb * baseColor.a * uGlintStrength;
	
	col = mix(col, uFogColor, getFog());
	col.a = baseColor.a;
	
	gl_FragColor = col;
	
	if (gl_FragColor.a == 0.0)
		discard;
}
