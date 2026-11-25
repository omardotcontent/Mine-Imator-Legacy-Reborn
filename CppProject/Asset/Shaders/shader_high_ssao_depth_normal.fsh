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
uniform float uPbrNormalStrength; // static
uniform int uPbrPomEnable; // static
uniform float uPbrPomDepth; // static
uniform int uPbrPomSamples; // static
uniform float uPbrEmissiveStrength; // static
uniform float uPbrAoStrength; // static
uniform vec2 uPbrTileGrid;
uniform vec4 uPbrMatOverride;

// Water ripples & Global Wetness / Rain Puddles
uniform float uRippleTime; // static
uniform int uWaterRipples; // static
uniform float uWaterRippleStrength; // static
uniform float uWaterRippleSpeed; // static
uniform float uWetness; // static
uniform int uWetnessRipples; // static

varying vec3 vWorldPos;
varying vec3 vWorldNormal;
varying vec3 vViewPos;
varying vec2 vTexCoord;
varying float vDepth;
varying vec3 vNormal;
varying vec3 vTangent;
varying float vHasTangent;
varying vec4 vColor;
varying vec4 vCustom;

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

vec2 clampTileUV(vec2 cand, vec2 tileMin, vec2 tileMax, vec2 grid, bool clampToTile)
{
	if (!clampToTile)
		return cand;
	vec2 pad = vec2(0.0005) / grid;
	return clamp(cand, tileMin + pad, tileMax - pad);
}

