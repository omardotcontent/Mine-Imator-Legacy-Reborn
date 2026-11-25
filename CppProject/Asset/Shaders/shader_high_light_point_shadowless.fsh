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

#define PI 3.14159265

uniform int uUseNormalMap; // static
uniform int uMaterialFormat;
uniform float uRoughness;
uniform float uMetallic;
uniform float uDefaultEmissive; // static
uniform float uPbrNormalStrength; // static
uniform int uPbrPomEnable; // static
uniform float uPbrPomDepth; // static
uniform int uPbrPomSamples; // static
uniform float uPbrEmissiveStrength; // static
uniform float uPbrAoStrength; // static
uniform vec2 uPbrTileGrid;
uniform vec4 uPbrMatOverride;

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

vec2 clampTileUV(vec2 cand, vec2 tileMin, vec2 tileMax, vec2 grid, bool clampToTile)
{
	if (!clampToTile)
		return cand;
	vec2 pad = vec2(0.0005) / grid;
	return clamp(cand, tileMin + pad, tileMax - pad);
}

vec2 getPomUV(vec2 uv, vec3 viewDir, vec3 geomN, vec3 geomT, float hasT)
{
	if (uUseNormalMap < 1 || uPbrPomEnable < 1 || hasT < 0.5 || uPbrPomDepth <= 0.0001)
		return uv;
	if (texture2D(/* lod0 */uTexture, uv).a < 0.5)
		return uv;
	float h0 = texture2D(/* lod0 */uTextureNormal, uv).a;
	if (h0 < 0.005 || h0 >= 0.996)
		return uv;
	vec3 N = normalize(geomN);
	vec3 T = normalize(geomT - dot(geomT, N) * N);
	vec3 Bv = cross(N, T);
	float ndotv = dot(viewDir, N);
	if (ndotv <= 0.05)
		return uv;
	bool clampToTile = (uPbrTileGrid.x > 1.5 || uPbrTileGrid.y > 1.5);
	vec2 gridAbs = max(vec2(1.0), abs(uPbrTileGrid));
	vec2 tileIdx = floor(uv * gridAbs);
	vec2 tileMin = tileIdx / gridAbs;
	vec2 tileMax = (tileIdx + 1.0) / gridAbs;
	float grazingFade = smoothstep(0.05, 0.35, ndotv);
	vec2 viewTS = vec2(dot(viewDir, T), dot(viewDir, Bv)) / (ndotv + 0.45);
	vec2 maxOffset = -viewTS * ((uPbrPomDepth * grazingFade) / gridAbs);
	int numSteps = clamp(uPbrPomSamples, 4, 32);
	float layerStep = 1.0 / float(numSteps);
	vec2 uvStep = maxOffset * layerStep;
	float currLayerDepth = 0.0;
	vec2 currUV = uv;
	float currDepthVal = 1.0 - h0;
	vec2 prevUV = uv;
	float prevDepthVal = currDepthVal;
	float prevLayerDepth = 0.0;
	bool hit = false;
	for (int i = 0; i < 32; i++)
	{
		if (i >= numSteps || currLayerDepth >= currDepthVal)
		{
			hit = (currLayerDepth >= currDepthVal);
			break;
		}
		vec2 candUV = clampTileUV(uv + uvStep * float(i + 1), tileMin, tileMax, gridAbs, clampToTile);
		float candAlpha = texture2D(/* lod0 */uTexture, candUV).a;
		float hs = texture2D(/* lod0 */uTextureNormal, candUV).a;
		if (candAlpha < 0.5 || hs < 0.005)
			break;
		prevUV = currUV;
		prevDepthVal = currDepthVal;
		prevLayerDepth = currLayerDepth;
		currUV = candUV;
		currLayerDepth += layerStep;
		currDepthVal = 1.0 - hs;
		if (currLayerDepth >= currDepthVal)
		{
			hit = true;
			break;
		}
	}
	if (hit && currLayerDepth > prevLayerDepth)
	{
		for (int b = 0; b < 5; b++)
		{
			vec2 midUV = 0.5 * (prevUV + currUV);
			float midLayer = 0.5 * (prevLayerDepth + currLayerDepth);
			float midA = texture2D(/* lod0 */uTexture, midUV).a;
			float midH = texture2D(/* lod0 */uTextureNormal, midUV).a;
			float midDepth = (midA < 0.5 || midH < 0.005) ? 0.0 : (1.0 - midH);
			if (midLayer >= midDepth)
			{
				currUV = midUV;
				currLayerDepth = midLayer;
				currDepthVal = midDepth;
			}
			else
			{
				prevUV = midUV;
				prevLayerDepth = midLayer;
				prevDepthVal = midDepth;
			}
		}
		float afterDiff = currDepthVal - currLayerDepth;
		float beforeDiff = prevDepthVal - prevLayerDepth;
		float denom = afterDiff - beforeDiff;
		float weight = (abs(denom) > 0.00001) ? clamp(afterDiff / denom, 0.0, 1.0) : 0.0;
		currUV = mix(currUV, prevUV, weight);
	}
	if (texture2D(/* lod0 */uTexture, currUV).a < 0.5)
		return uv;
	return currUV;
}

