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
uniform float uLightNear; // static
uniform float uLightFar; // static

uniform sampler2D uDepthBuffer; // static
uniform sampler2D uTransColorBuffer; // static

uniform int uBlurQuality; // static
uniform float uBlurSize; // static
uniform float uShadowBias; // static
uniform float uShadowDarkness; // static
uniform vec4 uShadowTint; // static

uniform int uColoredShadows; // static
uniform float uColoredShadowsStrength; // static

uniform float uDiffuseBoost; // static
uniform float uLightBleedStrength; // static
uniform float uBleedLight;
uniform vec4 uSubsurfaceColor;

// Material & Normal Maps
uniform int uUseNormalMap; // static
uniform int uMaterialFormat;
uniform float uRoughness;
uniform float uMetallic;
uniform float uDefaultEmissive; // static

// Enhanced 1.2.9 Lighting (toggleable)
uniform int uHemiEnable; // static
uniform float uHemiStrength; // static
uniform vec4 uHemiSkyColor; // static
uniform vec4 uHemiGroundColor; // static

uniform int uRimEnable; // static
uniform float uRimStrength; // static
uniform float uRimPower; // static
uniform vec4 uRimColor; // static

uniform int uSpecularEnable; // static
uniform float uSpecularStrength; // static
uniform float uSpecularShininess; // static

// Cloud Shadows (projects actual sky clouds texture aligned with background_sky_update)
uniform sampler2D uCloudTexture; // static
uniform int uCloudShadows; // static
uniform float uCloudShadowsStrength; // static
uniform float uCloudShadowsScale; // static
uniform float uCloudTileSize; // static
uniform float uCloudOffset; // static
uniform float uCloudHeight; // static
uniform vec3 uSunDir; // static

// Water Ripples & Wetness / Rain Puddles
uniform float uRippleTime; // static
uniform int uWaterRipples; // static
uniform float uWaterRippleStrength; // static
uniform float uWaterRippleSpeed; // static
uniform float uWetness; // static
uniform int uWetnessRipples; // static

// Anime / Toon Cel-Shading
uniform int uCelEnable; // static
uniform float uCelSteps; // static
uniform float uCelSmooth; // static

varying vec3 vPosition;
uniform vec4 uMirrorClipPlane; // static
varying vec3 vWorldPos;
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

