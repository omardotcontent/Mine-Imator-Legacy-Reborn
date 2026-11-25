uniform sampler2D uTexture; // static
uniform sampler2D uTextureMaterial; // static
uniform sampler2D uTextureNormal; // static

uniform vec3 uCameraPosition; // static
uniform int uUseNormalMap; // static
uniform int uMaterialFormat;
uniform float uDefaultEmissive; // static
uniform float uPbrNormalStrength; // static
uniform int uPbrPomEnable; // static
uniform float uPbrPomDepth; // static
uniform int uPbrPomSamples; // static
uniform float uPbrEmissiveStrength; // static
uniform float uPbrAoStrength; // static
uniform vec2 uPbrTileGrid;
uniform vec4 uPbrMatOverride;

uniform int uHemiEnable; // static
uniform float uHemiStrength; // static
uniform vec4 uHemiSkyColor; // static
uniform vec4 uHemiGroundColor; // static

uniform int uRimEnable; // static
uniform float uRimStrength; // static
uniform float uRimPower; // static
uniform vec4 uRimColor; // static
uniform vec4 uMirrorClipPlane; // static

varying vec3 vWorldPos;
varying vec3 vNormal;
varying vec3 vTangent;
varying float vHasTangent;
varying vec2 vTexCoord;
varying vec4 vColor;
varying float vBrightness;

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

void getNightPbr(vec2 uv, out float matEmissive, out float matAo)
{
	matEmissive = 0.0;
	matAo = 1.0;
	if (uUseNormalMap < 1)
		return;
	vec4 matCol = texture2D(uTextureMaterial, uv);
	vec4 nrmCol = texture2D(uTextureNormal, uv);
	if (uMaterialFormat == 2)
	{
		float aByte = floor(matCol.a * 255.0 + 0.5);
		matEmissive = (aByte < 254.5) ? ((aByte / 254.0) * max(0.0, uDefaultEmissive) * uPbrEmissiveStrength) : 0.0;
		if (nrmCol.a >= 0.01)
			matAo = mix(1.0, clamp(nrmCol.b, 0.0, 1.0), clamp(uPbrAoStrength, 0.0, 1.0));
	}
	else if (uMaterialFormat == 1)
		matEmissive = matCol.b * max(0.0, uDefaultEmissive) * uPbrEmissiveStrength;
}

void main()
{
	if (dot(uMirrorClipPlane.xyz, uMirrorClipPlane.xyz) > 0.25 && dot(vWorldPos, uMirrorClipPlane.xyz) + uMirrorClipPlane.w < -0.25)
		discard;
	vec3 V = normalize(uCameraPosition - vWorldPos);
	vec2 uv = getPomUV(vTexCoord, V, vNormal, vTangent, vHasTangent);
	vec4 texCol = texture2D(uTexture, uv);
	vec4 baseColor = vColor * texCol;
	if (texCol.a < 0.05 || baseColor.a < 0.01)
		discard;
	
	vec3 N = getMappedNormal(uv);
	float matEmissive, matAo;
	getNightPbr(uv, matEmissive, matAo);
	float bright = clamp(max(vBrightness, matEmissive), 0.0, 1.0);
	float aoFactor = mix(pow(max(matAo, 0.001), 0.5), 1.0, bright);
	vec3 light = vec3(0.0);
	
	if (uHemiEnable > 0)
	{
		float hemiFactor = clamp(N.z * 0.5 + 0.5, 0.0, 1.0);
		light += mix(uHemiGroundColor.rgb, uHemiSkyColor.rgb, hemiFactor) * uHemiStrength * 0.35 * aoFactor;
	}
	
	if (uRimEnable > 0)
	{
		float rim = pow(1.0 - clamp(dot(N, V), 0.0, 1.0), uRimPower) * uRimStrength * 0.45 * aoFactor;
		light += uRimColor.rgb * rim;
	}
	
	light = mix(light, vec3(1.0), bright);
	gl_FragColor = vec4(light, baseColor.a);
}
