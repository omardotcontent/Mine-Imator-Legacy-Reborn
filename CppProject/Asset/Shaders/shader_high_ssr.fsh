#define MAXSTEPS 96

varying vec2 vTexCoord;

uniform sampler2D uDepthBuffer;
uniform sampler2D uNormalBuffer;
uniform sampler2D uMaterialBuffer;

uniform vec2 uScreenSize;
uniform float uNear;
uniform float uFar;
uniform mat4 uProjMatrix;
uniform mat4 uProjMatrixInv;

uniform int uSteps;
uniform float uMaxDist;
uniform float uThickness;
uniform float uStrength;
uniform float uFresnel;
uniform int uWaterOnly;
uniform vec4 uSkyColor;
uniform vec4 uHorizonColor;

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

vec2 projectToScreen(vec3 viewPos)
{
	vec4 clip = uProjMatrix * vec4(viewPos, 1.0);
	vec2 uv = (clip.xy / max(0.0001, clip.w)) * 0.5 + 0.5;
	uv.y = 1.0 - uv.y;
	return uv;
}

float ignSsr(vec2 px)
{
	return fract(52.9829189 * fract(dot(px, vec2(0.06711056, 0.00583715))));
}

void main()
{
	vec4 depthTex = texture2D(uDepthBuffer, vTexCoord);
	if (depthTex.a < 0.99)
	{
		gl_FragColor = vec4(0.0);
		return;
	}
	
	vec4 matTex = texture2D(uMaterialBuffer, vTexCoord);
	float reflectivity = matTex.g;
	float isWater = matTex.b;
	
	if (uWaterOnly > 0 && isWater < 0.5)
	{
		gl_FragColor = vec4(0.0);
		return;
	}
	if (reflectivity < 0.04)
	{
		gl_FragColor = vec4(0.0);
		return;
	}
	
	float originDepth = unpackDepth(depthTex);
	vec3 origin = posFromBuffer(vTexCoord, originDepth);
	vec3 N = unpackNormal(texture2D(uNormalBuffer, vTexCoord));
	vec3 V = normalize(-origin);
	vec3 R = normalize(reflect(-V, N));
	
	// Fresnel Schlick factor scaled by surface reflectivity
	float fresnel = mix(0.15, 1.0, pow(1.0 - clamp(dot(N, V), 0.0, 1.0), 4.0) * uFresnel);
	fresnel = clamp(fresnel, 0.0, 1.0);
	
	int maxSteps = clamp(uSteps, 8, MAXSTEPS);
	float stepLen = uMaxDist / float(maxSteps);
	float jit = ignSsr(vTexCoord * max(uScreenSize, vec2(1.0, 1.0)));
	
	vec3 hitColor = mix(uHorizonColor.rgb, uSkyColor.rgb, clamp(R.y * 0.5 + 0.5, 0.0, 1.0));
	float hitAlpha = (isWater > 0.5) ? 0.55 : (0.22 * reflectivity);
	
	vec3 rayPos = origin + N * 0.28 + R * (stepLen * 0.4 * jit);
	vec3 prevPos = origin + N * 0.28;
	
	for (int i = 0; i < MAXSTEPS; i++)
	{
		if (i >= maxSteps)
			break;
		
		float stride = stepLen * (0.4 + 1.2 * (float(i) / float(maxSteps)));
		prevPos = rayPos;
		rayPos += R * stride;
		
		if (rayPos.z <= uNear || rayPos.z >= uFar)
			break;
		
		vec2 sampleUV = projectToScreen(rayPos);
		if (sampleUV.x < 0.0 || sampleUV.x > 1.0 || sampleUV.y < 0.0 || sampleUV.y > 1.0)
			break;
		
		vec4 sDepthTex = texture2D(/* lod0 */uDepthBuffer, sampleUV);
		if (sDepthTex.a < 0.99)
			continue;
		
		float sceneZ = posFromBuffer(sampleUV, unpackDepth(sDepthTex)).z;
		float diff = rayPos.z - sceneZ;
		
		if (diff > 0.0 && diff < uThickness + stride * 1.6)
		{
			// Binary search refinement (4 steps)
			vec3 lo = prevPos;
			vec3 hi = rayPos;
			for (int b = 0; b < 4; b++)
			{
				vec3 mid = 0.5 * (lo + hi);
				vec2 mUV = projectToScreen(mid);
				float mZ = posFromBuffer(mUV, unpackDepth(texture2D(/* lod0 */uDepthBuffer, mUV))).z;
				if (mid.z > mZ)
					hi = mid;
				else
					lo = mid;
			}
			vec2 finalUV = projectToScreen(hi);
			if (finalUV.x >= 0.0 && finalUV.x <= 1.0 && finalUV.y >= 0.0 && finalUV.y <= 1.0)
			{
				vec2 edge = smoothstep(vec2(0.0), vec2(0.08), finalUV) * (vec2(1.0, 1.0) - smoothstep(vec2(0.92), vec2(1.0), finalUV));
				float edgeFade = edge.x * edge.y;
				float distFade = 1.0 - clamp(float(i) / float(maxSteps), 0.0, 1.0);
				float backfaceReject = smoothstep(-0.35, 0.25, R.z);
				float conf = edgeFade * clamp(distFade * 1.4, 0.0, 1.0) * (0.65 + 0.35 * backfaceReject);
				vec3 sampled = texture2D(/* lod0 */gm_BaseTexture, finalUV).rgb;
				hitColor = mix(hitColor, sampled, conf);
				hitAlpha = max(hitAlpha, conf);
			}
			break;
		}
	}
	
	float blendAmt = clamp(reflectivity * fresnel * uStrength * hitAlpha, 0.0, 0.92);
	gl_FragColor = vec4(hitColor, blendAmt);
}
