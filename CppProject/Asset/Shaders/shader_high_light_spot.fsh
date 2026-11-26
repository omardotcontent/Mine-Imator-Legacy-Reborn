#define PI 3.14159265
#define TAU 6.28318530
#define GOLDEN_ANGLE 2.39996323
#define MAXSAMPLES 128

uniform sampler2D uTexture; // static
uniform sampler2D uTextureMaterial; // static
uniform sampler2D uTextureNormal; // static
uniform int uIsSky;
uniform int uIsWater;

uniform vec3 uCameraPosition; // static
uniform vec3 uLightPosition; // static
uniform vec4 uLightColor; // static
uniform float uLightStrength; // static
uniform float uLightNear; // static
uniform float uLightFar; // static
uniform float uLightFadeSize; // static
uniform float uLightSpotSharpness; // static

uniform sampler2D uDepthBuffer; // static

uniform int uBlurQuality; // static
uniform float uBlurSize; // static
uniform float uShadowBias; // static
uniform float uShadowDarkness; // static

uniform float uLightBleedStrength; // static
uniform float uBleedLight;
uniform vec4 uSubsurfaceColor;

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

uniform int uSpecularEnable; // static
uniform float uSpecularStrength; // static
uniform float uSpecularShininess; // static

uniform float uWetness; // static
uniform int uCelEnable; // static
uniform float uCelSteps; // static
uniform float uCelSmooth; // static

uniform int uGoboMode; // static
uniform float uGoboScale; // static
uniform float uGoboAngle; // static
uniform float uGoboTime; // static
uniform sampler2D uGoboTexture; // static
uniform mat4 uLightMatrix; // static

varying vec3 vPosition;
uniform vec4 uMirrorClipPlane; // static
varying vec3 vNormal;
varying vec3 vTangent;
varying float vHasTangent;
varying vec2 vTexCoord;
varying vec4 vColor;
varying vec4 vScreenCoord;
varying float vBrightness;
varying float vLightBleed;

uniform vec2 uSpotShadowParams; // static

#include "volume_medium.glsl"
#include "volume_shadow.glsl"

float unpackDepth(vec4 c)
{
	return c.r + c.g / 255.0 + c.b / (255.0 * 255.0);
}

vec2 vogelOffset(int idx, int count, float phi)
{
	float r = sqrt((float(idx) + 0.5) / float(count));
	float theta = float(idx) * GOLDEN_ANGLE + phi;
	return vec2(cos(theta), sin(theta)) * r;
}

float sampleSpotBilinear(vec2 uv, float texSize, float compareDepth, float softRange)
{
	float mapRes = 1.0 / texSize;
	vec2 st = uv * mapRes - 0.5;
	vec2 base = floor(st);
	vec2 f = st - base;
	float cMin = texSize * 0.5;
	float cMax = 1.0 - texSize * 0.5;
	vec2 uv00 = clamp((base + vec2(0.5, 0.5)) * texSize, vec2(cMin), vec2(cMax));
	vec2 uv10 = clamp((base + vec2(1.5, 0.5)) * texSize, vec2(cMin), vec2(cMax));
	vec2 uv01 = clamp((base + vec2(0.5, 1.5)) * texSize, vec2(cMin), vec2(cMax));
	vec2 uv11 = clamp((base + vec2(1.5, 1.5)) * texSize, vec2(cMin), vec2(cMax));
	float rangeZ = uLightFar - uLightNear;
	float d00 = uLightNear + unpackDepth(texture2D(/* lod0 */uDepthBuffer, uv00)) * rangeZ;
	float d10 = uLightNear + unpackDepth(texture2D(/* lod0 */uDepthBuffer, uv10)) * rangeZ;
	float d01 = uLightNear + unpackDepth(texture2D(/* lod0 */uDepthBuffer, uv01)) * rangeZ;
	float d11 = uLightNear + unpackDepth(texture2D(/* lod0 */uDepthBuffer, uv11)) * rangeZ;
	float sr = max(softRange, 0.0005);
	float s00 = clamp((compareDepth - d00) / sr, 0.0, 1.0);
	float s10 = clamp((compareDepth - d10) / sr, 0.0, 1.0);
	float s01 = clamp((compareDepth - d01) / sr, 0.0, 1.0);
	float s11 = clamp((compareDepth - d11) / sr, 0.0, 1.0);
	return mix(mix(s00, s10, f.x), mix(s01, s11, f.x), f.y);
}

