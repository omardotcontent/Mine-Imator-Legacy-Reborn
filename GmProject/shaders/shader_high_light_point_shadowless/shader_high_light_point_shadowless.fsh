uniform sampler2D uTexture; // static
uniform sampler2D uTextureMaterial; // static
uniform sampler2D uTextureNormal; // static

uniform int uIsSky;

uniform vec3 uCameraPosition; // static
uniform int uLightAmount; // static
uniform vec4 uLightData[128]; // static

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

varying vec3 vPosition;
uniform vec4 uMirrorClipPlane; // static
varying vec3 vNormal;
varying vec3 vTangent;
varying float vHasTangent;
varying vec4 vColor;
varying vec2 vTexCoord;
varying float vBrightness;
varying float vLightBleed;

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
	return normalize(mat3(T, B, N) * n.xyz);
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
	vec4 baseColor = vColor * texture2D(uTexture, vTexCoord);
	if (baseColor.a == 0.0)
		discard;
	
	vec3 lightResult = vec3(0.0);
	
	if (uIsSky > 0)
		lightResult = vec3(1.0);
	else
	{
		vec3 N = getMappedNormal(vTexCoord);
		float roughness, metallic, matEmissive, matSss;
		getMaterial(vTexCoord, roughness, metallic, matEmissive, matSss);
		
		float bright = clamp(max(vBrightness, matEmissive), 0.0, 1.0);
		float bleedTotal = clamp((vLightBleed + uBleedLight + matSss) * uLightBleedStrength, 0.0, 1.0);
		vec3 V = normalize(uCameraPosition - vPosition);
		float shininess = max(2.0, uSpecularShininess * mix(2.5, 0.15, roughness));
		float specMask = (1.0 - roughness * 0.85) * (1.0 + metallic * 1.5);
		
		for (int i = 0; i < uLightAmount; i++)
		{
			vec4 data1 = uLightData[i * 2];
			vec4 data2 = uLightData[i * 2 + 1];
			vec3 lightPosition = data1.xyz;
			float lightRange = data1.w;
			float lightFadeSize = data2.w;
			
			float dist = distance(vPosition, lightPosition);
			if (dist > lightRange)
				continue;
			
			vec3 L = normalize(lightPosition - vPosition);
			float ndotl = max(0.0, dot(N, L));
			float dif = clamp(ndotl + bleedTotal, 0.0, 1.0);
			float att = 1.0 - clamp((dist - lightRange * (1.0 - lightFadeSize)) / max(0.0001, lightRange * lightFadeSize), 0.0, 1.0);
			dif *= att;
			
			vec3 lightTint = data2.rgb;
			if (uBleedLight > 0.0 && ndotl < 0.25)
				lightTint = mix(lightTint, lightTint * uSubsurfaceColor.rgb, clamp(uBleedLight, 0.0, 1.0));
			
			vec3 light = lightTint * dif;
			
			if (uSpecularEnable > 0 && ndotl > 0.0 && att > 0.0)
			{
				vec3 H = normalize(L + V);
				float spec = pow(max(0.0, dot(N, H)), shininess);
				light += data2.rgb * spec * uSpecularStrength * specMask * att;
			}
			
			light = mix(light, vec3(1.0), bright);
			lightResult.rgb += light;
		}
	}
	
	gl_FragColor = vec4(lightResult, baseColor.a);
}
