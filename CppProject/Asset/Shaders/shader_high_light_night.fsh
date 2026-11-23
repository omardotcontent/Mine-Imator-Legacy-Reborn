uniform sampler2D uTexture; // static
uniform sampler2D uTextureMaterial; // static
uniform sampler2D uTextureNormal; // static

uniform vec3 uCameraPosition; // static
uniform int uUseNormalMap; // static
uniform int uMaterialFormat;
uniform float uDefaultEmissive; // static

uniform int uHemiEnable; // static
uniform float uHemiStrength; // static
uniform vec4 uHemiSkyColor; // static
uniform vec4 uHemiGroundColor; // static

uniform int uRimEnable; // static
uniform float uRimStrength; // static
uniform float uRimPower; // static
uniform vec4 uRimColor; // static

varying vec3 vWorldPos;
varying vec3 vNormal;
varying vec3 vTangent;
varying float vHasTangent;
varying vec2 vTexCoord;
varying vec4 vColor;
varying float vBrightness;

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

float getMaterialEmissive(vec2 uv)
{
	if (uUseNormalMap < 1)
		return 0.0;
	vec4 matColor = texture2D(uTextureMaterial, uv);
	if (uMaterialFormat == 2)
		return (matColor.a < 0.999 ? (matColor.a / 0.9961) : 0.0) * uDefaultEmissive;
	if (uMaterialFormat == 1)
		return matColor.b * uDefaultEmissive;
	return 0.0;
}

void main()
{
	vec4 texCol = texture2D(uTexture, vTexCoord);
	vec4 baseColor = vColor * texCol;
	if (texCol.a < 0.05 || baseColor.a < 0.01)
		discard;
	
	vec3 N = getMappedNormal(vTexCoord);
	float bright = clamp(max(vBrightness, getMaterialEmissive(vTexCoord)), 0.0, 1.0);
	vec3 light = vec3(0.0);
	
	if (uHemiEnable > 0)
	{
		float hemiFactor = clamp(N.z * 0.5 + 0.5, 0.0, 1.0);
		light += mix(uHemiGroundColor.rgb, uHemiSkyColor.rgb, hemiFactor) * uHemiStrength * 0.35;
	}
	
	if (uRimEnable > 0)
	{
		vec3 V = normalize(uCameraPosition - vWorldPos);
		float rim = pow(1.0 - clamp(dot(N, V), 0.0, 1.0), uRimPower) * uRimStrength * 0.45;
		light += uRimColor.rgb * rim;
	}
	
	light = mix(light, vec3(1.0), bright);
	gl_FragColor = vec4(light, baseColor.a);
}