float sampleSpotTent3x3(vec2 uv, float texSize, float compareDepth, float softRange)
{
	float mapRes = 1.0 / texSize;
	vec2 st = uv * mapRes;
	vec2 cIdx = floor(st);
	vec2 u = st - cIdx;
	vec3 wx = vec3(0.5 * (1.0 - u.x) * (1.0 - u.x), 0.75 - (u.x - 0.5) * (u.x - 0.5), 0.5 * u.x * u.x);
	vec3 wy = vec3(0.5 * (1.0 - u.y) * (1.0 - u.y), 0.75 - (u.y - 0.5) * (u.y - 0.5), 0.5 * u.y * u.y);
	float cMin = texSize * 0.5;
	float cMax = 1.0 - texSize * 0.5;
	float ux0 = clamp((cIdx.x - 0.5) * texSize, cMin, cMax);
	float ux1 = clamp((cIdx.x + 0.5) * texSize, cMin, cMax);
	float ux2 = clamp((cIdx.x + 1.5) * texSize, cMin, cMax);
	float rangeZ = uLightFar - uLightNear;
	float sr = max(softRange, 0.0005);
	float acc = 0.0;
	for (int iy = 0; iy < 3; iy++)
	{
		float wyv = (iy == 0) ? wy.x : ((iy == 1) ? wy.y : wy.z);
		float uy = clamp((cIdx.y + float(iy) - 0.5) * texSize, cMin, cMax);
		float d0 = uLightNear + unpackDepth(texture2D(/* lod0 */uDepthBuffer, vec2(ux0, uy))) * rangeZ;
		float d1 = uLightNear + unpackDepth(texture2D(/* lod0 */uDepthBuffer, vec2(ux1, uy))) * rangeZ;
		float d2 = uLightNear + unpackDepth(texture2D(/* lod0 */uDepthBuffer, vec2(ux2, uy))) * rangeZ;
		float r0 = clamp((compareDepth - d0) / sr, 0.0, 1.0);
		float r1 = clamp((compareDepth - d1) / sr, 0.0, 1.0);
		float r2 = clamp((compareDepth - d2) / sr, 0.0, 1.0);
		acc += wyv * (wx.x * r0 + wx.y * r1 + wx.z * r2);
	}
	return acc;
}

float worldNoise(vec3 p)
{
	vec2 q = floor(p.xy * 16.0 + p.z * 7.31);
	return fract(52.9829189 * fract(dot(q, vec2(0.06711056, 0.00583715))));
}

