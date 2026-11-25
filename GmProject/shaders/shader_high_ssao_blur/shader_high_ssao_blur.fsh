#define SAMPLES 4

varying vec2 vTexCoord;

uniform sampler2D uDepthBuffer;
uniform sampler2D uNormalBuffer;
uniform vec2 uScreenSize;
uniform vec2 uPixelCheck;
uniform int uAllowSky;

float unpackDepth(vec4 c)
{
	return c.r + c.g / 255.0 + c.b / (255.0 * 255.0);
}

vec3 unpackNormal(vec4 c)
{
	return normalize(c.rgb * 2.0 - 1.0);
}

float bilateralWeight(float cDepth, float sDepth, vec3 cNormal, vec3 sNormal)
{
	float nW = pow(clamp(dot(cNormal, sNormal), 0.0, 1.0), 8.0);
	float relDepthDiff = abs(sDepth - cDepth) / max(max(cDepth, sDepth), 0.00025);
	float dW = exp(-relDepthDiff * 32.0 - abs(sDepth - cDepth) * 60.0);
	return nW * dW;
}

void main()
{
	vec4 centerDepthTex = texture2D(uDepthBuffer, vTexCoord);
	bool centerIsSky = (centerDepthTex.a < 0.99);
	if (uAllowSky < 1 && centerIsSky)
	{
		gl_FragColor = texture2D(/* lod0 */gm_BaseTexture, vTexCoord);
		return;
	}
	float centerDepth = centerIsSky ? 1.0 : unpackDepth(centerDepthTex);
	vec3 centerNormal = centerIsSky ? vec3(0.0, 0.0, 1.0) : unpackNormal(texture2D(/* lod0 */uNormalBuffer, vTexCoord));
	
	vec2 texelCheck = uPixelCheck / max(uScreenSize, vec2(1.0, 1.0));
	
	float weights[5];
	weights[0] = 70.0;
	weights[1] = 56.0;
	weights[2] = 28.0;
	weights[3] = 8.0;
	weights[4] = 1.0;
	
	vec4 ssao = texture2D(gm_BaseTexture, vTexCoord) * weights[0];
	float totalWeight = weights[0];
	
	for (int i = 0; i < SAMPLES; i++)
	{
		vec2 sampleOffset = float(i + 1) * texelCheck;
		float kW = weights[i + 1];
		
		// Positive direction
		vec2 posUV = clamp(vTexCoord + sampleOffset, vec2(0.0), vec2(1.0));
		vec4 posDT = texture2D(/* lod0 */uDepthBuffer, posUV);
		bool posIsSky = (posDT.a < 0.99);
		if (uAllowSky < 1)
		{
			if (!posIsSky)
			{
				float posDepth = unpackDepth(posDT);
				vec3 posNormal = unpackNormal(texture2D(/* lod0 */uNormalBuffer, posUV));
				float posW = bilateralWeight(centerDepth, posDepth, centerNormal, posNormal) * kW;
				ssao += texture2D(/* lod0 */gm_BaseTexture, posUV) * posW;
				totalWeight += posW;
			}
		}
		else if (centerIsSky && posIsSky)
		{
			ssao += texture2D(/* lod0 */gm_BaseTexture, posUV) * kW;
			totalWeight += kW;
		}
		else if (!centerIsSky && !posIsSky)
		{
			float posDepth = unpackDepth(posDT);
			float relD = abs(posDepth - centerDepth) / max(max(centerDepth, posDepth), 0.0005);
			float posW = exp(-relD * 24.0 - abs(posDepth - centerDepth) * 40.0) * kW;
			ssao += texture2D(/* lod0 */gm_BaseTexture, posUV) * posW;
			totalWeight += posW;
		}
		
		// Negative direction (symmetric)
		vec2 negUV = clamp(vTexCoord - sampleOffset, vec2(0.0), vec2(1.0));
		vec4 negDT = texture2D(/* lod0 */uDepthBuffer, negUV);
		bool negIsSky = (negDT.a < 0.99);
		if (uAllowSky < 1)
		{
			if (!negIsSky)
			{
				float negDepth = unpackDepth(negDT);
				vec3 negNormal = unpackNormal(texture2D(/* lod0 */uNormalBuffer, negUV));
				float negW = bilateralWeight(centerDepth, negDepth, centerNormal, negNormal) * kW;
				ssao += texture2D(/* lod0 */gm_BaseTexture, negUV) * negW;
				totalWeight += negW;
			}
		}
		else if (centerIsSky && negIsSky)
		{
			ssao += texture2D(/* lod0 */gm_BaseTexture, negUV) * kW;
			totalWeight += kW;
		}
		else if (!centerIsSky && !negIsSky)
		{
			float negDepth = unpackDepth(negDT);
			float relD = abs(negDepth - centerDepth) / max(max(centerDepth, negDepth), 0.0005);
			float negW = exp(-relD * 24.0 - abs(negDepth - centerDepth) * 40.0) * kW;
			ssao += texture2D(/* lod0 */gm_BaseTexture, negUV) * negW;
			totalWeight += negW;
		}
	}
	
	gl_FragColor = ssao / max(totalWeight, 0.0001);
}
