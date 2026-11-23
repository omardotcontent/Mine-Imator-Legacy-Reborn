#define MAXSTEPS 48

varying vec2 vTexCoord;

uniform sampler2D uDepthBuffer;
uniform sampler2D uNormalBuffer;
uniform sampler2D uMaterialBuffer;

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

float screenNoise(vec2 uv)
{
	return fract(52.9829189 * fract(dot(uv * 512.0, vec2(0.06711056, 0.00583715))));
}

void main()
{
	vec4 base = texture2D(gm_BaseTexture, vTexCoord);
	vec4 depthTex = texture2D(uDepthBuffer, vTexCoord);
	if (depthTex.a < 0.99 || uStrength <= 0.001)
	{
		gl_FragColor = base;
		return;
	}
	
	// Respect emissive/SSAO brightness mask (.r) so glowing blocks aren't darkened
	float brMask = texture2D(uMaterialBuffer, vTexCoord).r;
	if (brMask <= 0.01)
	{
		gl_FragColor = base;
		return;
	}
	
	vec3 N = unpackNormal(texture2D(uNormalBuffer, vTexCoord));
	vec3 rayDir = normalize(uSunViewDir);
	
	// Skip faces already turned away from the sun (prevents self-shadowing bands on flat walls)
	float ndotl = dot(N, rayDir);
	if (ndotl <= 0.06)
	{
		gl_FragColor = base;
		return;
	}
	
	float originDepth = unpackDepth(depthTex);
	vec3 origin = posFromBuffer(vTexCoord, originDepth);
	
	// Offset ray start safely outside the surface along normal to avoid 24-bit depth stair-step self-hits
	float depthScale = 1.0 + originDepth * 22.0;
	vec3 rayStart = origin + N * (0.28 * depthScale);
	
	int steps = clamp(uSteps, 4, MAXSTEPS);
	float rayLen = clamp(uLength, 0.5, 40.0);
	float stepSize = rayLen / float(steps);
	float jitter = screenNoise(vTexCoord);
	float thickness = max(0.4, uThickness) * (1.0 + originDepth * 6.0);
	float bias = 0.14 * depthScale + stepSize * 0.45;
	
	float occluded = 0.0;
	
	for (int i = 0; i < MAXSTEPS; i++)
	{
		if (i >= steps)
			break;
		
		float t = stepSize * (float(i) + 0.5 + jitter * 0.5);
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
		
		vec4 sDepth = texture2D(uDepthBuffer, uv);
		if (sDepth.a < 0.99)
			continue;
		
		float sceneZ = posFromBuffer(uv, unpackDepth(sDepth)).z;
		float diff = samplePos.z - sceneZ;
		
		if (diff > bias && diff < thickness + bias)
		{
			// Smooth thickness & distance falloff to eliminate banding
			float hitWeight = smoothstep(bias, bias + thickness * 0.25, diff) * (1.0 - smoothstep(bias + thickness * 0.65, bias + thickness, diff));
			float distFade = 1.0 - smoothstep(0.55, 1.0, t / rayLen);
			occluded = max(occluded, hitWeight * distFade);
			if (occluded > 0.92)
				break;
		}
	}
	
	// Smooth grazing fade + distance fade
	float sunFade = smoothstep(0.06, 0.28, ndotl);
	float farFade = 1.0 - smoothstep(0.25, 0.65, originDepth);
	float shadowFactor = 1.0 - clamp(occluded * uStrength * brMask * sunFade * farFade, 0.0, 0.85);
	gl_FragColor = vec4(base.rgb * shadowFactor, base.a);
}
