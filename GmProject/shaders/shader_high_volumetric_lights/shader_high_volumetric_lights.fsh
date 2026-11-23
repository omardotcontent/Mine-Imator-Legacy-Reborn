#define MAXLIGHTS 16
#define MAXSTEPS 64

varying vec2 vTexCoord;

uniform sampler2D uDepthBuffer;

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

// Per-item view-space data packed into uLightData[64] (4 vec4s per item, 16 items max):
// uLightData[l*4 + 0] = vec4(viewPos.xyz, range)
// uLightData[l*4 + 1] = vec4(color.rgb, strength / density)
// uLightData[l*4 + 2] = vec4(viewDir.xyz, typeCode)
//   typeCode < -0.5 => Point Light / HDR Emissive Halo
//   typeCode in [-0.5, 1.0] => Spotlight (cosHalfAngle)
//   typeCode > 1.5 => 3D Volume Object (2.0 = Fog Volume, 3.0 = 3D Cloud Volume, 4.0 = Light Beam Volume)
// uLightData[l*4 + 3] = vec4(param1, param2, noiseScale, windSpeed)
uniform vec4 uLightData[64];

// Per-item view-to-unit-local ([-1, +1]^3) inverse transform for 3D Volumes (4 vec4s per item):
// uVolumeXform[l*4 + 0] = row 0 of view->unitLocal matrix
// uVolumeXform[l*4 + 1] = row 1 of view->unitLocal matrix
// uVolumeXform[l*4 + 2] = row 2 of view->unitLocal matrix
// uVolumeXform[l*4 + 3] = vec4(shapeType, 0, 0, 0)  [0=Box, 1=Sphere/Ellipsoid, 2=Cylinder, 3=Cone]
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

float fbm3DVol(vec3 p)
{
	float v = 0.0;
	v += 0.55 * noise3DVol(p);
	v += 0.30 * noise3DVol(p * 2.07 + vec3(17.1, 31.7, 11.3));
	v += 0.15 * noise3DVol(p * 4.13 + vec3(53.2, 19.8, 41.9));
	return v;
}

