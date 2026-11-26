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
	return w0 * noise3DVol(p) + (1.0 - w0) * noise3DVol(p * 2.13 + vec3(17.1, 31.7, 11.3));
}

vec2 volumeRayBounds(vec3 origin, vec3 direction)
{
	vec3 safeDir = vec3(
		abs(direction.x) < 1e-5 ? (direction.x < 0.0 ? -1e-5 : 1e-5) : direction.x,
		abs(direction.y) < 1e-5 ? (direction.y < 0.0 ? -1e-5 : 1e-5) : direction.y,
		abs(direction.z) < 1e-5 ? (direction.z < 0.0 ? -1e-5 : 1e-5) : direction.z
	);
	vec3 t0 = (-vec3(1.0) - origin) / safeDir;
	vec3 t1 = ( vec3(1.0) - origin) / safeDir;
	vec3 nearT = min(t0, t1);
	vec3 farT = max(t0, t1);
	return vec2(max(max(nearT.x, nearT.y), nearT.z), min(min(farT.x, farT.y), farT.z));
}

// Density per world unit, shared by camera rays and shadow rays.
float volumeMediumDensity(vec3 localP, vec3 noiseP, float shape, float mode, float edgeSoft, float noiseSoft)
{
	float innerEdge = mix(0.985, 0.04, edgeSoft);
	float zInnerEdge = mix(0.985, 0.12, edgeSoft);
	float zMask = 1.0 - smoothstep(zInnerEdge, 1.0, abs(localP.z));
	float shapeMask;
	if (shape < 0.5)
	{
		vec3 edge = 1.0 - smoothstep(vec3(innerEdge), vec3(1.0), abs(localP));
		shapeMask = edge.x * edge.y * edge.z;
	}
	else if (shape < 1.5)
		shapeMask = 1.0 - smoothstep(innerEdge, 1.0, length(localP));
	else if (shape < 2.5)
		shapeMask = (1.0 - smoothstep(innerEdge, 1.0, length(localP.xy))) * zMask;
	else
	{
		float coneRadius = mix(1.0, 0.05, clamp((localP.z + 1.0) * 0.5, 0.0, 1.0));
		shapeMask = (1.0 - smoothstep(coneRadius * innerEdge, coneRadius, length(localP.xy))) * zMask;
	}
	if (shapeMask <= 0.001)
		return 0.0;

	shapeMask = pow(shapeMask, mix(0.65, 1.85, edgeSoft));
	float n = fbm3DVol(noiseP, noiseSoft);
	if (mode < 2.5)
	{
		float nLo = mix(0.32, 0.04, noiseSoft);
		float nHi = mix(0.72, 0.96, noiseSoft);
		float nVal = mix(smoothstep(nLo, nHi, n), 0.72, noiseSoft * 0.55);
		return shapeMask * nVal * 0.018;
	}
	if (mode < 3.5)
	{
		float cloudLo = mix(0.46, 0.14, noiseSoft);
		float cloudHi = mix(0.64, 0.90, noiseSoft);
		float cloudShape = smoothstep(cloudLo, cloudHi, mix(n, 0.72, noiseSoft * 0.35) * shapeMask * 1.38);
		float topLit = clamp(0.65 + 0.35 * localP.z, 0.35, 1.15);
		float powder = 1.0 - exp(-cloudShape * 2.5);
		return cloudShape * topLit * (0.7 + 0.6 * powder) * 0.032;
	}

	float beamProgress = clamp((localP.z + 1.0) * 0.5, 0.0, 1.0);
	float beamRadius = mix(0.25, 0.95, beamProgress);
	float beamCore = 1.0 - smoothstep(beamRadius * mix(0.85, 0.05, edgeSoft), beamRadius, length(localP.xy));
	float dustMotes = mix(0.45 + 0.95 * smoothstep(0.35, 0.78, n), 0.85 + 0.25 * n, noiseSoft);
	return beamCore * zMask * shapeMask * dustMotes * 0.032;
}