float hash21Gobo(vec2 p)
{
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise2DGobo(vec2 p)
{
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21Gobo(i);
	float b = hash21Gobo(i + vec2(1.0, 0.0));
	float c = hash21Gobo(i + vec2(0.0, 1.0));
	float d = hash21Gobo(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

vec3 evalSpotGobo(vec2 uv)
{
	if (uGoboMode <= 0)
		return vec3(1.0);
	vec2 c = (uv - 0.5) * max(0.1, uGoboScale);
	float ca = cos(uGoboAngle);
	float sa = sin(uGoboAngle);
	vec2 ruv = vec2(c.x * ca - c.y * sa, c.x * sa + c.y * ca) + 0.5;
	if (uGoboMode == 1) // Window Blinds
	{
		float slats = smoothstep(0.28, 0.38, fract(ruv.y * 9.0)) * (1.0 - smoothstep(0.88, 0.96, fract(ruv.y * 9.0)));
		float vbar = smoothstep(0.025, 0.045, abs(ruv.x - 0.5));
		float frame = smoothstep(0.02, 0.05, ruv.x) * smoothstep(0.02, 0.05, 1.0 - ruv.x) * smoothstep(0.02, 0.05, ruv.y) * smoothstep(0.02, 0.05, 1.0 - ruv.y);
		return vec3(slats * vbar * frame);
	}
	else if (uGoboMode == 2) // Tree Canopy Leaves (swaying in wind)
	{
		vec2 w1 = vec2(sin(uGoboTime * 0.8), cos(uGoboTime * 0.6)) * 0.18;
		vec2 w2 = vec2(cos(uGoboTime * 1.1), sin(uGoboTime * 0.9)) * 0.12;
		float n = noise2DGobo(ruv * 5.0 + w1) * 0.6 + noise2DGobo(ruv * 11.0 - w2) * 0.4;
		return vec3(smoothstep(0.38, 0.62, n));
	}
	else if (uGoboMode == 3) // Animated Water Caustics
	{
		vec2 p1 = ruv * 6.0 + vec2(uGoboTime * 0.4, uGoboTime * 0.3);
		vec2 p2 = ruv * 6.5 - vec2(uGoboTime * 0.35, -uGoboTime * 0.45);
		float c1 = abs(noise2DGobo(p1) - 0.5);
		float c2 = abs(noise2DGobo(p2) - 0.5);
		float caust = pow(clamp(1.0 - min(c1, c2) * 3.2, 0.0, 1.0), 2.2);
		return vec3(0.25 + caust * 1.35);
	}
	else if (uGoboMode == 4) // Stained Glass Cathedral Window
	{
		vec2 cell = fract(ruv * 4.0);
		vec2 id = floor(ruv * 4.0);
		float lead = smoothstep(0.04, 0.09, cell.x) * smoothstep(0.04, 0.09, 1.0 - cell.x) * smoothstep(0.04, 0.09, cell.y) * smoothstep(0.04, 0.09, 1.0 - cell.y);
		float h = hash21Gobo(id);
		vec3 paneCol = 0.55 + 0.45 * cos(TAU * (h + vec3(0.0, 0.33, 0.67)));
		return paneCol * lead;
	}
	else if (uGoboMode == 5) // Soft Flashlight Cookie
	{
		float d = length(ruv - 0.5) * 2.0;
		float hotspot = exp(-d * d * 3.5);
		float ring = smoothstep(0.75, 0.88, d) * (1.0 - smoothstep(0.90, 1.0, d)) * 0.45;
		return vec3(clamp(hotspot + ring, 0.0, 1.0));
	}
	else if (uGoboMode == 6) // Custom Texture or Video Track
	{
		vec4 tex = texture2D(uGoboTexture, clamp(ruv, 0.0, 1.0));
		return tex.rgb * tex.a;
	}
	return vec3(1.0);
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

vec3 getMappedNormal(vec2 uv)
{
	vec3 N = normalize(vNormal);
	if (uUseNormalMap < 1 || vHasTangent < 0.5)
		return N;
	vec4 n = texture2D(uTextureNormal, uv);
	if (n.a < 0.01)
		return N;
	vec2 nxy = (n.xy * 2.0 - 1.0) * (uPbrNormalStrength * max(0.0, uPbrMatOverride.w));
	if (uPbrMatOverride.z < 0.5)
		nxy.y *= -1.0;
	float len2 = dot(nxy, nxy);
	float nz = (len2 < 0.999) ? sqrt(1.0 - len2) : 0.03;
	vec3 tn = normalize(vec3(nxy, nz));
	vec3 T = normalize(vTangent - dot(vTangent, N) * N);
	vec3 B = cross(T, N);
	return normalize(T * tn.x + B * tn.y + N * tn.z);
}

void getPbrMaterial(vec2 uv, out float roughness, out float metallic, out float f0, out vec3 metalTint, out float matEmissive, out float matSss, out float porosity, out float matAo)
{
	roughness = clamp(uRoughness, 0.02, 1.0);
	metallic = clamp(uMetallic, 0.0, 1.0);
	f0 = mix(0.04, 0.85, metallic);
	metalTint = vec3(1.0);
	matEmissive = 0.0;
	matSss = 0.0;
	porosity = 0.0;
	matAo = 1.0;
	
	if (uUseNormalMap > 0)
	{
		vec4 matCol = texture2D(uTextureMaterial, uv);
		vec4 nrmCol = texture2D(uTextureNormal, uv);
		if (uMaterialFormat == 2)
		{
			roughness = clamp(pow(1.0 - matCol.r, 2.0), 0.02, 1.0);
			float gByte = floor(matCol.g * 255.0 + 0.5);
			if (gByte < 229.5)
			{
				metallic = 0.0;
				f0 = clamp(matCol.g, 0.02, 0.90);
				metalTint = vec3(1.0);
				float bByte = floor(matCol.b * 255.0 + 0.5);
				if (bByte <= 64.5)
					porosity = bByte / 64.0;
				else
					matSss = (bByte - 65.0) / 190.0;
			}
			else if (gByte < 237.5)
			{
				metallic = 1.0;
				vec3 mF0 = vec3(0.56, 0.57, 0.58);
				if (gByte < 230.5) mF0 = vec3(0.56, 0.57, 0.58);
				else if (gByte < 231.5) mF0 = vec3(1.00, 0.71, 0.29);
				else if (gByte < 232.5) mF0 = vec3(0.91, 0.92, 0.92);
				else if (gByte < 233.5) mF0 = vec3(0.55, 0.56, 0.56);
				else if (gByte < 234.5) mF0 = vec3(0.95, 0.64, 0.54);
				else if (gByte < 235.5) mF0 = vec3(0.63, 0.62, 0.64);
				else if (gByte < 236.5) mF0 = vec3(0.67, 0.64, 0.58);
				else mF0 = vec3(0.95, 0.93, 0.88);
				f0 = dot(mF0, vec3(0.2126, 0.7152, 0.0722));
				metalTint = mF0 / max(f0, 0.001);
			}
			else
			{
				metallic = 1.0;
				f0 = 0.88;
				metalTint = vec3(1.0);
			}
			float aByte = floor(matCol.a * 255.0 + 0.5);
			matEmissive = (aByte < 254.5) ? ((aByte / 254.0) * max(0.0, uDefaultEmissive) * uPbrEmissiveStrength) : 0.0;
			if (nrmCol.a >= 0.01)
				matAo = mix(1.0, clamp(nrmCol.b, 0.0, 1.0), clamp(uPbrAoStrength, 0.0, 1.0));
		}
		else if (uMaterialFormat == 1)
		{
			roughness = clamp(1.0 - matCol.r, 0.02, 1.0);
			metallic = clamp(matCol.g, 0.0, 1.0);
			f0 = mix(0.04, 0.88, metallic);
			metalTint = vec3(1.0);
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
		metalTint = vec3(1.0);
	}
}

float evalPbrSpecular(vec3 N, vec3 V, vec3 L, float roughness, float metallic, float f0)
{
	float ndotl = max(dot(N, L), 0.0);
	float ndotv = max(dot(N, V), 0.001);
	if (ndotl <= 0.0)
		return 0.0;
	vec3 H = normalize(L + V);
	float ndoth = max(dot(N, H), 0.0);
	float vdoth = max(dot(V, H), 0.0);
	float a = clamp(roughness * roughness, 0.0004, 1.0);
	float a2 = a * a;
	float dDenom = ndoth * ndoth * (a2 - 1.0) + 1.0;
	float D = a2 / max(PI * dDenom * dDenom, 0.0001);
	float k = ((roughness + 1.0) * (roughness + 1.0)) * 0.125;
	float G = (ndotv / (ndotv * (1.0 - k) + k)) * (ndotl / (ndotl * (1.0 - k) + k));
	float fres = f0 + (1.0 - f0) * pow(clamp(1.0 - vdoth, 0.0, 1.0), 5.0);
	float brdf = (D * G * fres) / max(4.0 * ndotl * ndotv, 0.001);
	return clamp(brdf * ndotl, 0.0, 8.0);
}

void main()
{
	if (uIsSky < 1 && dot(uMirrorClipPlane.xyz, uMirrorClipPlane.xyz) > 0.25 && dot(vPosition, uMirrorClipPlane.xyz) + uMirrorClipPlane.w < -0.25)
		discard;
	vec3 light;
	vec2 uv = vTexCoord;
	
	if (uIsSky > 0)
		light = vec3(0.0);
	else
	{
		vec3 V = normalize(uCameraPosition - vPosition);
		uv = getPomUV(vTexCoord, V, vNormal, vTangent, vHasTangent);
		vec3 N = getMappedNormal(uv);
		float roughness, metallic, f0, matEmissive, matSss, porosity, matAo;
		vec3 metalTint;
		getPbrMaterial(uv, roughness, metallic, f0, metalTint, matEmissive, matSss, porosity, matAo);
		
		float bright = clamp(max(vBrightness, matEmissive), 0.0, 1.0);
		float bleedTotal = clamp((vLightBleed + uBleedLight + matSss) * uLightBleedStrength, 0.0, 1.0);
		float aoFactor = mix(pow(max(matAo, 0.001), 0.5), 1.0, bright);
		float diffuseScale = mix(1.0, 0.28, metallic);
		
		float dif = 0.0;
		float shadow = 0.0;
		float coneAtt = 0.0;
		vec3 goboMult = vec3(1.0);
		vec3 L = normalize(uLightPosition - vPosition);
		float ndotl = max(0.0, dot(N, L));
		
		// Check if not behind the spot light
		if (vScreenCoord.w > 0.0)
		{
			if (uWetness > 0.001 && normalize(vNormal).z > 0.65)
				roughness = mix(roughness, 0.08, clamp(uWetness * 0.85 * mix(0.45, 1.0, porosity), 0.0, 1.0));
			dif = clamp(ndotl + bleedTotal, 0.0, 1.0);
			if (uCelEnable > 0)
			{
				float steps = max(2.0, uCelSteps);
				float sc = dif * steps;
				dif = clamp((floor(sc) + smoothstep(0.5 - uCelSmooth * 0.48, 0.5 + uCelSmooth * 0.48, fract(sc))) / steps, 0.0, 1.0);
			}
			float distAtt = 1.0 - clamp((distance(vPosition, uLightPosition) - uLightFar * (1.0 - uLightFadeSize)) / max(0.0001, uLightFar * uLightFadeSize), 0.0, 1.0);
			dif *= distAtt;
			
			if (dif > 0.0 && bright < 1.0)
			{
				vec2 fragCoord = (vec2(vScreenCoord.x, -vScreenCoord.y) / max(0.0001, vScreenCoord.w) + 1.0) * 0.5;
				
				if (fragCoord.x > 0.0 && fragCoord.y > 0.0 && fragCoord.x < 1.0 && fragCoord.y < 1.0)
				{
					float blurSize = uBlurSize + (0.2 * bleedTotal);
					
					coneAtt = (1.0 - clamp((distance(fragCoord, vec2(0.5, 0.5)) - 0.5 * uLightSpotSharpness) / (0.5 * max(0.01, 1.0 - uLightSpotSharpness)), 0.0, 1.0)) * distAtt;
					dif *= 1.0 - clamp((distance(fragCoord, vec2(0.5, 0.5)) - 0.5 * uLightSpotSharpness) / (0.5 * max(0.01, 1.0 - uLightSpotSharpness)), 0.0, 1.0);
					if (uGoboMode > 0)
						goboMult = evalSpotGobo(fragCoord);
					
					vec3 Ng = normalize(vNormal);
					float cosTheta = clamp(dot(Ng, L), 0.0, 1.0);
					float sinTheta = sqrt(max(0.0, 1.0 - cosTheta * cosTheta));
					float tanTheta = min(sinTheta / max(cosTheta, 0.12), 5.5);
					float texSize = max(0.0001, uSpotShadowParams.x);
					float frustumScale = max(0.05, uSpotShadowParams.y);
					float rawW = max(0.1, vScreenCoord.w);
					float worldTexel = max(0.02, rawW * frustumScale * texSize);
					float biasScale = max(0.05, uShadowBias);
					float normalBiasWorld = (min(worldTexel, 0.55) * (0.95 + 1.55 * sinTheta) + 0.05) * biasScale;
					vec4 shadowWorldPos = vec4(vPosition + Ng * normalBiasWorld, 1.0);
					vec4 biasedCoord = uLightMatrix * shadowWorldPos;
					vec2 shadowCoord = (vec2(biasedCoord.x, -biasedCoord.y) / max(0.0001, biasedCoord.w) + 1.0) * 0.5;
					float fragDepth = min(biasedCoord.z, uLightFar);
					float baseBias = (worldTexel * 0.35 + 0.06) * biasScale;
					float softEdge = max(worldTexel * 0.25, 0.03);
					float filterUV = (blurSize > 0.001 && uBlurQuality > 1) ? min(blurSize / max(0.01, rawW * frustumScale), texSize * 18.0) : (texSize * 1.15);
					
					float tentBias = baseBias + (worldTexel * 0.85 * tanTheta) * biasScale;
					float tentSh = sampleSpotTent3x3(shadowCoord, texSize, fragDepth - tentBias, softEdge);
					if (uBlurQuality <= 1 || blurSize <= 0.001 || filterUV <= texSize * 1.35)
						shadow = tentSh;
					else
					{
						int q = clamp(uBlurQuality, 8, 24);
						float noiseAngle = worldNoise(vPosition) * GOLDEN_ANGLE * smoothstep(texSize * 7.0, texSize * 16.0, filterUV);
						float pcfSum = 0.0;
						for (int i = 0; i < 24; i++)
						{
							if (i >= q)
								break;
							vec2 pOff = vogelOffset(i, q, noiseAngle) * filterUV;
							float tapWorldRad = max(length(pOff) * rawW * frustumScale, worldTexel * 0.75);
							float tapBias = baseBias + (tapWorldRad * tanTheta * 0.95) * biasScale;
							pcfSum += sampleSpotBilinear(shadowCoord + pOff, texSize, fragDepth - tapBias, softEdge);
						}
						float pcfSh = pcfSum / float(q);
						shadow = mix(tentSh, pcfSh, smoothstep(texSize * 1.25, texSize * 2.15, filterUV));
					}
				}
				else
					dif = 0.0;
			}
		}
		
		float shadowAmt = clamp(shadow * uShadowDarkness, 0.0, 1.0);
		float volumeShadow = 0.0;
		if (uVolumeShadowCount > 0 && bright < 1.0 && coneAtt > 0.0 && shadowAmt < 1.0)
			volumeShadow = volumeShadowOpacity(vPosition, L, distance(vPosition, uLightPosition)) * clamp(uShadowDarkness, 0.0, 1.0);
		shadowAmt += (1.0 - shadowAmt) * volumeShadow;
		vec3 lightTint = uLightColor.rgb * goboMult;
		if (uBleedLight > 0.0 && ndotl < 0.25)
			lightTint = mix(lightTint, lightTint * uSubsurfaceColor.rgb, clamp(uBleedLight, 0.0, 1.0));
		
		if (uIsWater == 1)
			light = lightTint * uLightStrength * dif * (1.0 - volumeShadow);
		else
			light = lightTint * uLightStrength * dif * aoFactor * diffuseScale * (1.0 - shadowAmt);
		
		if (uSpecularEnable > 0 && uIsWater == 0 && shadowAmt < 0.99 && ndotl > 0.0 && coneAtt > 0.0)
		{
			float effRough = (uUseNormalMap > 0 && uMaterialFormat > 0 || uPbrMatOverride.x >= 0.0) ? roughness : clamp(1.0 - clamp(uSpecularShininess / 64.0, 0.0, 0.92), 0.06, 0.95);
			float specBrdf = evalPbrSpecular(N, V, L, effRough, metallic, f0);
			light += uLightColor.rgb * metalTint * uLightStrength * specBrdf * uSpecularStrength * coneAtt * (1.0 - shadowAmt);
		}
		
		light = mix(light, vec3(0.0), bright);
	}
	
	vec4 baseColor = texture2D(uTexture, uv);
	gl_FragColor = vec4(light, vColor.a * baseColor.a);
	
	if (baseColor.a < 0.05 || gl_FragColor.a < 0.01)
		discard;
}