float unpackDepth(vec4 c)
{
	if (c.a < 0.99)
		return 1.0;
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

float screenJitter(vec2 uv)
{
	return fract(52.9829189 * fract(dot(uv * 512.0, vec2(0.06711056, 0.00583715))));
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
	float jitter = screenJitter(vTexCoord);
	
	vec3 volAccum = vec3(0.0);
	
	for (int l = 0; l < MAXLIGHTS; l++)
	{
		if (l >= lcount)
			break;
		
		vec4 d0 = uLightData[l * 4];
		vec4 d1 = uLightData[l * 4 + 1];
		vec4 d2 = uLightData[l * 4 + 2];
		vec4 d3 = uLightData[l * 4 + 3];
		vec3 lPos = d0.xyz;
		float lRange = max(1.0, d0.w);
		vec3 lCol = d1.rgb;
		float lStr = d1.w;
		vec3 lDir = d2.xyz;
		float cosOuter = d2.w;
		float sharpness = d3.x;
		
		if (cosOuter < -0.5)
		{
			// Point Light / HDR Emissive Object Volumetric Halo
			if (uPointRadius > 0.001 && lPos.z > uNear)
			{
				float tClosest = dot(lPos, rayDir);
				if (tClosest > 0.0 && tClosest < maxRayDist + lRange * 0.15)
				{
					float tClamped = min(tClosest, maxRayDist);
					vec3 p = rayDir * tClamped;
					float d = length(p - lPos);
					float haloRad = max(4.0, lRange * 0.35 * uPointRadius);
					if (d < haloRad)
					{
						float normD = d / haloRad;
						float glow = exp(-normD * normD * 4.5) * (1.0 - normD);
						float occFade = smoothstep(lPos.z - haloRad * 0.5, lPos.z, maxRayDist);
						volAccum += lCol * lStr * glow * occFade * uPointRadius * 0.55;
					}
				}
			}
		}
		else if (cosOuter > 1.5)
		{
			// 3D Volume Object: 2.0 = Volumetric Fog, 3.0 = 3D Cloud Volume, 4.0 = Volumetric Light Beam
			// Exact oriented 3D bounding-box ray intersection in unit local space [-1, +1]^3
			vec4 vx0 = uVolumeXform[l * 4];
			vec4 vx1 = uVolumeXform[l * 4 + 1];
			vec4 vx2 = uVolumeXform[l * 4 + 2];
			float shapeType = uVolumeXform[l * 4 + 3].x;

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
				vec3 windVel = vec3(uTime * windSpd * 0.65, uTime * windSpd * 0.35, uTime * windSpd * 0.15);
				vec3 volSum = vec3(0.0);
				for (int s = 0; s < MAXSTEPS; s++)
				{
					if (s >= steps)
						break;
					float t = tStart + stepLen * (float(s) + jitter);
					vec3 localP = rayOrigL + rayDirL * t;
					float shapeMask = 0.0;
					if (shapeType < 0.5) // Box (CUBE)
					{
						vec3 edge = smoothstep(vec3(1.0), vec3(0.55), abs(localP));
						shapeMask = edge.x * edge.y * edge.z;
					}
					else if (shapeType < 1.5) // Sphere / Ellipsoid (SPHERE)
					{
						shapeMask = smoothstep(1.0, 0.35, length(localP));
					}
					else if (shapeType < 2.5) // Cylinder (CYLINDER)
					{
						shapeMask = smoothstep(1.0, 0.45, length(localP.xy)) * smoothstep(1.0, 0.65, abs(localP.z));
					}
					else // Cone (CONE)
					{
						float coneR = mix(1.0, 0.06, clamp((localP.z + 1.0) * 0.5, 0.0, 1.0));
						shapeMask = smoothstep(coneR, coneR * 0.3, length(localP.xy)) * smoothstep(1.0, 0.75, abs(localP.z));
					}

					if (shapeMask > 0.001)
					{
						vec3 sampleView = rayDir * t;
						vec3 worldP = (uViewMatrixInv * vec4(sampleView, 1.0)).xyz;
						float n = fbm3DVol(worldP * noiseScale + windVel);
						if (cosOuter < 2.5) // 2.0: Volumetric Fog Volume
						{
							float fogDens = shapeMask * smoothstep(0.2, 0.85, n);
							volSum += lCol * fogDens * stepLen * 0.016;
						}
						else if (cosOuter < 3.5) // 3.0: 3D Volumetric Cloud Volume
						{
							float cloudShape = smoothstep(0.36, 0.78, n * shapeMask * 1.35);
							// Beer-powder self-shadowing & top silver-lining highlight (local Z-up)
							float topLit = clamp(0.65 + 0.35 * localP.z, 0.35, 1.15);
							float powder = 1.0 - exp(-cloudShape * 2.5);
							volSum += lCol * cloudShape * topLit * (0.7 + 0.6 * powder) * stepLen * 0.032;
						}
						else // 4.0: Volumetric Light Beam Volume
						{
							float beamProg = clamp((localP.z + 1.0) * 0.5, 0.0, 1.0);
							float beamRad = mix(0.25, 0.95, beamProg);
							float beamCore = smoothstep(beamRad, beamRad * 0.15, length(localP.xy));
							float endFade = smoothstep(1.0, 0.65, abs(localP.z));
							float dustMotes = 0.55 + 0.85 * smoothstep(0.35, 0.8, n);
							volSum += lCol * beamCore * endFade * shapeMask * dustMotes * stepLen * 0.032;
						}
					}
				}
				volAccum += volSum * lStr;
			}
		}
		else if (uSpotDensity > 0.001)
		{
			// Spotlight 3D Volumetric Cone Raymarch with animated air dust noise
			float tProj = dot(lPos, rayDir);
			float tStart = max(uNear, tProj - lRange);
			float tEnd = min(maxRayDist, tProj + lRange);
			if (tEnd > tStart)
			{
				float segLen = tEnd - tStart;
				float stepLen = segLen / float(steps);
				float cosInner = mix(cosOuter, 0.9995, clamp(sharpness, 0.05, 0.95));
				float coneAcc = 0.0;
				
				for (int s = 0; s < MAXSTEPS; s++)
				{
					if (s >= steps)
						break;
					
					float t = tStart + stepLen * (float(s) + jitter);
					vec3 sampleP = rayDir * t;
					vec3 toP = sampleP - lPos;
					float dist = length(toP);
					if (dist > 0.001 && dist < lRange)
					{
						float cosAng = dot(toP / dist, lDir);
						if (cosAng > cosOuter)
						{
							float coneWeight = smoothstep(cosOuter, cosInner, cosAng);
							float distWeight = (1.0 - dist / lRange);
							distWeight *= distWeight;
							float apexBoost = 1.0 / (1.0 + dist * 0.025);
							coneAcc += coneWeight * distWeight * apexBoost * stepLen * 0.018;
						}
					}
				}
				volAccum += lCol * lStr * coneAcc * uSpotDensity;
			}
		}
	}
	
	gl_FragColor = vec4(volAccum * uIntensity, 1.0);
}