vec3 getMappedNormal(vec2 uv)
{
	vec3 N = normalize(vNormal);
	if (uUseNormalMap < 1 || vHasTangent < 0.5)
		return N;
	vec4 n = texture2D(uTextureNormal, uv);
	if (n.a < 0.01)
		return N;
	vec2 nxy = (n.xy * 2.0 - 1.0) * (uPbrNormalStrength * max(0.0, uPbrMatOverride.w));
	if (uPbrMatOverride.z < 0.5)
		nxy.y *= -1.0;
	float len2 = dot(nxy, nxy);
	float nz = (len2 < 0.999) ? sqrt(1.0 - len2) : 0.03;
	vec3 tn = normalize(vec3(nxy, nz));
	vec3 T = normalize(vTangent - dot(vTangent, N) * N);
	vec3 B = cross(T, N);
	return normalize(T * tn.x + B * tn.y + N * tn.z);
}

void getPbrMaterial(vec2 uv, out float roughness, out float metallic, out float f0, out vec3 metalTint, out float matEmissive, out float matSss, out float matAo)
{
	roughness = clamp(uRoughness, 0.02, 1.0);
	metallic = clamp(uMetallic, 0.0, 1.0);
	f0 = mix(0.04, 0.85, metallic);
	metalTint = vec3(1.0);
	matEmissive = 0.0;
	matSss = 0.0;
	matAo = 1.0;
	
	if (uUseNormalMap > 0)
	{
		vec4 matCol = texture2D(uTextureMaterial, uv);
		vec4 nrmCol = texture2D(uTextureNormal, uv);
		if (uMaterialFormat == 2)
		{
			roughness = clamp(pow(1.0 - matCol.r, 2.0), 0.02, 1.0);
			float gByte = floor(matCol.g * 255.0 + 0.5);
			if (gByte < 229.5)
			{
				metallic = 0.0;
				f0 = clamp(matCol.g, 0.02, 0.90);
				metalTint = vec3(1.0);
				float bByte = floor(matCol.b * 255.0 + 0.5);
				matSss = (bByte > 64.5) ? ((bByte - 65.0) / 190.0) : 0.0;
			}
			else if (gByte < 237.5)
			{
				metallic = 1.0;
				vec3 mF0 = vec3(0.56, 0.57, 0.58);
				if (gByte < 230.5) mF0 = vec3(0.56, 0.57, 0.58);
				else if (gByte < 231.5) mF0 = vec3(1.00, 0.71, 0.29);
				else if (gByte < 232.5) mF0 = vec3(0.91, 0.92, 0.92);
				else if (gByte < 233.5) mF0 = vec3(0.55, 0.56, 0.56);
				else if (gByte < 234.5) mF0 = vec3(0.95, 0.64, 0.54);
				else if (gByte < 235.5) mF0 = vec3(0.63, 0.62, 0.64);
				else if (gByte < 236.5) mF0 = vec3(0.67, 0.64, 0.58);
				else mF0 = vec3(0.95, 0.93, 0.88);
				f0 = dot(mF0, vec3(0.2126, 0.7152, 0.0722));
				metalTint = mF0 / max(f0, 0.001);
			}
			else
			{
				metallic = 1.0;
				f0 = 0.88;
				metalTint = vec3(1.0);
			}
			float aByte = floor(matCol.a * 255.0 + 0.5);
			matEmissive = (aByte < 254.5) ? ((aByte / 254.0) * max(0.0, uDefaultEmissive) * uPbrEmissiveStrength) : 0.0;
			if (nrmCol.a >= 0.01)
				matAo = mix(1.0, clamp(nrmCol.b, 0.0, 1.0), clamp(uPbrAoStrength, 0.0, 1.0));
		}
		else if (uMaterialFormat == 1)
		{
			roughness = clamp(1.0 - matCol.r, 0.02, 1.0);
			metallic = clamp(matCol.g, 0.0, 1.0);
			f0 = mix(0.04, 0.88, metallic);
			metalTint = vec3(1.0);
			matEmissive = matCol.b * max(0.0, uDefaultEmissive) * uPbrEmissiveStrength;
		}
	}
	if (uPbrMatOverride.x >= 0.0)
		roughness = clamp(uPbrMatOverride.x, 0.02, 1.0);
	if (uPbrMatOverride.y >= 0.0)
	{
		metallic = clamp(uPbrMatOverride.y, 0.0, 1.0);
		f0 = mix(0.04, 0.88, metallic);
		metalTint = vec3(1.0);
	}
}

