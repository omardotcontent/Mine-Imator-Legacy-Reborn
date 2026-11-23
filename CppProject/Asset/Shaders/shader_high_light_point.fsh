#define SQRT05 0.707106781
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

uniform sampler2D uDepthBufferXp; // static
uniform sampler2D uDepthBufferXn; // static
uniform sampler2D uDepthBufferYp; // static
uniform sampler2D uDepthBufferYn; // static
uniform sampler2D uDepthBufferZp; // static
uniform sampler2D uDepthBufferZn; // static

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

varying vec3 vPosition;
uniform vec4 uMirrorClipPlane; // static
varying vec3 vNormal;
varying vec3 vTangent;
varying float vHasTangent;
varying vec2 vTexCoord;
varying vec4 vColor;
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

vec4 texture2Dmap(int map, vec2 tex)
{
	if (map == 0) return texture2D(uDepthBufferXp, tex);
	else if (map == 1) return texture2D(uDepthBufferXn, tex);
	else if (map == 2) return texture2D(uDepthBufferYp, tex);
	else if (map == 3) return texture2D(uDepthBufferYn, tex);
	else if (map == 4) return texture2D(uDepthBufferZp, tex);
	else return texture2D(uDepthBufferZn, tex);
}

vec2 getShadowMapCoord(vec3 look)
{
	float tFOV = tan(PI / 4.0);
	vec3 u, v, toPoint = vPosition - uLightPosition;
	vec2 coord;
	
	look /= sqrt(dot(look, look));
	u = vec3(-look.z * look.x, -look.z * look.y, 1.0 - look.z * look.z);
	u /= sqrt(dot(u, u));
	u *= tFOV;
	v = vec3(u.y * look.z - look.y * u.z, u.z * look.x - look.z * u.x, u.x * look.y - look.x * u.y);
	
	toPoint /= dot(toPoint, look);
	coord.x = (dot(toPoint, v) / (tFOV * tFOV) + 1.0) / 2.0;
	coord.y = (1.0 - dot(toPoint, u) / (tFOV * tFOV)) / 2.0;
	
	return coord;
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
		
		float shadow = 0.0;
		vec3 L = normalize(uLightPosition - vPosition);
		float ndotl = max(0.0, dot(N, L));
		
		if (uWetness > 0.001 && normalize(vNormal).z > 0.65)
			roughness = mix(roughness, 0.08, uWetness * 0.85);
		
		// Diffuse factor (+ optional Cel-Shading)
		float dif = clamp(ndotl + bleedTotal, 0.0, 1.0);
		if (uCelEnable > 0)
		{
			float steps = max(2.0, uCelSteps);
			float sc = dif * steps;
			dif = clamp((floor(sc) + smoothstep(0.5 - uCelSmooth * 0.48, 0.5 + uCelSmooth * 0.48, fract(sc))) / steps, 0.0, 1.0);
		}
		
		// Attenuation factor
		float att = 1.0 - clamp((distance(vPosition, uLightPosition) - uLightFar * (1.0 - uLightFadeSize)) / max(0.0001, uLightFar * uLightFadeSize), 0.0, 1.0);
		dif *= att;
		
		if (dif > 0.0 && bright < 1.0)
		{
			int depthBuf;
			vec2 fragCoord;
			vec3 toLight = vPosition - uLightPosition;
			vec4 lookDir = vec4(
				toLight.x / max(0.0001, distance(vPosition.xy, uLightPosition.xy)),
				toLight.y / max(0.0001, distance(vPosition.xy, uLightPosition.xy)),
				toLight.z / max(0.0001, distance(vPosition.xz, uLightPosition.xz)),
				toLight.z / max(0.0001, distance(vPosition.yz, uLightPosition.yz))
			);
			
			if (lookDir.z > SQRT05 && lookDir.w > SQRT05)
			{
				depthBuf = 4;
				fragCoord = getShadowMapCoord(vec3(0.0, -0.0001, 1.0));
			}
			else if (lookDir.z < -SQRT05 && lookDir.w < -SQRT05)
			{
				depthBuf = 5;
				fragCoord = getShadowMapCoord(vec3(0.0, -0.0001, -1.0));
			}
			else if (lookDir.x > SQRT05)
			{
				depthBuf = 0;
				fragCoord = getShadowMapCoord(vec3(1.0, 0.0, 0.0));
			}
			else if (lookDir.x < -SQRT05)
			{
				depthBuf = 1;
				fragCoord = getShadowMapCoord(vec3(-1.0, 0.0, 0.0));
			}
			else if (lookDir.y > SQRT05)
			{
				depthBuf = 2;
				fragCoord = getShadowMapCoord(vec3(0.0, 1.0, 0.0));
			}
			else
			{
				depthBuf = 3;
				fragCoord = getShadowMapCoord(vec3(0.0, -1.0, 0.0));
			}
			
			float blurSize = uBlurSize + (0.2 * bleedTotal);
			float fragDepth = distance(vPosition, uLightPosition);
			float sampleSize = blurSize / max(0.0001, fragDepth);
			float bias = (1.0 + 2.0 * blurSize) * uShadowBias;
			
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
				float sampleDepth = uLightNear + (uLightFar - uLightNear) * unpackDepth(texture2Dmap(depthBuf, sampleCoord));
				
				shadow += ((fragDepth - bias) > sampleDepth) ? 1.0 : 0.0;
			}
			
			shadow /= float(q);
		}
		
		float shadowAmt = clamp(shadow * uShadowDarkness, 0.0, 1.0);
		vec3 lightTint = uLightColor.rgb;
		if (uBleedLight > 0.0 && ndotl < 0.25)
			lightTint = mix(lightTint, lightTint * uSubsurfaceColor.rgb, clamp(uBleedLight, 0.0, 1.0));
		
		if (uIsWater == 1)
			light = lightTint * uLightStrength * dif;
		else
			light = lightTint * uLightStrength * dif * (1.0 - shadowAmt);
		
		if (uSpecularEnable > 0 && uIsWater == 0 && shadowAmt < 0.99 && ndotl > 0.0 && att > 0.0)
		{
			vec3 V = normalize(uCameraPosition - vPosition);
			vec3 H = normalize(L + V);
			float shininess = max(2.0, uSpecularShininess * mix(2.5, 0.15, roughness));
			float spec = pow(max(0.0, dot(N, H)), shininess);
			float specMask = (1.0 - roughness * 0.85) * (1.0 + metallic * 1.5);
			light += uLightColor.rgb * uLightStrength * spec * uSpecularStrength * specMask * att * (1.0 - shadowAmt);
		}
		
		light = mix(light, vec3(1.0), bright);
	}
	
	vec4 baseColor = texture2D(uTexture, vTexCoord);
	gl_FragColor = vec4(light, vColor.a * baseColor.a);
	
	if (baseColor.a < 0.05 || gl_FragColor.a < 0.01)
		discard;
}
