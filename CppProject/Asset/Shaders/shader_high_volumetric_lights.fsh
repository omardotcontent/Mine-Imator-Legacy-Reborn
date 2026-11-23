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
uniform vec4 uVolumeAmbient;

// Per-item view-space data packed into uLightData[64] (4 vec4s per item, 16 items max):
// uLightData[l*4 + 0] = vec4(viewPos.xyz, range)
// uLightData[l*4 + 1] = vec4(color.rgb, strength / density)
// uLightData[l*4 + 2] = vec4(viewDir.xyz, typeCode)
//   typeCode < -0.5       => Point Light / Emit Light (scatters ONLY inside Volume regions)
//   typeCode in [-0.5, 1] => Spotlight (cosHalfAngle; scatters ONLY inside Volume regions)
//   typeCode > 1.5        => 3D Volume Object (2.0 = Fog, 3.0 = 3D Cloud, 4.0 = Light Beam)
// uLightData[l*4 + 3] = vec4(param1, param2, noiseScale, windSpeed)
uniform vec4 uLightData[64];

// Per-item view-to-unit-local ([-1, +1]^3) inverse transform for 3D Volumes (4 vec4s per item):
// uVolumeXform[l*4 + 0..2] = rows 0..2 of view->unitLocal matrix
// uVolumeXform[l*4 + 3]    = vec4(shapeType, edgeSoftness, noiseSoftness, 0.0)
//   shapeType: 0=Box, 1=Sphere/Ellipsoid, 2=Cylinder, 3=Cone
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
	float v = 0.0;
	float w0 = mix(0.50, 0.78, noiseSoft);
	float w1 = mix(0.32, 0.17, noiseSoft);
	float w2 = mix(0.18, 0.05, noiseSoft);
	v += w0 * noise3DVol(p);
	v += w1 * noise3DVol(p * 2.07 + vec3(17.1, 31.7, 11.3));
	v += w2 * noise3DVol(p * 4.13 + vec3(53.2, 19.8, 41.9));
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

// Evaluate lighting scattered from all Point, Spot, and Emit lights at a view-space sample inside a Volume
vec3 evalInVolumeLights(vec3 sampleView, vec3 rayDir, int lcount)
{
	vec3 scatter = vec3(0.0);
	for (int k = 0; k < MAXLIGHTS; k++)
	{
		if (k >= lcount)
			break;
		vec4 kd2 = uLightData[k * 4 + 2];
		if (kd2.w > 1.5)
			continue; // Skip volume entries; only evaluate actual light sources

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
				// Spotlight cone intersection inside the volume
				float cosOuter = kd2.w;
				float cosInner = mix(cosOuter, 0.9995, clamp(kd3.x, 0.05, 0.95));
				float cosAng = dot(lightToSample, kd2.xyz);
				float coneW = smoothstep(cosOuter, cosInner, cosAng);
				atten *= coneW;
			}

			if (atten > 0.0005)
			{
				// Forward-scattering phase boost for realistic light shafts through fog/clouds
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
	float jitter = screenJitter(vTexCoord);
	
	vec3 volAccum = vec3(0.0);
	
	// ONLY render volumetric media inside 3D Volume Objects (zero fog halo around lights outside Volumes)
	for (int l = 0; l < MAXLIGHTS; l++)
	{
		if (l >= lcount)
			break;
		
		vec4 d2 = uLightData[l * 4 + 2];
		float typeCode = d2.w;
		if (typeCode <= 1.5)
			continue; // Lights are evaluated strictly inside Volume regions via evalInVolumeLights()
		
		vec4 d1 = uLightData[l * 4 + 1];
		vec4 d3 = uLightData[l * 4 + 3];
		vec3 volCol = d1.rgb;
		float volDensity = d1.w;
		
		// Exact oriented 3D bounding-box ray intersection in unit local space [-1, +1]^3
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
			vec3 windVel = vec3(uTime * windSpd * 0.65, uTime * windSpd * 0.35, uTime * windSpd * 0.15);

			// Edge softness controls boundary feathering (0% = crisp boundary, 100% = full center-to-edge soft fade)
			float innerEdge = mix(0.985, 0.04, edgeSoft);
			float zInnerEdge = mix(0.985, 0.12, edgeSoft);
			float edgePower = mix(0.65, 1.85, edgeSoft);

			vec3 baseAmb = (typeCode > 3.5) ? max(uVolumeAmbient.rgb, vec3(0.75)) : uVolumeAmbient.rgb;
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
					vec3 edge = smoothstep(vec3(1.0), vec3(innerEdge), abs(localP));
					shapeMask = edge.x * edge.y * edge.z;
				}
				else if (shapeType < 1.5) // Sphere / Ellipsoid (SPHERE)
				{
					shapeMask = smoothstep(1.0, innerEdge, length(localP));
				}
				else if (shapeType < 2.5) // Cylinder (CYLINDER)
				{
					shapeMask = smoothstep(1.0, innerEdge, length(localP.xy)) * smoothstep(1.0, zInnerEdge, abs(localP.z));
				}
				else // Cone (CONE)
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
					if (typeCode < 2.5) // 2.0: Volumetric Fog Volume
					{
						float nLo = mix(0.32, 0.04, noiseSoft);
						float nHi = mix(0.72, 0.96, noiseSoft);
						float nVal = mix(smoothstep(nLo, nHi, n), 0.72, noiseSoft * 0.55);
						mediumDens = shapeMask * nVal * stepLen * 0.018;
					}
					else if (typeCode < 3.5) // 3.0: 3D Volumetric Cloud Volume
					{
						float cLo = mix(0.46, 0.14, noiseSoft);
						float cHi = mix(0.64, 0.90, noiseSoft);
						float nBlend = mix(n, 0.72, noiseSoft * 0.35);
						float cloudShape = smoothstep(cLo, cHi, nBlend * shapeMask * 1.38);
						float topLit = clamp(0.65 + 0.35 * localP.z, 0.35, 1.15);
						float powder = 1.0 - exp(-cloudShape * 2.5);
						mediumDens = cloudShape * topLit * (0.7 + 0.6 * powder) * stepLen * 0.032;
					}
					else // 4.0: Volumetric Light Beam Volume
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
						vec3 lightInVol = evalInVolumeLights(sampleView, rayDir, lcount);
						volSum += volCol * (baseAmb + lightInVol) * mediumDens;
					}
				}
			}
			volAccum += volSum * volDensity;
		}
	}
	
	gl_FragColor = vec4(volAccum * uIntensity, 1.0);
}
