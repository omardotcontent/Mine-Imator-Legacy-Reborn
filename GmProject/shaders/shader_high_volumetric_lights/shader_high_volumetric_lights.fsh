#define MAXLIGHTS 16
#define MAXSTEPS 64

varying vec2 vTexCoord;

uniform sampler2D uDepthBuffer;
uniform sampler2D uSunDepthBuffer;
uniform sampler2D uSpotDepthBuffer;

uniform vec2 uScreenSize;
uniform float uNear;
uniform float uFar;
uniform mat4 uProjMatrixInv;

uniform int uLightCount;
uniform int uSteps;
uniform float uIntensity;
uniform float uSpotDensity;
uniform float uPointRadius;
uniform float uTime;
uniform mat4 uViewMatrixInv;
uniform vec4 uVolumeAmbient;

uniform int uSunShadowEnable;
uniform float uSunShadowTexel;
uniform mat4 uSunLightMatrix;
uniform float uSunLightNear;
uniform float uSunLightFar;
uniform vec3 uSunLightDir;
uniform vec4 uSunLightColor;

uniform int uSpotShadowEnable;
uniform int uSpotShadowIndex;
uniform mat4 uSpotLightMatrix;
uniform float uSpotLightNear;
uniform float uSpotLightFar;
uniform float uSpotShadowTexel;
uniform vec4 uVolumeWind;

uniform vec4 uLightData[64];
uniform vec4 uVolumeXform[64];

float hash31Vol(vec3 p)
{
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.x + p.y) * p.z);
}

