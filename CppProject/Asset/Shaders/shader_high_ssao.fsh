varying vec2 vTexCoord;

uniform sampler2D uDepthBuffer;
uniform sampler2D uNormalBuffer;
uniform sampler2D uBrightnessBuffer;
uniform sampler2D uNoiseBuffer;

uniform float uNear;
uniform float uFar;

uniform mat4 uProjMatrix;
uniform mat4 uProjMatrixInv;

uniform vec2 uScreenSize;

uniform vec3 uKernel[64];
uniform int uSamples;
uniform float uRadius;
uniform float uPower;
uniform float uBias;
uniform vec4 uColor;

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

float ignSsao(vec2 px)
{
	return fract(52.9829189 * fract(dot(px, vec2(0.06711056, 0.00583715))));
}

float traceHorizon(vec2 dirUV, float radPx, vec3 origin, vec3 normal, float searchRad, int steps, float jit, float minElev)
{
	float maxElev = minElev;
	float horizonAO = 0.0;
	for (int s = 0; s < 5; s++)
	{
		if (s >= steps)
			break;
		
		float fracStep = (float(s) + 0.25 + 0.75 * jit) / float(steps);
		float stepScale = mix(0.08, 1.0, fracStep * fracStep);
		vec2 sampleUV = vTexCoord + dirUV * (stepScale * radPx);
		if (sampleUV.x < 0.001 || sampleUV.x > 0.999 || sampleUV.y < 0.001 || sampleUV.y > 0.999)
			break;
		
		vec4 sDepthTex = texture2D(/* lod0 */uDepthBuffer, sampleUV);
		if (sDepthTex.a < 0.99)
			continue;
		
		vec3 sPos = posFromBuffer(sampleUV, unpackDepth(sDepthTex));
		vec3 delta = sPos - origin;
		float distSq = dot(delta, delta);
		if (distSq > 0.0001)
		{
			float invDist = 1.0 / sqrt(distSq);
			float elev = clamp(dot(normal, delta * invDist), 0.0, 1.0);
			if (elev > maxElev)
			{
				float falloff = clamp(1.0 - distSq / max(searchRad * searchRad, 0.001), 0.0, 1.0);
				float sBr = texture2D(/* lod0 */uBrightnessBuffer, sampleUV).r;
				horizonAO += (elev - maxElev) * falloff * (0.35 + 0.65 * sBr);
				maxElev = mix(maxElev, elev, falloff);
			}
		}
	}
	return horizonAO;
}

void main()
{
	vec4 depthTex = texture2D(uDepthBuffer, vTexCoord);
	if (depthTex.a < 1.0)
		discard;
	
	float centerBr = texture2D(uBrightnessBuffer, vTexCoord).r;
	if (centerBr <= 0.001)
	{
		gl_FragColor = vec4(1.0);
		return;
	}
	
	float originDepth = unpackDepth(depthTex);
	vec3 origin = posFromBuffer(vTexCoord, originDepth);
	vec3 normal = unpackNormal(texture2D(uNormalBuffer, vTexCoord));
	
	float searchRad = max(0.5, uRadius * (1.0 - originDepth * 0.5));
	vec4 radClip = uProjMatrix * vec4(origin + vec3(searchRad, 0.0, 0.0), 1.0);
	vec2 radUV = (radClip.xy / max(0.0001, radClip.w)) * 0.5 + 0.5;
	radUV.y = 1.0 - radUV.y;
	float rawPx = length((radUV - vTexCoord) * max(uScreenSize, vec2(1.0, 1.0)));
	float radPx = clamp(rawPx, 4.0, min(uScreenSize.x, uScreenSize.y) * 0.16);
	
	vec2 pxCoord = vTexCoord * max(uScreenSize, vec2(1.0, 1.0));
	float rot = ignSsao(pxCoord) * 0.78539816;
	float jit = ignSsao(pxCoord + vec2(37.0, 17.0));
	
	vec2 texelSize = 1.0 / max(uScreenSize, vec2(1.0, 1.0));
	int stepsPerDir = clamp(uSamples / 8, 2, 5);
	float minElev = sin(clamp(uBias * 0.65 + 0.06, 0.03, 0.45));
	
	float occlusion = 0.0;
	for (int d = 0; d < 4; d++)
	{
		float ang = rot + float(d) * 0.78539816;
		vec2 dirUV = vec2(cos(ang), sin(ang)) * texelSize;
		float sliceJit = fract(jit + float(d) * 0.381966);
		occlusion += traceHorizon( dirUV, radPx, origin, normal, searchRad, stepsPerDir, sliceJit, minElev);
		occlusion += traceHorizon(-dirUV, radPx, origin, normal, searchRad, stepsPerDir, fract(sliceJit + 0.5), minElev);
	}
	occlusion /= 8.0;
	
	occlusion = 1.0 - pow(clamp(1.0 - occlusion * 1.45, 0.0, 1.0), max(uPower, 0.1));
	occlusion = clamp(occlusion * centerBr, 0.0, 1.0);
	
	gl_FragColor = mix(vec4(1.0), uColor, occlusion);
}
