#define MAXSTEPS 48

varying vec2 vTexCoord;

uniform sampler2D uDepthBuffer;
uniform sampler2D uNormalBuffer;
uniform sampler2D uMaterialBuffer;

uniform vec2 uScreenSize;
uniform float uNear;
uniform float uFar;
uniform mat4 uProjMatrix;
uniform mat4 uProjMatrixInv;

uniform vec3 uSunViewDir;
uniform int uSteps;
uniform float uLength;
uniform float uThickness;
uniform float uStrength;

float unpackDepth(vec4 c)
{
	return c.r + c.g / 255.0 + c.b / (255.0 * 255.0);
}

vec3 unpackNormal(vec4 c)
{
	return normalize(c.rgb * 2.0 - 1.0);
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

float screenNoise(vec2 px)
{
	return fract(52.9829189 * fract(dot(px, vec2(0.06711056, 0.00583715))));
}

void main()
{
	vec4 depthTex = texture2D(uDepthBuffer, vTexCoord);
	if (depthTex.a < 0.99 || uStrength <= 0.001)
	{
		gl_FragColor = vec4(1.0);
		return;
	}
	
	// Respect emissive/SSAO brightness mask (.r) so glowing blocks aren't darkened
	float brMask = texture2D(uMaterialBuffer, vTexCoord).r;
	if (brMask <= 0.01)
	{
		gl_FragColor = vec4(1.0);
		return;
	}
	
	vec3 N = unpackNormal(texture2D(uNormalBuffer, vTexCoord));
	vec3 rayDir = normalize(uSunViewDir);
	
	// Skip faces already turned away from the sun (prevents self-shadowing bands on flat walls)
	float ndotl = dot(N, rayDir);
	if (ndotl <= 0.06)
	{
		gl_FragColor = vec4(1.0);
		return;
	}
	
	float originDepth = unpackDepth(depthTex);
	vec3 origin = posFromBuffer(vTexCoord, originDepth);
	float viewDist = max(0.5, origin.z);
	if (viewDist > 650.0)
	{
		gl_FragColor = vec4(1.0);
		return;
	}
	
	float pxWorld = max(0.004, (2.0 * viewDist) / max(abs(uProjMatrix[1][1]) * max(uScreenSize.y, 1.0), 1.0));
	float slope = 1.0 - clamp(ndotl, 0.0, 1.0);
	
	int steps = clamp(uSteps, 8, MAXSTEPS);
	float rayLen = clamp(uLength, 0.5, 40.0) * clamp(viewDist / 28.0, 0.30, 1.0);
	float jitter = screenNoise(vTexCoord * max(uScreenSize, vec2(1.0, 1.0)));
	float thickness = max(0.35, uThickness) * clamp(viewDist / 32.0, 0.45, 2.5);
	
	vec3 rayStart = origin + N * (pxWorld * (1.6 + 2.8 * slope));
	float baseBias = pxWorld * (1.2 + 2.6 * slope);
	
	float occluded = 0.0;
	
	for (int i = 0; i < MAXSTEPS; i++)
	{
		if (i >= steps)
			break;
		
		float fracS = (float(i) + 0.15 + 0.85 * jitter) / float(steps);
		float t = rayLen * mix(fracS, fracS * fracS, 0.42);
		float stepBias = baseBias + (t / float(steps)) * (0.35 + 0.45 * slope);
		vec3 samplePos = rayStart + rayDir * t;
		if (samplePos.z <= uNear || samplePos.z >= uFar)
			break;
		
		vec4 clip = uProjMatrix * vec4(samplePos, 1.0);
		if (clip.w <= 0.0001)
			break;
		vec2 uv = (clip.xy / clip.w) * 0.5 + 0.5;
		uv.y = 1.0 - uv.y;
		
		if (uv.x < 0.002 || uv.x > 0.998 || uv.y < 0.002 || uv.y > 0.998)
			break;
		
		vec2 pxDelta = (uv - vTexCoord) * max(uScreenSize, vec2(1.0, 1.0));
		if (dot(pxDelta, pxDelta) < 2.25)
			continue;
		
		vec4 sDepth = texture2D(/* lod0 */uDepthBuffer, uv);
		if (sDepth.a < 0.99)
			continue;
		
		float sceneZ = posFromBuffer(uv, unpackDepth(sDepth)).z;
		float diff = samplePos.z - sceneZ;
		
		if (diff > stepBias && diff < thickness + stepBias)
		{
			float hitWeight = smoothstep(stepBias, stepBias + thickness * 0.25, diff) * (1.0 - smoothstep(stepBias + thickness * 0.65, stepBias + thickness, diff));
			float distFade = 1.0 - smoothstep(0.55, 1.0, t / rayLen);
			occluded = max(occluded, hitWeight * distFade);
			if (occluded > 0.92)
				break;
		}
	}
	
	float sunFade = smoothstep(0.06, 0.28, ndotl);
	float farFade = 1.0 - smoothstep(350.0, 650.0, viewDist);
	float vis = 1.0 - clamp(occluded * uStrength * brMask * sunFade * farFade, 0.0, 0.88);
	gl_FragColor = vec4(vis, vis, vis, 1.0);
}
