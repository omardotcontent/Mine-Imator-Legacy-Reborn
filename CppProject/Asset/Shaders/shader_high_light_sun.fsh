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
uniform float uLightNear; // static
uniform float uLightFar; // static

uniform sampler2D uDepthBuffer; // static
uniform sampler2D uDepthBufferNear; // static
uniform sampler2D uTransColorBuffer; // static
uniform int uNearShadowEnable; // static
uniform vec4 uNearLightParams; // static

uniform int uBlurQuality; // static
uniform float uBlurSize; // static
uniform float uShadowBias; // static
uniform float uShadowDarkness; // static
uniform vec4 uShadowTint; // static

uniform int uColoredShadows; // static
uniform float uColoredShadowsStrength; // static

uniform float uDiffuseBoost; // static
uniform float uLightBleedStrength; // static
uniform float uBleedLight;
uniform vec4 uSubsurfaceColor;

// Material & Normal Maps
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

// Enhanced 1.2.9 Lighting (toggleable)
uniform int uHemiEnable; // static
uniform float uHemiStrength; // static
uniform vec4 uHemiSkyColor; // static
uniform vec4 uHemiGroundColor; // static

uniform int uRimEnable; // static
uniform float uRimStrength; // static
uniform float uRimPower; // static
uniform vec4 uRimColor; // static

uniform int uSpecularEnable; // static
uniform float uSpecularStrength; // static
uniform float uSpecularShininess; // static

uniform int uCloudShadows; // static
uniform float uCloudShadowsStrength; // static
uniform float uCloudShadowsScale; // static
uniform vec3 uSunDir; // static

// Water Ripples & Wetness / Rain Puddles
uniform float uRippleTime; // static
uniform int uWaterRipples; // static
uniform float uWaterRippleStrength; // static
uniform float uWaterRippleSpeed; // static
uniform float uWetness; // static
uniform int uWetnessRipples; // static

// Anime / Toon Cel-Shading
uniform int uCelEnable; // static
uniform float uCelSteps; // static
uniform float uCelSmooth; // static

varying vec3 vPosition;
uniform vec4 uMirrorClipPlane; // static
varying vec3 vWorldPos;
varying vec3 vNormal;
varying vec3 vTangent;
varying float vHasTangent;
varying vec2 vTexCoord;
varying vec4 vColor;
varying vec4 vScreenCoord;
varying vec4 vLightNormalDir;
varying vec4 vNearScreenCoord;
varying vec4 vNearLightNormalDir;
varying vec4 vClipPos;
varying float vBrightness;
varying float vLightBleed;

uniform vec2 uScreenSize; // static
uniform float uShadowTexelSize; // static

#include "volume_medium.glsl"
#include "volume_shadow.glsl"
#include "sky_cloud_medium.glsl"

float unpackDepth(vec4 c)
{
	return c.r + c.g / 255.0 + c.b / (255.0 * 255.0);
}

float ignNoise(vec2 px)
{
	return fract(52.9829189 * fract(dot(px, vec2(0.06711056, 0.00583715))));
}

vec2 vogelOffset(int idx, int count, float phi)
{
	float r = sqrt((float(idx) + 0.5) / float(count));
	float theta = float(idx) * GOLDEN_ANGLE + phi;
	return vec2(cos(theta), sin(theta)) * r;
}

float sampleFarBilinear(vec2 uv, float texSize, float compareDepth, float softRange)
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

float sampleFarTent3x3(vec2 uv, float texSize, float compareDepth, float softRange)
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

float sampleNearBilinear(vec2 uv, float texSize, float nearZ, float farZ, float compareDepth, float softRange)
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
	float rangeZ = farZ - nearZ;
	float d00 = nearZ + unpackDepth(texture2D(/* lod0 */uDepthBufferNear, uv00)) * rangeZ;
	float d10 = nearZ + unpackDepth(texture2D(/* lod0 */uDepthBufferNear, uv10)) * rangeZ;
	float d01 = nearZ + unpackDepth(texture2D(/* lod0 */uDepthBufferNear, uv01)) * rangeZ;
	float d11 = nearZ + unpackDepth(texture2D(/* lod0 */uDepthBufferNear, uv11)) * rangeZ;
	float sr = max(softRange, 0.0005);
	float s00 = clamp((compareDepth - d00) / sr, 0.0, 1.0);
	float s10 = clamp((compareDepth - d10) / sr, 0.0, 1.0);
	float s01 = clamp((compareDepth - d01) / sr, 0.0, 1.0);
	float s11 = clamp((compareDepth - d11) / sr, 0.0, 1.0);
	return mix(mix(s00, s10, f.x), mix(s01, s11, f.x), f.y);
}

