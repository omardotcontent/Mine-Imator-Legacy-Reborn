uniform sampler2D uBlurBuffer;
uniform vec2 uScreenSize;
uniform float uBlurSize;

uniform float uBias;
uniform float uThreshold;
uniform float uGain;

uniform int uFringe;
uniform vec3 uFringeAngle;
uniform vec3 uFringeStrength;

uniform int uSampleAmount;
uniform vec2 uSamples[128];
uniform float uWeightSamples[128];

varying vec2 vTexCoord;

float getBlur(vec2 coord)
{
	vec2 blur = texture2D(/* lod0 */uBlurBuffer, coord).xy;
	return clamp(blur.x + blur.y, 0.0, 1.0);
}

float ignDofNoise(vec2 px)
{
	return fract(52.9829189 * fract(dot(px, vec2(0.06711056, 0.00583715))));
}

vec4 getColor(vec2 coord, float blur)
{
	vec4 baseColor = texture2D(/* lod0 */gm_BaseTexture, coord);
	vec3 lumCo = vec3(0.299, 0.587, 0.114);
	float lum = dot(baseColor.rgb, lumCo);
	float thresh = max((lum - uThreshold) * uGain, 0.0);
	baseColor.rgb = baseColor.rgb + mix(vec3(0.0), baseColor.rgb, vec3(thresh * blur));
	return baseColor;
}

void main()
{
	vec2 texelSize = 1.0 / max(uScreenSize, vec2(1.0, 1.0));
	float screenSampleSize = uScreenSize.y * uBlurSize;
	vec2 blurTex = texture2D(uBlurBuffer, vTexCoord).xy;
	float myBlur = clamp(blurTex.r + blurTex.g, 0.0, 1.0);
	
	float blur = 0.0;
	float colorDiv = 0.0;
	vec4 colorAdd = vec4(0.0);
	float weightStrength = 0.0;
	float blurAmount = myBlur * screenSampleSize;
	vec4 centerTex = texture2D(gm_BaseTexture, vTexCoord);
	
	if (blurAmount > 0.001)
	{
		float jit = ignDofNoise(vTexCoord * uScreenSize) * 6.2831853;
		float cs = cos(jit);
		float sn = sin(jit);
		
		for (int i = 0; i < 128; i++)
		{
			if (i >= uSampleAmount)
				break;
			
			if (uWeightSamples[i] < 0.05)
				continue;
			
			vec2 rawOff = uSamples[i].xy;
			vec2 rotOff = vec2(rawOff.x * cs - rawOff.y * sn, rawOff.x * sn + rawOff.y * cs);
			vec2 offset = rotOff * blurAmount;
			vec2 tex = clamp(vTexCoord + texelSize * offset, vec2(0.0), vec2(1.0));
			
			float sampleBlur = getBlur(tex);
			float bias = mix(1.0, smoothstep(0.0, 1.0, uWeightSamples[i]), uBias);
			float mul = (1.0 - (1.0 - sampleBlur) * myBlur) * bias;
			
			blur += sampleBlur;
			if (mul > 0.0)
			{
				colorAdd += getColor(tex, sampleBlur) * mul;
				colorDiv += mul;
			}
			weightStrength += bias;
		}
		
		float avgBlur = (weightStrength > 0.0001) ? (blur / weightStrength) : myBlur;
		vec4 gathered = (colorDiv > 0.0001) ? (colorAdd / colorDiv) : centerTex;
		
		// Single decoupled chromatic fringe pass outside the 128-tap disk gather
		if (uFringe > 0 && myBlur > 0.001)
		{
			float fringeScale = clamp(avgBlur + myBlur, 0.0, 1.0) * 0.5;
			float fringeSize = texelSize.x * myBlur * screenSampleSize * 0.35;
			vec2 rOff = vec2(cos(uFringeAngle.x), sin(uFringeAngle.x)) * (uFringeStrength.x * fringeSize);
			vec2 gOff = vec2(cos(uFringeAngle.y), sin(uFringeAngle.y)) * (uFringeStrength.y * fringeSize);
			vec2 bOff = vec2(cos(uFringeAngle.z), sin(uFringeAngle.z)) * (uFringeStrength.z * fringeSize);
			float rFr = texture2D(/* lod0 */gm_BaseTexture, clamp(vTexCoord + rOff, vec2(0.0), vec2(1.0))).r;
			float gFr = texture2D(/* lod0 */gm_BaseTexture, clamp(vTexCoord + gOff, vec2(0.0), vec2(1.0))).g;
			float bFr = texture2D(/* lod0 */gm_BaseTexture, clamp(vTexCoord + bOff, vec2(0.0), vec2(1.0))).b;
			gathered.rgb = mix(gathered.rgb, vec3(rFr, gFr, bFr), 0.35 * clamp(fringeScale, 0.0, 1.0));
		}
		
		gl_FragColor = vec4(gathered.rgb, centerTex.a);
	}
	else
	{
		gl_FragColor = centerTex;
	}
}
