uniform sampler2D uTexture; // static
uniform sampler2D uTextureMaterial; // static

uniform int uColorsExt;
uniform vec4 uRGBAdd;
uniform vec4 uRGBSub;
uniform vec4 uHSBAdd;
uniform vec4 uHSBSub;
uniform vec4 uHSBMul;
uniform vec4 uMixColor;

uniform int uGlow;
uniform int uGlowTexture;
uniform vec4 uGlowColor;
uniform int uBlockGlow; // static
uniform float uGlowThreshold; // static

uniform int uUseMaterialMap; // static
uniform int uMaterialFormat;
uniform float uDefaultEmissive; // static

uniform int uFogShow;
uniform float uFogDistance; // static
uniform float uFogSize; // static
uniform float uFogHeight; // static

uniform vec3 uCameraPosition; // static

varying vec3 vPosition;
varying float vDepth;
varying vec4 vColor;
varying vec2 vTexCoord;
varying float vBrightness;

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

float getMaterialEmissive(vec2 uv)
{
	if (uUseMaterialMap < 1)
		return 0.0;
	vec4 matColor = texture2D(uTextureMaterial, uv);
	if (uMaterialFormat == 2)
		return (matColor.a < 0.999 ? (matColor.a / 0.9961) : 0.0) * uDefaultEmissive;
	if (uMaterialFormat == 1)
		return matColor.b * uDefaultEmissive;
	return 0.0;
}

void main()
{
	vec2 tex = vTexCoord;
	vec4 baseColor = vColor * texture2D(uTexture, tex);
	float matEmissive = getMaterialEmissive(tex);
	float totalBright = max(vBrightness, matEmissive);
	
	// Glow isn't enabled on object, but bright blocks or material-emissive pixels should still glow
	if (uGlow < 1 && uBlockGlow > 0)
	{
		if (matEmissive > 0.01 || ((baseColor.r + baseColor.g + baseColor.b) / 3.0) > uGlowThreshold)
			baseColor.rgb *= vec3(totalBright);
		else
			baseColor.rgb *= vec3(0.0);
	}
	else if (uGlow < 1)
	{
		baseColor.rgb *= vec3(0.0);
	}
	else
	{
		// Glow using base texture and color settings
		if (uGlowTexture > 0)
		{
			if (uColorsExt > 0)
			{
				float baseAlpha = baseColor.a;
				baseColor = clamp(baseColor + uRGBAdd - uRGBSub, 0.0, 1.0);
				baseColor = hsbtorgb(clamp(rgbtohsb(baseColor) + uHSBAdd - uHSBSub, 0.0, 1.0) * uHSBMul);
				baseColor = mix(baseColor, uMixColor, uMixColor.a);
				baseColor.a = baseAlpha;
			}
			
			baseColor.rgb *= uGlowColor.rgb;
		}
		else
			baseColor.rgb = uGlowColor.rgb;
	}
	
	baseColor.rgb *= vec3(1.0 - getFog());
	
	if ((baseColor.a <= 0.98 && uGlow < 1) || baseColor.a == 0.0)
		discard;
	
	gl_FragColor = baseColor;
}