float evalPbrSpecular(vec3 N, vec3 V, vec3 L, float roughness, float metallic, float f0)
{
	float ndotl = max(dot(N, L), 0.0);
	float ndotv = max(dot(N, V), 0.001);
	if (ndotl <= 0.0)
		return 0.0;
	vec3 H = normalize(L + V);
	float ndoth = max(dot(N, H), 0.0);
	float vdoth = max(dot(V, H), 0.0);
	float a = clamp(roughness * roughness, 0.0004, 1.0);
	float a2 = a * a;
	float dDenom = ndoth * ndoth * (a2 - 1.0) + 1.0;
	float D = a2 / max(PI * dDenom * dDenom, 0.0001);
	float k = ((roughness + 1.0) * (roughness + 1.0)) * 0.125;
	float G = (ndotv / (ndotv * (1.0 - k) + k)) * (ndotl / (ndotl * (1.0 - k) + k));
	float fres = f0 + (1.0 - f0) * pow(clamp(1.0 - vdoth, 0.0, 1.0), 5.0);
	float brdf = (D * G * fres) / max(4.0 * ndotl * ndotv, 0.001);
	return clamp(brdf * ndotl, 0.0, 8.0);
}

void main()
{
	if (uIsSky < 1 && dot(uMirrorClipPlane.xyz, uMirrorClipPlane.xyz) > 0.25 && dot(vPosition, uMirrorClipPlane.xyz) + uMirrorClipPlane.w < -0.25)
		discard;
	vec3 V = normalize(uCameraPosition - vPosition);
	vec2 uv = (uIsSky < 1) ? getPomUV(vTexCoord, V, vNormal, vTangent, vHasTangent) : vTexCoord;
	vec4 texCol = texture2D(uTexture, uv);
	vec4 baseColor = vColor * texCol;
	if (texCol.a < 0.05 || baseColor.a < 0.01)
		discard;
	
	vec3 lightResult = vec3(0.0);
	
	if (uIsSky > 0)
		lightResult = vec3(0.0);
	else
	{
		vec3 N = getMappedNormal(uv);
		float roughness, metallic, f0, matEmissive, matSss, matAo;
		vec3 metalTint;
		getPbrMaterial(uv, roughness, metallic, f0, metalTint, matEmissive, matSss, matAo);
		
		float bright = clamp(max(vBrightness, matEmissive), 0.0, 1.0);
		float bleedTotal = clamp((vLightBleed + uBleedLight + matSss) * uLightBleedStrength, 0.0, 1.0);
		float aoFactor = mix(pow(max(matAo, 0.001), 0.5), 1.0, bright);
		float diffuseScale = mix(1.0, 0.28, metallic);
		float effRough = (uUseNormalMap > 0 && uMaterialFormat > 0 || uPbrMatOverride.x >= 0.0) ? roughness : clamp(1.0 - clamp(uSpecularShininess / 64.0, 0.0, 0.92), 0.06, 0.95);
		
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
			
			vec3 light = lightTint * dif * aoFactor * diffuseScale;
			
			if (uSpecularEnable > 0 && ndotl > 0.0 && att > 0.0)
			{
				float specBrdf = evalPbrSpecular(N, V, L, effRough, metallic, f0);
				light += data2.rgb * metalTint * specBrdf * uSpecularStrength * att;
			}
			
			light = mix(light, vec3(0.0), bright);
			lightResult.rgb += light;
		}
	}
	
	gl_FragColor = vec4(lightResult, baseColor.a);
}