float sampleNearTent3x3(vec2 uv, float texSize, float nearZ, float farZ, float compareDepth, float softRange)
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
	float rangeZ = farZ - nearZ;
	float sr = max(softRange, 0.0005);
	float acc = 0.0;
	for (int iy = 0; iy < 3; iy++)
	{
		float wyv = (iy == 0) ? wy.x : ((iy == 1) ? wy.y : wy.z);
		float uy = clamp((cIdx.y + float(iy) - 0.5) * texSize, cMin, cMax);
		float d0 = nearZ + unpackDepth(texture2D(/* lod0 */uDepthBufferNear, vec2(ux0, uy))) * rangeZ;
		float d1 = nearZ + unpackDepth(texture2D(/* lod0 */uDepthBufferNear, vec2(ux1, uy))) * rangeZ;
		float d2 = nearZ + unpackDepth(texture2D(/* lod0 */uDepthBufferNear, vec2(ux2, uy))) * rangeZ;
		float r0 = clamp((compareDepth - d0) / sr, 0.0, 1.0);
		float r1 = clamp((compareDepth - d1) / sr, 0.0, 1.0);
		float r2 = clamp((compareDepth - d2) / sr, 0.0, 1.0);
		acc += wyv * (wx.x * r0 + wx.y * r1 + wx.z * r2);
	}
	return acc;
}

float evalSunFarShadow(vec4 screenCoord, vec4 lightNormalDir, float sinTheta, float tanTheta, float blurSize, vec2 screenPx)
{
	float rawW = max(0.1, screenCoord.w);
	float texSize = max(0.0001, uShadowTexelSize);
	float frustumScale = 0.828427;
	float worldTexel = max(0.02, rawW * frustumScale * texSize);
	float biasScale = max(0.05, uShadowBias);
	float normalBiasWorld = (min(worldTexel, 0.55) * (0.95 + 1.55 * sinTheta) + 0.05) * biasScale;
	vec4 biasedCoord = screenCoord + lightNormalDir * normalBiasWorld;
	vec2 fragCoord = (vec2(biasedCoord.x, -biasedCoord.y) / max(0.0001, biasedCoord.w) + 1.0) * 0.5;
	if (fragCoord.x <= 0.0 || fragCoord.y <= 0.0 || fragCoord.x >= 1.0 || fragCoord.y >= 1.0)
		return 0.0;
	
	float fragDepth = min(biasedCoord.z, uLightFar);
	float baseBias = (worldTexel * 0.35 + 0.08) * biasScale;
	float softEdge = max(worldTexel * 0.25, 0.04);
	
	if (uBlurQuality <= 1 || blurSize <= 0.001)
	{
		float tentBias = baseBias + (worldTexel * 0.85 * tanTheta) * biasScale;
		return sampleFarTent3x3(fragCoord, texSize, fragDepth - tentBias, softEdge);
	}
	
	float worldBlurMax = (1.15 * blurSize) * clamp(rawW / 2000.0, 0.5, 2.5);
	float maxSampleUV = min(worldBlurMax / max(0.01, rawW * frustumScale), texSize * 20.0);
	float searchRadius = max(texSize * 2.0, maxSampleUV * 1.05);
	float noiseVal = ignNoise(screenPx) * GOLDEN_ANGLE;
	float searchAngle = noiseVal * smoothstep(texSize * 7.0, texSize * 16.0, searchRadius);
	
	float blockerSum = 0.0;
	float blockerCount = 0.0;
	float rangeZ = uLightFar - uLightNear;
	for (int k = 0; k < 6; k++)
	{
		vec2 bOff = vogelOffset(k, 6, searchAngle) * searchRadius;
		float bWorldRad = max(length(bOff) * rawW * frustumScale, worldTexel * 0.90);
		float bBias = baseBias + (bWorldRad * tanTheta * 0.95) * biasScale;
		float bDepth = uLightNear + unpackDepth(texture2D(/* lod0 */uDepthBuffer, fragCoord + bOff)) * rangeZ;
		if ((fragDepth - bBias) > bDepth)
		{
			blockerSum += bDepth;
			blockerCount += 1.0;
		}
	}
	
	float filterUV = texSize * 1.15;
	if (blockerCount > 0.5)
	{
		float avgBlocker = blockerSum / blockerCount;
		float blockerDist = max(0.0, fragDepth - avgBlocker);
		float penumbra = clamp((blockerDist * (0.25 + 0.75 * max(blurSize, 0.5))) / 28.0, 0.14, 1.0);
		filterUV = max(texSize * 1.15, maxSampleUV * penumbra);
	}
	
	float tentBias = baseBias + (worldTexel * 0.85 * tanTheta) * biasScale;
	float tentSh = sampleFarTent3x3(fragCoord, texSize, fragDepth - tentBias, softEdge);
	if (filterUV <= texSize * 1.35)
		return tentSh;
	
	float filterAngle = noiseVal * smoothstep(texSize * 7.0, texSize * 16.0, filterUV);
	int pcfSamples = clamp(uBlurQuality, 8, 28);
	float pcfSum = 0.0;
	for (int j = 0; j < 28; j++)
	{
		if (j >= pcfSamples)
			break;
		vec2 pOff = vogelOffset(j, pcfSamples, filterAngle) * filterUV;
		float tapWorldRad = max(length(pOff) * rawW * frustumScale, worldTexel * 0.75);
		float tapBias = baseBias + (tapWorldRad * tanTheta * 0.95) * biasScale;
		pcfSum += sampleFarBilinear(fragCoord + pOff, texSize, fragDepth - tapBias, softEdge);
	}
	float pcfSh = pcfSum / float(pcfSamples);
	float blendT = smoothstep(texSize * 1.25, texSize * 2.15, filterUV);
	return mix(tentSh, pcfSh, blendT);
}

