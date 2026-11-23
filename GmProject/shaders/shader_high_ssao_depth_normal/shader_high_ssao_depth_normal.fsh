uniform sampler2D uTexture; // static
uniform sampler2D uTextureMaterial; // static
uniform sampler2D uTextureNormal; // static

uniform float uBrightness;
uniform float uBlockBrightness; // static
uniform int uSSAOEnable;
uniform int uIsWater;
uniform int uIsGround;
uniform int uOutlineEnable;

uniform int uUseNormalMap; // static
uniform int uMaterialFormat;
uniform float uRoughness;
uniform float uMetallic;
uniform float uDefaultEmissive; // static

// Water ripples & Global Wetness / Rain Puddles
uniform float uRippleTime; // static
uniform int uWaterRipples; // static
uniform float uWaterRippleStrength; // static
uniform float uWaterRippleSpeed; // static
uniform float uWetness; // static
uniform int uWetnessRipples; // static

varying vec3 vWorldPos;
varying vec3 vWorldNormal;
varying vec2 vTexCoord;
varying float vDepth;
varying vec3 vNormal;
varying vec3 vTangent;
varying float vHasTangent;
varying vec4 vColor;
varying vec4 vCustom;

vec4 packDepth(float f)
{
	return vec4(floor(f * 255.0) / 255.0, fract(f * 255.0), fract(f * 255.0 * 255.0), 1.0);
}

vec4 packNormal(vec3 n)
{
	return vec4((n + vec3(1.0, 1.0, 1.0)) / 2.0, 1.0);
}

float hash21(vec2 p)
{
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float valueNoise(vec2 p)
{
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float puddleMask(vec2 wp)
{
	float n = valueNoise(wp * 0.022) * 0.65 + valueNoise(wp * 0.058 + vec2(7.3, 19.1)) * 0.35;
	return smoothstep(0.92 - uWetness * 0.80, 0.98 - uWetness * 0.42, n);
}

vec2 getWaterRippleOffset(vec2 wp, float t)
{
	float w1 = sin(wp.x * 0.32 + wp.y * 0.20 + t * 2.4);
	float w2 = cos(wp.x * 0.19 - wp.y * 0.38 + t * 3.1);
	float w3 = sin((wp.x + wp.y) * 0.62 - t * 4.2);
	float w4 = cos((wp.x - wp.y) * 0.48 + t * 2.8);
	return vec2(w1 + w3 * 0.55 + w4 * 0.35, w2 - w3 * 0.55 + w4 * 0.35);
}

vec2 getRainRippleLayer(vec2 wp, float t, float scale, float offset)
{
	vec2 p = wp * scale + vec2(offset * 17.3, offset * 9.7);
	vec2 cell = floor(p);
	vec2 local = fract(p) - 0.5;
	float phase = fract(t * 0.85 + hash21(cell));
	float dist = length(local);
	float radius = phase * 0.48;
	float ring = sin((dist - radius) * 38.0) * exp(-abs(dist - radius) * 14.0) * (1.0 - phase) * step(dist, 0.48);
	vec2 dir = (dist > 0.001) ? (local / dist) : vec2(0.0);
	return dir * ring;
}

vec2 getRainRippleOffset(vec2 wp, float t)
{
	return getRainRippleLayer(wp, t, 0.16, 0.0) + getRainRippleLayer(wp, t * 1.13, 0.23, 3.7) * 0.75;
}

vec3 getMappedNormal(vec2 uv, float wetMask)
{
	vec3 N = normalize(vNormal);
	vec3 T = (vHasTangent > 0.5) ? normalize(vTangent - dot(vTangent, N) * N) : normalize(cross(abs(N.y) < 0.9 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0), N));
	vec3 B = cross(T, N);
	
	if (uUseNormalMap > 0 && vHasTangent > 0.5)
	{
		vec4 n = texture2D(uTextureNormal, uv);
		if (n.a >= 0.01)
		{
			n.xy = n.xy * 2.0 - 1.0;
			n.z = sqrt(max(0.0, 1.0 - dot(n.xy, n.xy)));
			n.y *= -1.0;
			N = normalize(mat3(T, B, N) * n.xyz);
		}
	}
	
	if (uIsWater > 0 && uWaterRipples > 0)
	{
		vec2 rip = getWaterRippleOffset(vWorldPos.xy, uRippleTime * uWaterRippleSpeed) * (0.24 * uWaterRippleStrength);
		N = normalize(N + T * rip.x + B * rip.y);
	}
	else if (wetMask > 0.05 && uWetnessRipples > 0)
	{
		vec2 rip = getRainRippleOffset(vWorldPos.xy, uRippleTime) * (0.45 * wetMask);
		N = normalize(N + T * rip.x + B * rip.y);
	}
	
	return N;
}

void getMaterialData(vec2 uv, out float roughness, out float metallic, out float matEmissive)
{
	roughness = uRoughness;
	metallic = uMetallic;
	matEmissive = 0.0;
	
	if (uUseNormalMap < 1)
		return;
	
	vec4 matColor = texture2D(uTextureMaterial, uv);
	if (uMaterialFormat == 2)
	{
		roughness = pow(1.0 - matColor.r, 2.0);
		metallic = (matColor.g > 0.898) ? 1.0 : 0.0;
		matEmissive = (matColor.a < 0.999 ? (matColor.a / 0.9961) : 0.0) * uDefaultEmissive;
	}
	else if (uMaterialFormat == 1)
	{
		roughness = 1.0 - matColor.r;
		metallic = matColor.g;
		matEmissive = matColor.b * uDefaultEmissive;
	}
}

void main()
{
	vec4 baseColor = texture2D(uTexture, vTexCoord);
	if (baseColor.a < 0.15)
		discard;
	
	// Upward-facing wetness / puddle mask
	float upMask = smoothstep(0.60, 0.85, normalize(vWorldNormal).z);
	float wetMask = (uWetness > 0.001) ? (puddleMask(vWorldPos.xy) * upMask * uWetness) : 0.0;
	
	// Depth
	gl_FragData[0] = packDepth(vDepth);
	
	// Normal (view space, with normal map + water/rain ripples)
	gl_FragData[1] = packNormal(getMappedNormal(vTexCoord, wetMask));
	
	// Material & SSAO mask: R = SSAO brightness mask, G = reflectivity (for SSR), B = water mask
	float roughness, metallic, matEmissive;
	getMaterialData(vTexCoord, roughness, metallic, matEmissive);
	
	float br;
	if (uSSAOEnable > 0 && uIsWater == 0)
		br = max(0.0, vColor.a - max(uBrightness, matEmissive) - vCustom.z * uBlockBrightness);
	else
		br = 0.0;
	
	float gloss = clamp((1.0 - roughness) * (0.35 + metallic * 0.65), 0.0, 1.0);
	float refl = max(gloss, wetMask * 0.92);
	if (uIsWater > 0)
		refl = 0.96;
	
	float outMask = (uIsGround > 0 || uOutlineEnable < 1) ? 0.0 : 1.0;
	gl_FragData[2] = vec4(br, refl, (uIsWater > 0) ? 1.0 : 0.0, outMask);
}
