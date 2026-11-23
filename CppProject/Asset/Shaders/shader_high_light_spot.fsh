#define PI 3.14159265
#define TAU 6.28318530
#define GOLDEN_ANGLE 2.39996323
#define MAXSAMPLES 128

uniform sampler2D uTexture; // static
uniform sampler2D uTextureMaterial; // static
uniform sampler2D uTextureNormal; // static
uniform int uIsSky;
uniform int uIsWater;

uniform vec3 uCameraPosition; // static
uniform vec3 uLightPosition; // static
uniform vec4 uLightColor; // static
uniform float uLightStrength; // static
uniform float uLightNear; // static
uniform float uLightFar; // static
uniform float uLightFadeSize; // static
uniform float uLightSpotSharpness; // static

uniform sampler2D uDepthBuffer; // static

uniform int uBlurQuality; // static
uniform float uBlurSize; // static
uniform float uShadowBias; // static
uniform float uShadowDarkness; // static

uniform float uLightBleedStrength; // static
uniform float uBleedLight;
uniform vec4 uSubsurfaceColor;

uniform int uUseNormalMap; // static
uniform int uMaterialFormat;
uniform float uRoughness;
uniform float uMetallic;
uniform float uDefaultEmissive; // static

uniform int uSpecularEnable; // static
uniform float uSpecularStrength; // static
uniform float uSpecularShininess; // static

uniform float uWetness; // static
uniform int uCelEnable; // static
uniform float uCelSteps; // static
uniform float uCelSmooth; // static

uniform int uGoboMode; // static
uniform float uGoboScale; // static
uniform float uGoboAngle; // static
uniform float uGoboTime; // static
uniform sampler2D uGoboTexture; // static

varying vec3 vPosition;
uniform vec4 uMirrorClipPlane; // static
varying vec3 vNormal;
varying vec3 vTangent;
varying float vHasTangent;
varying vec2 vTexCoord;
varying vec4 vColor;
varying vec4 vScreenCoord;
varying float vBrightness;
varying float vLightBleed;

float unpackDepth(vec4 c)
{
	return c.r + c.g / 255.0 + c.b / (255.0 * 255.0);
}

float worldNoise(vec3 p)
{
	vec2 q = floor(p.xy * 16.0 + p.z * 7.31);
	return fract(52.9829189 * fract(dot(q, vec2(0.06711056, 0.00583715))));
}