float evalSunNearShadow(vec4 screenCoord, vec4 lightNormalDir, vec2 fragCoord, float sinTheta, float tanTheta, float blurSize, vec2 screenPx, float normalBiasWorld)
{
	float nearZ = uNearLightParams.x;
	float farZ = uNearLightParams.y;
	float texSize = max(0.0001, uNearLightParams.z);
	float frustumScale = max(0.001, uNearLightParams.w);
	vec4 biasedCoord = screenCoord + lightNormalDir * normalBiasWorld;
	float rawW = max(0.1, screenCoord.w);
	float worldTexel = max(0.015, rawW * frustumScale * texSize);
	float biasScale = max(0.05, uShadowBias);
	float fragDepth = min(biasedCoord.z, farZ);
	float baseBias = (worldTexel * 0.30 + 0.05) * biasScale;
	float softEdge = max(worldTexel * 0.30, 0.03);
	
	if (uBlurQuality <= 1 || blurSize <= 0.001)
	{
		float tentBias = baseBias + (worldTexel * 0.80 * tanTheta) * biasScale;
		return sampleNearTent3x3(fragCoord, texSize, nearZ, farZ, fragDepth - tentBias, softEdge);
	}
	
	float worldBlurMax = (1.15 * blurSize) * clamp(rawW / 2000.0, 0.5, 2.5);
	float maxSampleUV = min(worldBlurMax / max(0.01, rawW * frustumScale), texSize * 20.0);
	float searchRadius = max(texSize * 2.0, maxSampleUV * 1.05);
	float noiseVal = ignNoise(screenPx) * GOLDEN_ANGLE;
	float searchAngle = noiseVal * smoothstep(texSize * 7.0, texSize * 16.0, searchRadius);
	
	float blockerSum = 0.0;
	float blockerCount = 0.0;
	float rangeZ = farZ - nearZ;
	for (int k = 0; k < 6; k++)
	{
		vec2 bOff = vogelOffset(k, 6, searchAngle) * searchRadius;
		float bWorldRad = max(length(bOff) * rawW * frustumScale, worldTexel * 0.90);
		float bBias = baseBias + (bWorldRad * tanTheta * 0.95) * biasScale;
		float bDepth = nearZ + unpackDepth(texture2D(/* lod0 */uDepthBufferNear, fragCoord + bOff)) * rangeZ;
		if ((fragDepth - bBias) > bDepth)
		{
			blockerSum += bDepth;
			blockerCount += 1.0;
		}
	}
	
	float filterUV = texSize * 1.15;
	if (blockerCount > 0.5)
	{
		float avgBlocker = blockerSum / blockerCount;
		float blockerDist = max(0.0, fragDepth - avgBlocker);
		float penumbra = clamp((blockerDist * (0.25 + 0.75 * max(blurSize, 0.5))) / 28.0, 0.14, 1.0);
		filterUV = max(texSize * 1.15, maxSampleUV * penumbra);
	}
	
	float tentBias = baseBias + (worldTexel * 0.80 * tanTheta) * biasScale;
	float tentSh = sampleNearTent3x3(fragCoord, texSize, nearZ, farZ, fragDepth - tentBias, softEdge);
	if (filterUV <= texSize * 1.35)
		return tentSh;
	
	float filterAngle = noiseVal * smoothstep(texSize * 7.0, texSize * 16.0, filterUV);
	int pcfSamples = clamp(uBlurQuality, 8, 28);
	float pcfSum = 0.0;
	for (int j = 0; j < 28; j++)
	{
		if (j >= pcfSamples)
			break;
		vec2 pOff = vogelOffset(j, pcfSamples, filterAngle) * filterUV;
		float tapWorldRad = max(length(pOff) * rawW * frustumScale, worldTexel * 0.75);
		float tapBias = baseBias + (tapWorldRad * tanTheta * 0.95) * biasScale;
		pcfSum += sampleNearBilinear(fragCoord + pOff, texSize, nearZ, farZ, fragDepth - tapBias, softEdge);
	}
	float pcfSh = pcfSum / float(pcfSamples);
	float blendT = smoothstep(texSize * 1.25, texSize * 2.15, filterUV);
	return mix(tentSh, pcfSh, blendT);
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

float getCloudShadowFactor(vec3 wp)
{
	if (uCloudShadows < 1 || uCloudShadowsStrength <= 0.0 || uSunDir.z <= 0.05 || uCloudTileSize <= 1.0)
		return 0.0;

	float sunFade = smoothstep(0.05, 0.22, uSunDir.z);
	if (uCloudShadows == 2)
	{
		float softness = max(uCloudThickness, uCloudTileSize * 0.0015) * clamp(uCloudShadowsScale, 0.25, 4.0);
		float transmission = skyCloudSunTransmission(wp, uSunDir, 6, softness);
		return (1.0 - transmission) * uCloudShadowsStrength * sunFade;
	}
	
	// Exact intersection of sun ray from world point wp with cloud plane z = uCloudHeight
	float tHit = max(0.0, (uCloudHeight - wp.z) / max(0.08, uSunDir.z));
	vec2 cloudPos = wp.xy + uSunDir.xy * tHit;
	
	// Exact tile UV matching background_sky_update.gml: xo = k*size, yo = k*size - offset
	vec2 baseUV = vec2(cloudPos.x / uCloudTileSize, (cloudPos.y + uCloudOffset) / uCloudTileSize);
	
	// Soft penumbra filter radius controlled by uCloudShadowsScale (default 1.0 = natural soft cloud edge)
	float blur = 0.0045 * clamp(uCloudShadowsScale, 0.1, 4.0);
	float acc = 0.0;
	acc += texture2D(uCloudTexture, baseUV).a * 0.24;
	acc += texture2D(uCloudTexture, baseUV + vec2( blur,  0.0)).a * 0.11;
	acc += texture2D(uCloudTexture, baseUV + vec2(-blur,  0.0)).a * 0.11;
	acc += texture2D(uCloudTexture, baseUV + vec2( 0.0,  blur)).a * 0.11;
	acc += texture2D(uCloudTexture, baseUV + vec2( 0.0, -blur)).a * 0.11;
	acc += texture2D(uCloudTexture, baseUV + vec2( blur * 0.7,  blur * 0.7)).a * 0.08;
	acc += texture2D(uCloudTexture, baseUV + vec2(-blur * 0.7,  blur * 0.7)).a * 0.08;
	acc += texture2D(uCloudTexture, baseUV + vec2( blur * 0.7, -blur * 0.7)).a * 0.08;
	acc += texture2D(uCloudTexture, baseUV + vec2(-blur * 0.7, -blur * 0.7)).a * 0.08;
	
	// Fade out smoothly when sun is very low on horizon
	return clamp(acc, 0.0, 1.0) * uCloudShadowsStrength * sunFade;
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

float getPomSelfShadow(vec2 uv, vec3 lightDir, vec3 geomN, vec3 geomT, float hasT)
{
	if (uUseNormalMap < 1 || uPbrPomEnable < 1 || hasT < 0.5 || uPbrPomDepth <= 0.0001)
		return 0.0;
	if (texture2D(/* lod0 */uTexture, uv).a < 0.5)
		return 0.0;
	float h0 = texture2D(/* lod0 */uTextureNormal, uv).a;
	if (h0 < 0.005 || h0 >= 0.996)
		return 0.0;
	vec3 N = normalize(geomN);
	float ndotl = dot(lightDir, N);
	if (ndotl <= 0.05)
		return 0.0;
	vec3 T = normalize(geomT - dot(geomT, N) * N);
	vec3 Bv = cross(N, T);
	bool clampToTile = (uPbrTileGrid.x > 1.5 || uPbrTileGrid.y > 1.5);
	vec2 gridAbs = max(vec2(1.0), abs(uPbrTileGrid));
	vec2 tileIdx = floor(uv * gridAbs);
	vec2 tileMin = tileIdx / gridAbs;
	vec2 tileMax = (tileIdx + 1.0) / gridAbs;
	float currLayerDepth = 1.0 - h0;
	if (currLayerDepth <= 0.01)
		return 0.0;
	vec2 lightTS = vec2(dot(lightDir, T), dot(lightDir, Bv)) / (ndotl + 0.45);
	vec2 rayOffset = lightTS * (uPbrPomDepth / gridAbs);
	const int shadowSteps = 6;
	float stepDepth = currLayerDepth / float(shadowSteps);
	vec2 uvStep = rayOffset * stepDepth;
	float occlusion = 0.0;
	float marchDepth = currLayerDepth;
	for (int s = 1; s <= 6; s++)
	{
		marchDepth -= stepDepth;
		vec2 sampleUV = clampTileUV(uv + uvStep * float(s), tileMin, tileMax, gridAbs, clampToTile);
		float sAlpha = texture2D(/* lod0 */uTexture, sampleUV).a;
		float sh = texture2D(/* lod0 */uTextureNormal, sampleUV).a;
		if (sAlpha < 0.5 || sh < 0.005)
			break;
		float sDepth = 1.0 - sh;
		float diff = marchDepth - sDepth;
		if (diff > 0.0)
			occlusion = max(occlusion, clamp(diff * 3.5, 0.0, 0.85));
	}
	return occlusion;
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

float applyCel(float d)
{
	if (uCelEnable < 1)
		return d;
	float steps = max(2.0, uCelSteps);
	float scaled = d * steps;
	float band = floor(scaled);
	float fracPart = fract(scaled);
	float edge = smoothstep(0.5 - uCelSmooth * 0.48, 0.5 + uCelSmooth * 0.48, fracPart);
	return clamp((band + edge) / steps, 0.0, 1.0);
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
		if (uMaterialFormat == 2) // LabPBR 1.3
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
		else if (uMaterialFormat == 1) // SEUS
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
	if (uIsSky < 1 && dot(uMirrorClipPlane.xyz, uMirrorClipPlane.xyz) > 0.25 && dot(vWorldPos, uMirrorClipPlane.xyz) + uMirrorClipPlane.w < -0.25)
		discard;
	vec3 light;
	vec2 uv = vTexCoord;
	
	if (uIsSky > 0)
		light = vec3(1.0);
	else
	{
		vec3 V = normalize(uCameraPosition - vWorldPos);
		uv = getPomUV(vTexCoord, V, vNormal, vTangent, vHasTangent);
		float upMask = smoothstep(0.60, 0.85, normalize(vNormal).z);
		float wetMask = (uWetness > 0.001) ? (puddleMask(vWorldPos.xy) * upMask * uWetness) : 0.0;
		
		vec3 N = getMappedNormal(uv, wetMask);
		float roughness, metallic, f0, matEmissive, matSss, porosity, matAo;
		vec3 metalTint;
		getPbrMaterial(uv, roughness, metallic, f0, metalTint, matEmissive, matSss, porosity, matAo);
		
		// Wetness makes puddles glossy & low-roughness
		if (wetMask > 0.001)
			roughness = mix(roughness, 0.06, clamp(wetMask * mix(0.45, 1.0, porosity), 0.0, 1.0));
		if (uIsWater > 0)
		{
			roughness = 0.08;
			f0 = 0.02;
		}
		
		float bright = clamp(max(vBrightness, matEmissive), 0.0, 1.0);
		float bleedTotal = clamp((vLightBleed + uBleedLight + matSss) * uLightBleedStrength, 0.0, 1.0);
		float aoFactor = mix(pow(max(matAo, 0.001), 0.5), 1.0, bright);
		float diffuseScale = mix(1.0, 0.28, metallic);
		
		vec3 L = normalize(uLightPosition - vPosition);
		
		// Diffuse factor (+ optional Cel-Shading quantization)
		float ndotl = max(0.0, dot(N, L));
		float dif = applyCel(clamp(ndotl + bleedTotal, 0.0, 1.0));
		
		float shadow = 0.0;
		vec3 transTint = vec3(1.0);
		
		if (dif > 0.0 && bright < 1.0)
		{
			dif *= uDiffuseBoost;
			
			vec3 Ng = normalize(vNormal);
			float cosTheta = clamp(dot(Ng, L), 0.0, 1.0);
			float sinTheta = sqrt(max(0.0, 1.0 - cosTheta * cosTheta));
			float tanTheta = min(sinTheta / max(cosTheta, 0.12), 5.5);
			vec2 screenUV = (vClipPos.xy / max(abs(vClipPos.w), 0.0001)) * 0.5 + 0.5;
			vec2 screenPx = screenUV * max(uScreenSize, vec2(1.0, 1.0));
			float blurSize = uBlurSize + (0.2 * bleedTotal);
			
			bool usedNear = false;
			if (uNearShadowEnable > 0 && vNearScreenCoord.w > 0.1)
			{
				float nearWorldTexel = max(0.015, max(0.1, vNearScreenCoord.w) * max(0.001, uNearLightParams.w) * max(0.0001, uNearLightParams.z));
				float nearNormalBias = (nearWorldTexel * (0.95 + 1.55 * sinTheta) + 0.05) * max(0.05, uShadowBias);
				vec4 nearBiased = vNearScreenCoord + vNearLightNormalDir * nearNormalBias;
				vec2 nearUV = (vec2(nearBiased.x, -nearBiased.y) / max(0.0001, nearBiased.w) + 1.0) * 0.5;
				float nearEdge = max(abs(nearUV.x - 0.5), abs(nearUV.y - 0.5));
				if (nearEdge < 0.47 && nearBiased.z > uNearLightParams.x && nearBiased.z < uNearLightParams.y)
				{
					float nearSh = evalSunNearShadow(vNearScreenCoord, vNearLightNormalDir, nearUV, sinTheta, tanTheta, blurSize, screenPx, nearNormalBias);
					if (nearEdge < 0.38)
						shadow = nearSh;
					else
					{
						float farSh = evalSunFarShadow(vScreenCoord, vLightNormalDir, sinTheta, tanTheta, blurSize, screenPx);
						shadow = mix(nearSh, farSh, smoothstep(0.38, 0.47, nearEdge));
					}
					usedNear = true;
				}
			}
			if (!usedNear)
				shadow = evalSunFarShadow(vScreenCoord, vLightNormalDir, sinTheta, tanTheta, blurSize, screenPx);
			
			// Stained Glass / Translucent Colored Shadows
			if (uColoredShadows > 0 && shadow < 0.99)
			{
				vec2 colUV = (vec2(vScreenCoord.x, -vScreenCoord.y) / max(0.0001, vScreenCoord.w) + 1.0) * 0.5;
				if (colUV.x > 0.0 && colUV.y > 0.0 && colUV.x < 1.0 && colUV.y < 1.0)
				{
					vec3 tc = texture2D(/* lod0 */uTransColorBuffer, colUV).rgb;
					transTint = mix(vec3(1.0), tc, clamp(uColoredShadowsStrength, 0.0, 2.0));
				}
			}
		}
		
		// Cloud Shadows & POM relief self-shadowing
		float cloudSh = getCloudShadowFactor(vWorldPos);
		float pomSh = (uIsWater < 1 && bright < 1.0) ? getPomSelfShadow(uv, L, vNormal, vTangent, vHasTangent) : 0.0;
		float shadowAmt = clamp(max(max(shadow * uShadowDarkness, cloudSh), pomSh * uShadowDarkness), 0.0, 1.0);
		float volumeShadow = 0.0;
		if (uVolumeShadowCount > 0 && bright < 1.0 && (dif > 0.0 || ndotl > 0.0) && shadowAmt < 1.0)
			volumeShadow = volumeShadowOpacity(vWorldPos, uSunDir, 1e8) * clamp(uShadowDarkness, 0.0, 1.0);
		shadowAmt += (1.0 - shadowAmt) * volumeShadow;
		
		// Subsurface tint for light-bleeding objects
		vec3 sunTint = uLightColor.rgb * transTint;
		if (uBleedLight > 0.0 && ndotl < 0.25)
			sunTint = mix(sunTint, sunTint * uSubsurfaceColor.rgb, clamp(uBleedLight, 0.0, 1.0));
		
		// Calculate primary sun light
		if (uIsWater == 1)
			light = sunTint * dif * (1.0 - cloudSh * 0.6) * (1.0 - volumeShadow);
		else
			light = sunTint * dif * aoFactor * diffuseScale * (1.0 - shadowAmt) + uShadowTint.rgb * shadowAmt * aoFactor;
		
		// GGX Microfacet + Schlick Fresnel Specular
		bool doSpec = (uSpecularEnable > 0) || (wetMask > 0.05) || (uIsWater > 0 && uWaterRipples > 0);
		if (doSpec && shadowAmt < 0.99 && ndotl > 0.0)
		{
			float effRough = (uUseNormalMap > 0 && uMaterialFormat > 0 || uPbrMatOverride.x >= 0.0) ? roughness : clamp(1.0 - clamp(uSpecularShininess / 64.0, 0.0, 0.92), 0.06, 0.95);
			float specStr = (uSpecularEnable > 0) ? uSpecularStrength : 0.0;
			if (wetMask > 0.05)
				specStr = max(specStr, wetMask * 0.85);
			if (uIsWater > 0 && uWaterRipples > 0)
				specStr = max(specStr, 0.90);
			float specBrdf = evalPbrSpecular(N, V, L, effRough, metallic, f0);
			light += sunTint * metalTint * specBrdf * specStr * (1.0 - shadowAmt) * uDiffuseBoost;
		}
		
		// Hemisphere Sky/Ground Ambient lift
		if (uHemiEnable > 0)
		{
			float hemiFactor = clamp(N.z * 0.5 + 0.5, 0.0, 1.0);
			vec3 hemi = mix(uHemiGroundColor.rgb, uHemiSkyColor.rgb, hemiFactor) * uHemiStrength * aoFactor;
			light += hemi;
		}
		
		// Rim / Fresnel Backlight
		if (uRimEnable > 0)
		{
			float rim = pow(1.0 - clamp(dot(N, V), 0.0, 1.0), uRimPower) * uRimStrength * aoFactor;
			light += uRimColor.rgb * rim * (1.0 - shadowAmt * 0.65);
		}
		
		light = mix(light, vec3(1.0), bright);
	}
	
	vec4 baseColor = texture2D(uTexture, uv);
	gl_FragColor = vec4(light, vColor.a * baseColor.a);
	
	if (baseColor.a < 0.05 || gl_FragColor.a < 0.01)
		discard;
}