float noise3DVol(vec3 p)
{
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash31Vol(i);
	float n100 = hash31Vol(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash31Vol(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash31Vol(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash31Vol(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash31Vol(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash31Vol(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash31Vol(i + vec3(1.0, 1.0, 1.0));
	return mix(mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y),
	           mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y), f.z);
}

float fbm3DVol(vec3 p, float noiseSoft)
{
	float w0 = mix(0.62, 0.82, noiseSoft);
	float w1 = 1.0 - w0;
	return w0 * noise3DVol(p) + w1 * noise3DVol(p * 2.13 + vec3(17.1, 31.7, 11.3));
}

float unpackDepth(vec4 c)
{
	if (c.a < 0.99)
		return 1.0;
	return c.r + c.g / 255.0 + c.b / (255.0 * 255.0);
}

float unpackSunDepth(vec4 c)
{
	return c.r + c.g / 255.0 + c.b / (255.0 * 255.0);
}

float transformDepth(float depth)
{
	return (uFar - (uNear * uFar) / (depth * (uFar - uNear) + uNear)) / (uFar - uNear);
}

vec3 posFromBuffer(vec2 coord, float depth)
{
	vec4 pos = uProjMatrixInv * vec4(coord.x * 2.0 - 1.0, 1.0 - coord.y * 2.0, transformDepth(depth), 1.0);
	return pos.xyz / pos.w;
}

float screenJitter(vec2 px)
{
	return fract(52.9829189 * fract(dot(px, vec2(0.06711056, 0.00583715))));
}

float evalSunVisibility(vec3 worldP)
{
	if (uSunShadowEnable < 1)
		return 1.0;
	vec4 sunSc = uSunLightMatrix * vec4(worldP, 1.0);
	if (sunSc.z <= uSunLightNear || sunSc.z >= uSunLightFar)
		return 1.0;
	vec2 sunUV = (vec2(sunSc.x, -sunSc.y) / max(0.0001, sunSc.z) + 1.0) * 0.5;
	if (sunUV.x <= 0.0 || sunUV.x >= 1.0 || sunUV.y <= 0.0 || sunUV.y >= 1.0)
		return 1.0;
	float r = max(uSunShadowTexel, 0.0002) * 0.75;
	float rangeZ = uSunLightFar - uSunLightNear;
	float cmpZ = sunSc.z - 4.0;
	float d0 = uSunLightNear + unpackSunDepth(texture2D(/* lod0 */uSunDepthBuffer, clamp(sunUV + vec2(-r, -0.5 * r), vec2(0.0), vec2(1.0)))) * rangeZ;
	float d1 = uSunLightNear + unpackSunDepth(texture2D(/* lod0 */uSunDepthBuffer, clamp(sunUV + vec2( 0.5 * r, -r), vec2(0.0), vec2(1.0)))) * rangeZ;
	float d2 = uSunLightNear + unpackSunDepth(texture2D(/* lod0 */uSunDepthBuffer, clamp(sunUV + vec2( r,  0.5 * r), vec2(0.0), vec2(1.0)))) * rangeZ;
	float d3 = uSunLightNear + unpackSunDepth(texture2D(/* lod0 */uSunDepthBuffer, clamp(sunUV + vec2(-0.5 * r,  r), vec2(0.0), vec2(1.0)))) * rangeZ;
	float vis = 0.0;
	vis += (cmpZ <= d0) ? 0.25 : 0.0;
	vis += (cmpZ <= d1) ? 0.25 : 0.0;
	vis += (cmpZ <= d2) ? 0.25 : 0.0;
	vis += (cmpZ <= d3) ? 0.25 : 0.0;
	return vis;
}

float evalSpotVisibility(vec3 worldP)
{
	if (uSpotShadowEnable < 1)
		return 1.0;
	vec4 spSc = uSpotLightMatrix * vec4(worldP, 1.0);
	if (spSc.w <= 0.001 || spSc.z <= uSpotLightNear || spSc.z >= uSpotLightFar)
		return 1.0;
	vec2 spUV = (vec2(spSc.x, -spSc.y) / max(0.0001, spSc.w) + 1.0) * 0.5;
	if (spUV.x <= 0.0 || spUV.x >= 1.0 || spUV.y <= 0.0 || spUV.y >= 1.0)
		return 1.0;
	float r = max(uSpotShadowTexel, 0.0002) * 0.75;
	float rangeZ = max(0.0001, uSpotLightFar - uSpotLightNear);
	float cmpZ = spSc.z - 1.25;
	float d0 = uSpotLightNear + unpackSunDepth(texture2D(/* lod0 */uSpotDepthBuffer, clamp(spUV + vec2(-r, -0.5 * r), vec2(0.0), vec2(1.0)))) * rangeZ;
	float d1 = uSpotLightNear + unpackSunDepth(texture2D(/* lod0 */uSpotDepthBuffer, clamp(spUV + vec2( 0.5 * r, -r), vec2(0.0), vec2(1.0)))) * rangeZ;
	float d2 = uSpotLightNear + unpackSunDepth(texture2D(/* lod0 */uSpotDepthBuffer, clamp(spUV + vec2( r,  0.5 * r), vec2(0.0), vec2(1.0)))) * rangeZ;
	float d3 = uSpotLightNear + unpackSunDepth(texture2D(/* lod0 */uSpotDepthBuffer, clamp(spUV + vec2(-0.5 * r,  r), vec2(0.0), vec2(1.0)))) * rangeZ;
	float vis = 0.0;
	vis += (cmpZ <= d0) ? 0.25 : 0.0;
	vis += (cmpZ <= d1) ? 0.25 : 0.0;
	vis += (cmpZ <= d2) ? 0.25 : 0.0;
	vis += (cmpZ <= d3) ? 0.25 : 0.0;
	return vis;
}

// Evaluate lighting scattered from all Point, Spot, and Emit lights at a sample inside a Volume
vec3 evalInVolumeLights(vec3 sampleView, vec3 worldP, vec3 rayDir, int lcount)
{
	vec3 scatter = vec3(0.0);
	for (int k = 0; k < MAXLIGHTS; k++)
	{
		if (k >= lcount)
			break;
		vec4 kd2 = uLightData[k * 4 + 2];
		if (kd2.w > 1.5)
			continue;

		vec4 kd0 = uLightData[k * 4];
		vec4 kd1 = uLightData[k * 4 + 1];
		vec4 kd3 = uLightData[k * 4 + 3];

		vec3 toSample = sampleView - kd0.xyz;
		float dist = length(toSample);
		float lRange = max(1.0, kd0.w);
		if (dist < lRange)
		{
			float normDist = dist / lRange;
			float fadeSize = clamp(kd3.y, 0.02, 1.0);
			float atten = 1.0 - smoothstep(1.0 - fadeSize, 1.0, normDist);
			atten *= 1.0 / (1.0 + normDist * normDist * 2.2);

			vec3 lightToSample = toSample / max(0.0001, dist);

			if (kd2.w >= -0.5)
			{
				float cosOuter = kd2.w;
				float cosInner = mix(cosOuter, 0.9995, clamp(kd3.x, 0.05, 0.95));
				float cosAng = dot(lightToSample, kd2.xyz);
				float coneW = smoothstep(cosOuter, cosInner, cosAng);
				atten *= coneW;
				if (k == uSpotShadowIndex && uSpotShadowEnable > 0 && atten > 0.0005)
					atten *= evalSpotVisibility(worldP);
			}

			if (atten > 0.0005)
			{
				float cosTheta = dot(rayDir, -lightToSample);
				float phase = 0.72 + 0.65 * pow(clamp(cosTheta * 0.5 + 0.5, 0.0, 1.0), 2.2);
				scatter += kd1.rgb * kd1.w * atten * phase * 2.3;
			}
		}
	}
	return scatter;
}

void main()
{
	if (uLightCount <= 0 || uIntensity <= 0.001)
	{
		gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
		return;
	}
	
	float rawDepth = unpackDepth(texture2D(uDepthBuffer, vTexCoord));
	vec3 endPos = posFromBuffer(vTexCoord, rawDepth);
	float maxRayDist = length(endPos);
	vec3 rayDir = endPos / max(0.0001, maxRayDist);
	
	int lcount = clamp(uLightCount, 0, MAXLIGHTS);
	int steps = clamp(uSteps, 8, MAXSTEPS);
	float jitter = screenJitter(vTexCoord * max(uScreenSize, vec2(1.0, 1.0)));

	vec3 viewRayW = normalize((uViewMatrixInv * vec4(rayDir, 0.0)).xyz);
	float sunCos = dot(viewRayW, normalize(uSunLightDir));
	float sunPhase = 0.55 + 0.85 * pow(clamp(sunCos * 0.5 + 0.5, 0.0, 1.0), 3.0);
	
	vec3 volAccum = vec3(0.0);
	
	for (int l = 0; l < MAXLIGHTS; l++)
	{
		if (l >= lcount)
			break;
		
		vec4 d2 = uLightData[l * 4 + 2];
		float typeCode = d2.w;
		if (typeCode <= 1.5)
			continue;
		
		vec4 d1 = uLightData[l * 4 + 1];
		vec4 d3 = uLightData[l * 4 + 3];
		vec3 volCol = d1.rgb;
		float volDensity = d1.w;
		
		vec4 vx0 = uVolumeXform[l * 4];
		vec4 vx1 = uVolumeXform[l * 4 + 1];
		vec4 vx2 = uVolumeXform[l * 4 + 2];
		vec4 vx3 = uVolumeXform[l * 4 + 3];
		float shapeType = vx3.x;
		float edgeSoft = clamp(vx3.y, 0.0, 1.0);
		float noiseSoft = clamp(vx3.z, 0.0, 1.0);

		vec3 rayOrigL = vec3(vx0.w, vx1.w, vx2.w);
		vec3 rayDirL = vec3(dot(vx0.xyz, rayDir), dot(vx1.xyz, rayDir), dot(vx2.xyz, rayDir));
		vec3 safeDirL = vec3(
			abs(rayDirL.x) < 1e-5 ? (rayDirL.x < 0.0 ? -1e-5 : 1e-5) : rayDirL.x,
			abs(rayDirL.y) < 1e-5 ? (rayDirL.y < 0.0 ? -1e-5 : 1e-5) : rayDirL.y,
			abs(rayDirL.z) < 1e-5 ? (rayDirL.z < 0.0 ? -1e-5 : 1e-5) : rayDirL.z
		);
		vec3 t0 = (-vec3(1.0) - rayOrigL) / safeDirL;
		vec3 t1 = ( vec3(1.0) - rayOrigL) / safeDirL;
		vec3 tMinV = min(t0, t1);
		vec3 tMaxV = max(t0, t1);
		float tEnter = max(max(tMinV.x, tMinV.y), tMinV.z);
		float tExit  = min(min(tMaxV.x, tMaxV.y), tMaxV.z);

		float tStart = max(uNear, tEnter);
		float tEnd = min(maxRayDist, tExit);
		if (tEnd > tStart)
		{
			float segLen = tEnd - tStart;
			float stepLen = segLen / float(steps);
			float noiseScale = max(0.1, d3.z) * 0.035;
			float windSpd = d3.w;
			vec3 windVel = uVolumeWind.xyz * windSpd;

			float innerEdge = mix(0.985, 0.04, edgeSoft);
			float zInnerEdge = mix(0.985, 0.12, edgeSoft);
			float edgePower = mix(0.65, 1.85, edgeSoft);

			vec3 baseAmb = (typeCode > 3.5) ? max(uVolumeAmbient.rgb, vec3(0.75)) : uVolumeAmbient.rgb;
			vec3 volSum = vec3(0.0);
			float transmittance = 1.0;

			for (int s = 0; s < MAXSTEPS; s++)
			{
				if (s >= steps)
					break;
				float t = tStart + stepLen * (float(s) + jitter);
				vec3 localP = rayOrigL + rayDirL * t;
				float shapeMask = 0.0;
				if (shapeType < 0.5)
				{
					vec3 edge = smoothstep(vec3(1.0), vec3(innerEdge), abs(localP));
					shapeMask = edge.x * edge.y * edge.z;
				}
				else if (shapeType < 1.5)
				{
					shapeMask = smoothstep(1.0, innerEdge, length(localP));
				}
				else if (shapeType < 2.5)
				{
					shapeMask = smoothstep(1.0, innerEdge, length(localP.xy)) * smoothstep(1.0, zInnerEdge, abs(localP.z));
				}
				else
				{
					float coneR = mix(1.0, 0.05, clamp((localP.z + 1.0) * 0.5, 0.0, 1.0));
					shapeMask = smoothstep(coneR, coneR * innerEdge, length(localP.xy)) * smoothstep(1.0, zInnerEdge, abs(localP.z));
				}

				if (shapeMask > 0.001)
				{
					shapeMask = pow(shapeMask, edgePower);
					vec3 sampleView = rayDir * t;
					vec3 worldP = (uViewMatrixInv * vec4(sampleView, 1.0)).xyz;
					float n = fbm3DVol(worldP * noiseScale + windVel, noiseSoft);

					float mediumDens = 0.0;
					if (typeCode < 2.5)
					{
						float nLo = mix(0.32, 0.04, noiseSoft);
						float nHi = mix(0.72, 0.96, noiseSoft);
						float nVal = mix(smoothstep(nLo, nHi, n), 0.72, noiseSoft * 0.55);
						mediumDens = shapeMask * nVal * stepLen * 0.018;
					}
					else if (typeCode < 3.5)
					{
						float cLo = mix(0.46, 0.14, noiseSoft);
						float cHi = mix(0.64, 0.90, noiseSoft);
						float nBlend = mix(n, 0.72, noiseSoft * 0.35);
						float cloudShape = smoothstep(cLo, cHi, nBlend * shapeMask * 1.38);
						float topLit = clamp(0.65 + 0.35 * localP.z, 0.35, 1.15);
						float powder = 1.0 - exp(-cloudShape * 2.5);
						mediumDens = cloudShape * topLit * (0.7 + 0.6 * powder) * stepLen * 0.032;
					}
					else
					{
						float beamProg = clamp((localP.z + 1.0) * 0.5, 0.0, 1.0);
						float beamRad = mix(0.25, 0.95, beamProg);
						float beamCore = smoothstep(beamRad, beamRad * mix(0.85, 0.05, edgeSoft), length(localP.xy));
						float endFade = smoothstep(1.0, zInnerEdge, abs(localP.z));
						float dustMotes = mix(0.45 + 0.95 * smoothstep(0.35, 0.78, n), 0.85 + 0.25 * n, noiseSoft);
						mediumDens = beamCore * endFade * shapeMask * dustMotes * stepLen * 0.032;
					}

					if (mediumDens > 0.0001)
					{
						vec3 lightInVol = evalInVolumeLights(sampleView, worldP, rayDir, lcount);
						float sunVis = evalSunVisibility(worldP);
						vec3 sunScatter = (uSunShadowEnable > 0) ? (uSunLightColor.rgb * sunVis * sunPhase * 0.55) : vec3(0.0);
						vec3 ambTerm = (uSunShadowEnable > 0) ? (baseAmb * (0.35 + 0.65 * sunVis)) : baseAmb;
						float sigma = mediumDens * volDensity;
						volSum += transmittance * volCol * (ambTerm + sunScatter + lightInVol) * mediumDens;
						transmittance *= exp(-sigma * 0.45);
						if (transmittance < 0.02)
							break;
					}
				}
			}
			volAccum += volSum * volDensity;
		}
	}
	
	gl_FragColor = vec4(volAccum * uIntensity, 1.0);
}
