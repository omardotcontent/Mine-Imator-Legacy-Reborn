#define MAXSAMPLES 96

varying vec2 vTexCoord;

uniform sampler2D uOcclusionMask;
uniform vec2 uSunScreenPos;
uniform vec4 uSunColor;
uniform int uSamples;
uniform float uDensity;
uniform float uDecay;
uniform float uWeight;
uniform float uExposure;
uniform float uSunVisibility;

float screenNoise(vec2 uv)
{
	return fract(52.9829189 * fract(dot(uv * 512.0, vec2(0.06711056, 0.00583715))));
}

void main()
{
	vec4 baseColor = texture2D(gm_BaseTexture, vTexCoord);
	
	if (uSunVisibility <= 0.001 || uExposure <= 0.001)
	{
		gl_FragColor = baseColor;
		return;
	}
	
	int sampleCount = clamp(uSamples, 8, MAXSAMPLES);
	vec2 deltaTexCoord = (vTexCoord - uSunScreenPos);
	deltaTexCoord *= (1.0 / float(sampleCount)) * uDensity;
	
	// Dither starting point slightly to eliminate radial banding
	float jitter = screenNoise(vTexCoord);
	vec2 texCoord = vTexCoord - deltaTexCoord * jitter;
	
	float illuminationDecay = 1.0;
	float shafts = 0.0;
	
	for (int i = 0; i < MAXSAMPLES; i++)
	{
		if (i >= sampleCount)
			break;
		
		texCoord -= deltaTexCoord;
		
		// Clamp inside screen bounds
		if (texCoord.x >= 0.0 && texCoord.x <= 1.0 && texCoord.y >= 0.0 && texCoord.y <= 1.0)
		{
			// Occlusion mask: 0 = sky (unoccluded), 1 = geometry (occluded)
			float occ = texture2D(uOcclusionMask, texCoord).r;
			float skyOpen = 1.0 - occ;
			
			// Concentrate energy smoothly near the sun disc while still allowing wide rays
			float distToSun = distance(texCoord, uSunScreenPos);
			float radialFalloff = exp(-distToSun * 1.65);
			
			shafts += skyOpen * radialFalloff * illuminationDecay * uWeight;
		}
		
		illuminationDecay *= uDecay;
	}
	
	vec3 rayColor = uSunColor.rgb * (shafts * uExposure * uSunVisibility);
	gl_FragColor = vec4(baseColor.rgb + rayColor, baseColor.a);
}