vec2 getPomUV(vec2 uv, vec3 viewDir, vec3 geomN, vec3 geomT, float hasT)
{
	if (uUseNormalMap < 1 || uPbrPomEnable < 1 || hasT < 0.5 || uPbrPomDepth <= 0.0001)
		return uv;
	if (texture2D(/* lod0 */uTexture, uv).a < 0.5)
		return uv;
	float h0 = texture2D(/* lod0 */uTextureNormal, uv).a;
	if (h0 < 0.005 || h0 >= 0.996)
		return uv;
	vec3 N = normalize(geomN);
	vec3 T = normalize(geomT - dot(geomT, N) * N);
	vec3 Bv = cross(N, T);
	float ndotv = dot(viewDir, N);
	if (ndotv <= 0.05)
		return uv;
	bool clampToTile = (uPbrTileGrid.x > 1.5 || uPbrTileGrid.y > 1.5);
	vec2 gridAbs = max(vec2(1.0), abs(uPbrTileGrid));
	vec2 tileIdx = floor(uv * gridAbs);
	vec2 tileMin = tileIdx / gridAbs;
	vec2 tileMax = (tileIdx + 1.0) / gridAbs;
	float grazingFade = smoothstep(0.05, 0.35, ndotv);
	vec2 viewTS = vec2(dot(viewDir, T), dot(viewDir, Bv)) / (ndotv + 0.45);
	vec2 maxOffset = -viewTS * ((uPbrPomDepth * grazingFade) / gridAbs);
	int numSteps = clamp(uPbrPomSamples, 4, 32);
	float layerStep = 1.0 / float(numSteps);
	vec2 uvStep = maxOffset * layerStep;
	float currLayerDepth = 0.0;
	vec2 currUV = uv;
	float currDepthVal = 1.0 - h0;
	vec2 prevUV = uv;
	float prevDepthVal = currDepthVal;
	float prevLayerDepth = 0.0;
	bool hit = false;
	for (int i = 0; i < 32; i++)
	{
		if (i >= numSteps || currLayerDepth >= currDepthVal)
		{
			hit = (currLayerDepth >= currDepthVal);
			break;
		}
		vec2 candUV = clampTileUV(uv + uvStep * float(i + 1), tileMin, tileMax, gridAbs, clampToTile);
		float candAlpha = texture2D(/* lod0 */uTexture, candUV).a;
		float hs = texture2D(/* lod0 */uTextureNormal, candUV).a;
		if (candAlpha < 0.5 || hs < 0.005)
			break;
		prevUV = currUV;
		prevDepthVal = currDepthVal;
		prevLayerDepth = currLayerDepth;
		currUV = candUV;
		currLayerDepth += layerStep;
		currDepthVal = 1.0 - hs;
		if (currLayerDepth >= currDepthVal)
		{
			hit = true;
			break;
		}
	}
	if (hit && currLayerDepth > prevLayerDepth)
	{
		for (int b = 0; b < 5; b++)
		{
			vec2 midUV = 0.5 * (prevUV + currUV);
			float midLayer = 0.5 * (prevLayerDepth + currLayerDepth);
			float midA = texture2D(/* lod0 */uTexture, midUV).a;
			float midH = texture2D(/* lod0 */uTextureNormal, midUV).a;
			float midDepth = (midA < 0.5 || midH < 0.005) ? 0.0 : (1.0 - midH);
			if (midLayer >= midDepth)
			{
				currUV = midUV;
				currLayerDepth = midLayer;
				currDepthVal = midDepth;
			}
			else
			{
				prevUV = midUV;
				prevLayerDepth = midLayer;
				prevDepthVal = midDepth;
			}
		}
		float afterDiff = currDepthVal - currLayerDepth;
		float beforeDiff = prevDepthVal - prevLayerDepth;
		float denom = afterDiff - beforeDiff;
		float weight = (abs(denom) > 0.00001) ? clamp(afterDiff / denom, 0.0, 1.0) : 0.0;
		currUV = mix(currUV, prevUV, weight);
	}
	if (texture2D(/* lod0 */uTexture, currUV).a < 0.5)
		return uv;
	return currUV;
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
			vec2 nxy = (n.xy * 2.0 - 1.0) * (uPbrNormalStrength * max(0.0, uPbrMatOverride.w));
			if (uPbrMatOverride.z < 0.5)
				nxy.y *= -1.0;
			float len2 = dot(nxy, nxy);
			float nz = (len2 < 0.999) ? sqrt(1.0 - len2) : 0.03;
			vec3 tn = normalize(vec3(nxy, nz));
			N = normalize(T * tn.x + B * tn.y + N * tn.z);
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

void getMaterialData(vec2 uv, out float roughness, out float metallic, out float f0, out float matEmissive, out float porosity)
{
	roughness = clamp(uRoughness, 0.02, 1.0);
	metallic = clamp(uMetallic, 0.0, 1.0);
	f0 = mix(0.04, 0.85, metallic);
	matEmissive = 0.0;
	porosity = 0.0;
	
	if (uUseNormalMap > 0)
	{
		vec4 matCol = texture2D(uTextureMaterial, uv);
		if (uMaterialFormat == 2)
		{
			roughness = clamp(pow(1.0 - matCol.r, 2.0), 0.02, 1.0);
			float gByte = floor(matCol.g * 255.0 + 0.5);
			if (gByte < 229.5)
			{
				metallic = 0.0;
				f0 = clamp(matCol.g, 0.02, 0.90);
				float bByte = floor(matCol.b * 255.0 + 0.5);
				porosity = (bByte <= 64.5) ? (bByte / 64.0) : 0.0;
			}
			else
			{
				metallic = 1.0;
				f0 = 0.85;
			}
			float aByte = floor(matCol.a * 255.0 + 0.5);
			matEmissive = (aByte < 254.5) ? ((aByte / 254.0) * max(0.0, uDefaultEmissive) * uPbrEmissiveStrength) : 0.0;
		}
		else if (uMaterialFormat == 1)
		{
			roughness = clamp(1.0 - matCol.r, 0.02, 1.0);
			metallic = clamp(matCol.g, 0.0, 1.0);
			f0 = mix(0.04, 0.85, metallic);
			matEmissive = matCol.b * max(0.0, uDefaultEmissive) * uPbrEmissiveStrength;
			porosity = 0.35 * (1.0 - metallic) * roughness;
		}
	}
	if (uPbrMatOverride.x >= 0.0)
		roughness = clamp(uPbrMatOverride.x, 0.02, 1.0);
	if (uPbrMatOverride.y >= 0.0)
	{
		metallic = clamp(uPbrMatOverride.y, 0.0, 1.0);
		f0 = mix(0.04, 0.88, metallic);
	}
}

void main()
{
	vec2 uv = getPomUV(vTexCoord, normalize(-vViewPos), vNormal, vTangent, vHasTangent);
	vec4 baseColor = texture2D(uTexture, uv);
	if (baseColor.a < 0.05 || baseColor.a * vColor.a < 0.15)
		discard;
	
	// Upward-facing wetness / puddle mask
	float upMask = smoothstep(0.60, 0.85, normalize(vWorldNormal).z);
	float wetMask = (uWetness > 0.001) ? (puddleMask(vWorldPos.xy) * upMask * uWetness) : 0.0;
	
	// Depth
	gl_FragData[0] = packDepth(vDepth);
	
	// Normal (view space, with normal map + water/rain ripples)
	gl_FragData[1] = packNormal(getMappedNormal(uv, wetMask));
	
	// Material & SSAO mask: R = SSAO brightness mask, G = reflectivity (for SSR), B = water mask
	float roughness, metallic, f0, matEmissive, porosity;
	getMaterialData(uv, roughness, metallic, f0, matEmissive, porosity);
	if (wetMask > 0.001)
		roughness = mix(roughness, 0.06, clamp(wetMask * mix(0.5, 1.0, porosity), 0.0, 1.0));
	
	float br;
	if (uSSAOEnable > 0 && uIsWater == 0)
		br = max(0.0, vColor.a - max(uBrightness, matEmissive) - vCustom.z * uBlockBrightness);
	else
		br = 0.0;
	
	float gloss = clamp((1.0 - roughness) * (0.28 + max(metallic, f0) * 0.72), 0.0, 1.0);
	float refl = max(gloss, wetMask * 0.92);
	if (uIsWater > 0)
		refl = 0.96;
	
	float outMask = (uIsGround > 0 || uOutlineEnable < 1) ? 0.0 : 1.0;
	gl_FragData[2] = vec4(br, refl, (uIsWater > 0) ? 1.0 : 0.0, outMask);
}