float hash21Gobo(vec2 p)
{
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise2DGobo(vec2 p)
{
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21Gobo(i);
	float b = hash21Gobo(i + vec2(1.0, 0.0));
	float c = hash21Gobo(i + vec2(0.0, 1.0));
	float d = hash21Gobo(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

vec3 evalSpotGobo(vec2 uv)
{
	if (uGoboMode <= 0)
		return vec3(1.0);
	vec2 c = (uv - 0.5) * max(0.1, uGoboScale);
	float ca = cos(uGoboAngle);
	float sa = sin(uGoboAngle);
	vec2 ruv = vec2(c.x * ca - c.y * sa, c.x * sa + c.y * ca) + 0.5;
	if (uGoboMode == 1) // Window Blinds
	{
		float slats = smoothstep(0.28, 0.38, fract(ruv.y * 9.0)) * (1.0 - smoothstep(0.88, 0.96, fract(ruv.y * 9.0)));
		float vbar = smoothstep(0.025, 0.045, abs(ruv.x - 0.5));
		float frame = smoothstep(0.02, 0.05, ruv.x) * smoothstep(0.02, 0.05, 1.0 - ruv.x) * smoothstep(0.02, 0.05, ruv.y) * smoothstep(0.02, 0.05, 1.0 - ruv.y);
		return vec3(slats * vbar * frame);
	}
	else if (uGoboMode == 2) // Tree Canopy Leaves (swaying in wind)
	{
		vec2 w1 = vec2(sin(uGoboTime * 0.8), cos(uGoboTime * 0.6)) * 0.18;
		vec2 w2 = vec2(cos(uGoboTime * 1.1), sin(uGoboTime * 0.9)) * 0.12;
		float n = noise2DGobo(ruv * 5.0 + w1) * 0.6 + noise2DGobo(ruv * 11.0 - w2) * 0.4;
		return vec3(smoothstep(0.38, 0.62, n));
	}
	else if (uGoboMode == 3) // Animated Water Caustics
	{
		vec2 p1 = ruv * 6.0 + vec2(uGoboTime * 0.4, uGoboTime * 0.3);
		vec2 p2 = ruv * 6.5 - vec2(uGoboTime * 0.35, -uGoboTime * 0.45);
		float c1 = abs(noise2DGobo(p1) - 0.5);
		float c2 = abs(noise2DGobo(p2) - 0.5);
		float caust = pow(clamp(1.0 - min(c1, c2) * 3.2, 0.0, 1.0), 2.2);
		return vec3(0.25 + caust * 1.35);
	}
	else if (uGoboMode == 4) // Stained Glass Cathedral Window
	{
		vec2 cell = fract(ruv * 4.0);
		vec2 id = floor(ruv * 4.0);
		float lead = smoothstep(0.04, 0.09, cell.x) * smoothstep(0.04, 0.09, 1.0 - cell.x) * smoothstep(0.04, 0.09, cell.y) * smoothstep(0.04, 0.09, 1.0 - cell.y);
		float h = hash21Gobo(id);
		vec3 paneCol = 0.55 + 0.45 * cos(TAU * (h + vec3(0.0, 0.33, 0.67)));
		return paneCol * lead;
	}
	else if (uGoboMode == 5) // Soft Flashlight Cookie
	{
		float d = length(ruv - 0.5) * 2.0;
		float hotspot = exp(-d * d * 3.5);
		float ring = smoothstep(0.75, 0.88, d) * (1.0 - smoothstep(0.90, 1.0, d)) * 0.45;
		return vec3(clamp(hotspot + ring, 0.0, 1.0));
	}
	else if (uGoboMode == 6) // Custom Texture or Video Track
	{
		vec4 tex = texture2D(uGoboTexture, clamp(ruv, 0.0, 1.0));
		return tex.rgb * tex.a;
	}
	return vec3(1.0);
}

vec3 getMappedNormal(vec2 uv)
{
	vec3 N = normalize(vNormal);
	if (uUseNormalMap < 1 || vHasTangent < 0.5)
		return N;
	vec4 n = texture2D(uTextureNormal, uv);
	if (n.a < 0.01)
		return N;
	n.xy = n.xy * 2.0 - 1.0;
	n.z = sqrt(max(0.0, 1.0 - dot(n.xy, n.xy)));
	n.y *= -1.0;
	vec3 T = normalize(vTangent - dot(vTangent, N) * N);
	vec3 B = cross(T, N);
	return normalize(T * n.x + B * n.y + N * n.z);
}

void getMaterial(vec2 uv, out float roughness, out float metallic, out float matEmissive, out float matSss)
{
	roughness = uRoughness;
	metallic = uMetallic;
	matEmissive = 0.0;
	matSss = 0.0;
	
	if (uUseNormalMap < 1)
		return;
	
	vec4 matColor = texture2D(uTextureMaterial, uv);
	if (uMaterialFormat == 2)
	{
		roughness = pow(1.0 - matColor.r, 2.0);
		if (matColor.g > 0.898)
			metallic = 1.0;
		else
		{
			metallic = 0.0;
			matSss = (matColor.b > 0.255) ? ((matColor.b - 0.255) / 0.745) : 0.0;
		}
		matEmissive = (matColor.a < 0.999 ? (matColor.a / 0.9961) : 0.0) * uDefaultEmissive;
	}
	else if (uMaterialFormat == 1)
	{
		roughness = 1.0 - matColor.r;
		metallic = matColor.g;
		matEmissive = matColor.b * uDefaultEmissive;
	}
}

void main()
{
	if (uIsSky < 1 && dot(uMirrorClipPlane.xyz, uMirrorClipPlane.xyz) > 0.25 && dot(vPosition, uMirrorClipPlane.xyz) + uMirrorClipPlane.w < -0.25)
		discard;
	vec3 light;
	
	if (uIsSky > 0)
		light = vec3(1.0);
	else
	{
		vec3 N = getMappedNormal(vTexCoord);
		float roughness, metallic, matEmissive, matSss;
		getMaterial(vTexCoord, roughness, metallic, matEmissive, matSss);
		
		float bright = clamp(max(vBrightness, matEmissive), 0.0, 1.0);
		float bleedTotal = clamp((vLightBleed + uBleedLight + matSss) * uLightBleedStrength, 0.0, 1.0);
		
		float dif = 0.0;
		float shadow = 0.0;
		float coneAtt = 0.0;
		vec3 goboMult = vec3(1.0);
		vec3 L = normalize(uLightPosition - vPosition);
		float ndotl = max(0.0, dot(N, L));
		
		// Check if not behind the spot light
		if (vScreenCoord.w > 0.0)
		{
			if (uWetness > 0.001 && normalize(vNormal).z > 0.65)
				roughness = mix(roughness, 0.08, uWetness * 0.85);
			dif = clamp(ndotl + bleedTotal, 0.0, 1.0);
			if (uCelEnable > 0)
			{
				float steps = max(2.0, uCelSteps);
				float sc = dif * steps;
				dif = clamp((floor(sc) + smoothstep(0.5 - uCelSmooth * 0.48, 0.5 + uCelSmooth * 0.48, fract(sc))) / steps, 0.0, 1.0);
			}
			float distAtt = 1.0 - clamp((distance(vPosition, uLightPosition) - uLightFar * (1.0 - uLightFadeSize)) / max(0.0001, uLightFar * uLightFadeSize), 0.0, 1.0);
			dif *= distAtt;
			
			if (dif > 0.0 && bright < 1.0)
			{
				float fragDepth = min(vScreenCoord.z, uLightFar);
				vec2 fragCoord = (vec2(vScreenCoord.x, -vScreenCoord.y) / vScreenCoord.z + 1.0) / 2.0;
				
				if (fragCoord.x > 0.0 && fragCoord.y > 0.0 && fragCoord.x < 1.0 && fragCoord.y < 1.0)
				{
					float blurSize = uBlurSize + (0.2 * bleedTotal);
					
					coneAtt = (1.0 - clamp((distance(fragCoord, vec2(0.5, 0.5)) - 0.5 * uLightSpotSharpness) / (0.5 * max(0.01, 1.0 - uLightSpotSharpness)), 0.0, 1.0)) * distAtt;
					dif *= 1.0 - clamp((distance(fragCoord, vec2(0.5, 0.5)) - 0.5 * uLightSpotSharpness) / (0.5 * max(0.01, 1.0 - uLightSpotSharpness)), 0.0, 1.0);
					if (uGoboMode > 0)
						goboMult = evalSpotGobo(fragCoord);
					
					float bias = (0.1 * (uLightFar / max(0.0001, fragDepth))) * uShadowBias;
					float sampleSize = blurSize / max(0.0001, fragDepth);
					
					int q = clamp(uBlurQuality, 1, MAXSAMPLES);
					float noiseAngle = worldNoise(vPosition) * TAU;
					
					for (int i = 0; i < MAXSAMPLES; i++)
					{
						if (i >= q)
							break;
						
						float r = sqrt((float(i) + 0.5) / float(q));
						float angle = float(i) * GOLDEN_ANGLE + noiseAngle;
						vec2 off = vec2(cos(angle), sin(angle)) * r;
						
						vec2 sampleCoord = fragCoord + off * sampleSize;
						float sampleDepth = uLightNear + unpackDepth(texture2D(uDepthBuffer, sampleCoord)) * (uLightFar - uLightNear);
						
						shadow += ((fragDepth - bias) > sampleDepth) ? 1.0 : 0.0;
					}
					
					shadow /= float(q);
				}
				else
					dif = 0.0;
			}
		}
		
		float shadowAmt = clamp(shadow * uShadowDarkness, 0.0, 1.0);
		vec3 lightTint = uLightColor.rgb * goboMult;
		if (uBleedLight > 0.0 && ndotl < 0.25)
			lightTint = mix(lightTint, lightTint * uSubsurfaceColor.rgb, clamp(uBleedLight, 0.0, 1.0));
		
		if (uIsWater == 1)
			light = lightTint * uLightStrength * dif;
		else
			light = lightTint * uLightStrength * dif * (1.0 - shadowAmt);
		
		if (uSpecularEnable > 0 && uIsWater == 0 && shadowAmt < 0.99 && ndotl > 0.0 && coneAtt > 0.0)
		{
			vec3 V = normalize(uCameraPosition - vPosition);
			vec3 H = normalize(L + V);
			float shininess = max(2.0, uSpecularShininess * mix(2.5, 0.15, roughness));
			float spec = pow(max(0.0, dot(N, H)), shininess);
			float specMask = (1.0 - roughness * 0.85) * (1.0 + metallic * 1.5);
			light += uLightColor.rgb * uLightStrength * spec * uSpecularStrength * specMask * coneAtt * (1.0 - shadowAmt);
		}
		
		light = mix(light, vec3(1.0), bright);
	}
	
	vec4 baseColor = texture2D(uTexture, vTexCoord);
	gl_FragColor = vec4(light, vColor.a * baseColor.a);
	
	if (baseColor.a < 0.05 || gl_FragColor.a < 0.01)
		discard;
}