float hash21(vec2 p)
{
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float valueNoise(vec2 p)
{
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float getCloudShadowFactor(vec3 wp)
{
	if (uCloudShadows < 1 || uSunDir.z <= 0.05 || uCloudTileSize <= 1.0)
		return 0.0;
	
	// Exact intersection of sun ray from world point wp with cloud plane z = uCloudHeight
	float tHit = max(0.0, (uCloudHeight - wp.z) / max(0.08, uSunDir.z));
	vec2 cloudPos = wp.xy + uSunDir.xy * tHit;
	
	// Exact tile UV matching background_sky_update.gml: xo = k*size, yo = k*size - offset
	vec2 baseUV = vec2(cloudPos.x / uCloudTileSize, (cloudPos.y + uCloudOffset) / uCloudTileSize);
	
	// Soft penumbra filter radius controlled by uCloudShadowsScale (default 1.0 = natural soft cloud edge)
	float blur = 0.0045 * clamp(uCloudShadowsScale, 0.1, 4.0);
	float acc = 0.0;
	acc += texture2D(uCloudTexture, baseUV).a * 0.24;
	acc += texture2D(uCloudTexture, baseUV + vec2( blur,  0.0)).a * 0.11;
	acc += texture2D(uCloudTexture, baseUV + vec2(-blur,  0.0)).a * 0.11;
	acc += texture2D(uCloudTexture, baseUV + vec2( 0.0,  blur)).a * 0.11;
	acc += texture2D(uCloudTexture, baseUV + vec2( 0.0, -blur)).a * 0.11;
	acc += texture2D(uCloudTexture, baseUV + vec2( blur * 0.7,  blur * 0.7)).a * 0.08;
	acc += texture2D(uCloudTexture, baseUV + vec2(-blur * 0.7,  blur * 0.7)).a * 0.08;
	acc += texture2D(uCloudTexture, baseUV + vec2( blur * 0.7, -blur * 0.7)).a * 0.08;
	acc += texture2D(uCloudTexture, baseUV + vec2(-blur * 0.7, -blur * 0.7)).a * 0.08;
	
	// Fade out smoothly when sun is very low on horizon
	float sunFade = smoothstep(0.05, 0.22, uSunDir.z);
	return clamp(acc, 0.0, 1.0) * uCloudShadowsStrength * sunFade;
}

float puddleMask(vec2 wp)
{
	float n = valueNoise(wp * 0.022) * 0.65 + valueNoise(wp * 0.058 + vec2(7.3, 19.1)) * 0.35;
	return smoothstep(0.92 - uWetness * 0.80, 0.98 - uWetness * 0.42, n);
}

vec2 getWaterRippleOffset(vec2 wp, float t)
{
	float w1 = sin(wp.x * 0.32 + wp.y * 0.20 + t * 2.4);
	float w2 = cos(wp.x * 0.19 - wp.y * 0.38 + t * 3.1);
	float w3 = sin((wp.x + wp.y) * 0.62 - t * 4.2);
	float w4 = cos((wp.x - wp.y) * 0.48 + t * 2.8);
	return vec2(w1 + w3 * 0.55 + w4 * 0.35, w2 - w3 * 0.55 + w4 * 0.35);
}

vec2 getRainRippleLayer(vec2 wp, float t, float scale, float offset)
{
	vec2 p = wp * scale + vec2(offset * 17.3, offset * 9.7);
	vec2 cell = floor(p);
	vec2 local = fract(p) - 0.5;
	float phase = fract(t * 0.85 + hash21(cell));
	float dist = length(local);
	float radius = phase * 0.48;
	float ring = sin((dist - radius) * 38.0) * exp(-abs(dist - radius) * 14.0) * (1.0 - phase) * step(dist, 0.48);
	vec2 dir = (dist > 0.001) ? (local / dist) : vec2(0.0);
	return dir * ring;
}

vec2 getRainRippleOffset(vec2 wp, float t)
{
	return getRainRippleLayer(wp, t, 0.16, 0.0) + getRainRippleLayer(wp, t * 1.13, 0.23, 3.7) * 0.75;
}

vec3 getMappedNormal(vec2 uv, float wetMask)
{
	vec3 N = normalize(vNormal);
	vec3 T = (vHasTangent > 0.5) ? normalize(vTangent - dot(vTangent, N) * N) : normalize(cross(abs(N.y) < 0.9 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0), N));
	vec3 B = cross(T, N);
	
	if (uUseNormalMap > 0 && vHasTangent > 0.5)
	{
		vec4 n = texture2D(uTextureNormal, uv);
		if (n.a >= 0.01)
		{
			n.xy = n.xy * 2.0 - 1.0;
			n.z = sqrt(max(0.0, 1.0 - dot(n.xy, n.xy)));
			n.y *= -1.0;
			N = normalize(mat3(T, B, N) * n.xyz);
		}
	}
	
	if (uIsWater > 0 && uWaterRipples > 0)
	{
		vec2 rip = getWaterRippleOffset(vWorldPos.xy, uRippleTime * uWaterRippleSpeed) * (0.24 * uWaterRippleStrength);
		N = normalize(N + T * rip.x + B * rip.y);
	}
	else if (wetMask > 0.05 && uWetnessRipples > 0)
	{
		vec2 rip = getRainRippleOffset(vWorldPos.xy, uRippleTime) * (0.45 * wetMask);
		N = normalize(N + T * rip.x + B * rip.y);
	}
	
	return N;
}

float applyCel(float d)
{
	if (uCelEnable < 1)
		return d;
	float steps = max(2.0, uCelSteps);
	float scaled = d * steps;
	float band = floor(scaled);
	float fracPart = fract(scaled);
	float edge = smoothstep(0.5 - uCelSmooth * 0.48, 0.5 + uCelSmooth * 0.48, fracPart);
	return clamp((band + edge) / steps, 0.0, 1.0);
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
	if (uMaterialFormat == 2) // LabPBR
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
	else if (uMaterialFormat == 1) // SEUS
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
		float upMask = smoothstep(0.60, 0.85, normalize(vNormal).z);
		float wetMask = (uWetness > 0.001) ? (puddleMask(vWorldPos.xy) * upMask * uWetness) : 0.0;
		
		vec3 N = getMappedNormal(vTexCoord, wetMask);
		float roughness, metallic, matEmissive, matSss;
		getMaterial(vTexCoord, roughness, metallic, matEmissive, matSss);
		
		// Wetness makes puddles glossy & low-roughness
		if (wetMask > 0.001)
			roughness = mix(roughness, 0.06, wetMask);
		if (uIsWater > 0)
			roughness = 0.08;
		
		float bright = clamp(max(vBrightness, matEmissive), 0.0, 1.0);
		float bleedTotal = clamp((vLightBleed + uBleedLight + matSss) * uLightBleedStrength, 0.0, 1.0);
		
		vec3 L = normalize(uLightPosition - vPosition);
		
		// Diffuse factor (+ optional Cel-Shading quantization)
		float ndotl = max(0.0, dot(N, L));
		float dif = applyCel(clamp(ndotl + bleedTotal, 0.0, 1.0));
		
		float shadow = 0.0;
		vec3 transTint = vec3(1.0);
		
		if (dif > 0.0 && bright < 1.0)
		{
			dif *= uDiffuseBoost;
			
			float fragDepth = min(vScreenCoord.z, uLightFar);
			vec2 fragCoord = (vec2(vScreenCoord.x, -vScreenCoord.y) / vScreenCoord.z + 1.0) / 2.0;
			
			if (fragCoord.x > 0.0 && fragCoord.y > 0.0 && fragCoord.x < 1.0 && fragCoord.y < 1.0)
			{
				float blurSize = uBlurSize + (0.2 * bleedTotal);
				float bias = (1.0 + (uLightFar / max(0.0001, fragDepth)) * blurSize) * uShadowBias;
				float sampleSize = blurSize / max(0.0001, fragDepth);
				
				int q = clamp(uBlurQuality, 1, MAXSAMPLES);
				float noiseAngle = worldNoise(vWorldPos) * TAU;
				
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
				
				// Stained Glass / Translucent Colored Shadows
				if (uColoredShadows > 0 && shadow < 0.99)
				{
					vec3 tc = texture2D(uTransColorBuffer, fragCoord).rgb;
					transTint = mix(vec3(1.0), tc, clamp(uColoredShadowsStrength, 0.0, 2.0));
				}
			}
		}
		
		// Cloud Shadows projected onto terrain & characters
		float cloudSh = getCloudShadowFactor(vWorldPos);
		float shadowAmt = clamp(max(shadow * uShadowDarkness, cloudSh), 0.0, 1.0);
		
		// Subsurface tint for light-bleeding objects
		vec3 sunTint = uLightColor.rgb * transTint;
		if (uBleedLight > 0.0 && ndotl < 0.25)
			sunTint = mix(sunTint, sunTint * uSubsurfaceColor.rgb, clamp(uBleedLight, 0.0, 1.0));
		
		// Calculate primary sun light
		if (uIsWater == 1)
			light = sunTint * dif * (1.0 - cloudSh * 0.6);
		else
			light = sunTint * dif * (1.0 - shadowAmt) + uShadowTint.rgb * shadowAmt;
		
		// Soft Specular Sheen (active if Specular ON, Water Ripples ON, or Wet Puddles > 0)
		bool doSpec = (uSpecularEnable > 0) || (wetMask > 0.05) || (uIsWater > 0 && uWaterRipples > 0);
		if (doSpec && shadowAmt < 0.99 && ndotl > 0.0)
		{
			vec3 V = normalize(uCameraPosition - vWorldPos);
			vec3 H = normalize(L + V);
			float specStr = (uSpecularEnable > 0) ? uSpecularStrength : 0.0;
			if (wetMask > 0.05)
				specStr = max(specStr, wetMask * 0.85);
			if (uIsWater > 0 && uWaterRipples > 0)
				specStr = max(specStr, 0.90);
			float shininess = max(2.0, uSpecularShininess * mix(3.0, 0.15, roughness));
			float spec = pow(max(0.0, dot(N, H)), shininess);
			float specMask = (1.0 - roughness * 0.85) * (1.0 + metallic * 1.5);
			light += sunTint * spec * specStr * specMask * (1.0 - shadowAmt) * uDiffuseBoost;
		}
		
		// Hemisphere Sky/Ground Ambient lift
		if (uHemiEnable > 0)
		{
			float hemiFactor = clamp(N.z * 0.5 + 0.5, 0.0, 1.0);
			vec3 hemi = mix(uHemiGroundColor.rgb, uHemiSkyColor.rgb, hemiFactor) * uHemiStrength;
			light += hemi;
		}
		
		// Rim / Fresnel Backlight
		if (uRimEnable > 0)
		{
			vec3 V = normalize(uCameraPosition - vWorldPos);
			float rim = pow(1.0 - clamp(dot(N, V), 0.0, 1.0), uRimPower) * uRimStrength;
			light += uRimColor.rgb * rim * (1.0 - shadowAmt * 0.65);
		}
		
		light = mix(light, vec3(1.0), bright);
	}
	
	vec4 baseColor = texture2D(uTexture, vTexCoord);
	gl_FragColor = vec4(light, vColor.a * baseColor.a);
	
	if (gl_FragColor.a == 0.0)
		discard;
}
