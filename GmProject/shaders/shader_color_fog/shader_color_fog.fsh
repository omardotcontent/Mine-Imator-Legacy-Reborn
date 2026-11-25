uniform sampler2D uTexture; // static
uniform sampler2D uTextureMaterial; // static
uniform sampler2D uTextureNormal; // static

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

uniform float uSampleIndex;
uniform int uAlphaHash;

uniform int uColorsExt;
uniform vec4 uRGBAdd;
uniform vec4 uRGBSub;
uniform vec4 uHSBAdd;
uniform vec4 uHSBSub;
uniform vec4 uHSBMul;
uniform vec4 uMixColor;

uniform int uFogShow;
uniform vec4 uFogColor; // static
uniform float uFogDistance; // static
uniform float uFogSize; // static
uniform float uFogHeight; // static

uniform vec3 uCameraPosition; // static

// Water ripples & Global Wetness / Rain Puddles
uniform int uIsSky;
uniform int uIsWater;
uniform float uRippleTime; // static
uniform int uWaterRipples; // static
uniform float uWaterRippleStrength; // static
uniform float uWaterRippleSpeed; // static
uniform float uWetness; // static
uniform int uWetnessRipples; // static
uniform vec3 uSunDir; // static
uniform vec4 uSkyColor; // static
uniform vec4 uHorizonColor; // static

uniform int uIsPlanarMirror;
uniform float uMirrorStrength;
uniform vec4 uMirrorVPX; // static
uniform vec4 uMirrorVPY; // static
uniform vec4 uMirrorVPW; // static
uniform sampler2D uMirrorTexture; // static
uniform vec4 uMirrorClipPlane; // static

varying vec3 vPosition;
varying vec3 vWorldNormal;
varying vec3 vWorldTangent;
varying float vHasTangent;
varying float vDepth;
varying vec4 vColor;
varying vec2 vTexCoord;

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
	vec3 N = normalize(vWorldNormal);
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
	vec3 T = normalize(vWorldTangent - dot(vWorldTangent, N) * N);
	vec3 B = cross(T, N);
	return normalize(T * tn.x + B * tn.y + N * tn.z);
}

void getPbrFogInfo(vec2 uv, out float porosity, out float matAo, out float matEmissive)
{
	porosity = 0.5;
	matAo = 1.0;
	matEmissive = 0.0;
	if (uUseNormalMap < 1)
		return;
	vec4 matCol = texture2D(uTextureMaterial, uv);
	vec4 nrmCol = texture2D(uTextureNormal, uv);
	if (uMaterialFormat == 2)
	{
		float gByte = floor(matCol.g * 255.0 + 0.5);
		if (gByte < 229.5)
		{
			float bByte = floor(matCol.b * 255.0 + 0.5);
			porosity = (bByte <= 64.5) ? (bByte / 64.0) : 0.15;
		}
		else
			porosity = 0.0;
		float aByte = floor(matCol.a * 255.0 + 0.5);
		matEmissive = (aByte < 254.5) ? ((aByte / 254.0) * max(0.0, uDefaultEmissive) * uPbrEmissiveStrength) : 0.0;
		if (nrmCol.a >= 0.01)
			matAo = mix(1.0, clamp(nrmCol.b, 0.0, 1.0), clamp(uPbrAoStrength, 0.0, 1.0));
	}
	else if (uMaterialFormat == 1)
	{
		float metallic = clamp(matCol.g, 0.0, 1.0);
		porosity = 0.35 * (1.0 - metallic) * clamp(1.0 - matCol.r, 0.0, 1.0);
		matEmissive = matCol.b * max(0.0, uDefaultEmissive) * uPbrEmissiveStrength;
	}
}

vec4 rgbtohsb(vec4 c)
{
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec4(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x, c.a);
}

vec4 hsbtorgb(vec4 c)
{
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return vec4(c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y), c.a);
}

float getFog()
{
	float fog;
	if (uFogShow > 0)
	{
		float fogDepth = distance(vPosition, uCameraPosition);
		
		fog = clamp(1.0 - (uFogDistance - fogDepth) / uFogSize, 0.0, 1.0);
		fog *= clamp(1.0 - (vPosition.z - uFogHeight) / uFogSize, 0.0, 1.0);
	}
	else
		fog = 0.0;
	
	return fog;
}

float hash(vec2 c)
{
	return fract(10000.0 * sin(17.0 * c.x + 0.1 * c.y) *
	(0.1 + abs(sin(13.0 * c.y + c.x))));
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

float puddleMask(vec2 wp)
{
	float n = valueNoise(wp * 0.022) * 0.65 + valueNoise(wp * 0.058 + vec2(7.3, 19.1)) * 0.35;
	return smoothstep(0.92 - uWetness * 0.80, 0.98 - uWetness * 0.42, n);
}

vec2 getWaterRipple(vec2 wp, float t)
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
	float rnd = hash21(cell);
	float phase = fract(t * 0.85 + rnd);
	float dist = length(local);
	float radius = phase * 0.48;
	float ring = sin((dist - radius) * 38.0) * exp(-abs(dist - radius) * 14.0) * (1.0 - phase) * step(dist, 0.48);
	vec2 dir = (dist > 0.001) ? (local / dist) : vec2(0.0);
	return dir * ring;
}

vec2 getRainRipples(vec2 wp, float t)
{
	return getRainRippleLayer(wp, t, 0.16, 0.0) + getRainRippleLayer(wp, t * 1.13, 0.23, 3.7) * 0.75;
}

void main()
{
	if (uIsSky < 1 && dot(uMirrorClipPlane.xyz, uMirrorClipPlane.xyz) > 0.25)
	{
		if (dot(vPosition, uMirrorClipPlane.xyz) + uMirrorClipPlane.w < -0.25)
			discard;
	}
	vec3 V = normalize(uCameraPosition - vPosition);
	vec2 tex = (uIsSky < 1) ? getPomUV(vTexCoord, V, vWorldNormal, vWorldTangent, vHasTangent) : vTexCoord;
	vec4 baseColor = vColor * texture2D(uTexture, tex); // Get base
	if (uIsPlanarMirror > 0 && baseColor.a > 0.01)
	{
		vec4 wp4 = vec4(vPosition, 1.0);
		float mw = max(0.0001, dot(uMirrorVPW, wp4));
		vec2 muv = vec2(dot(uMirrorVPX, wp4), dot(uMirrorVPY, wp4)) / mw * 0.5 + 0.5;
		muv.y = 1.0 - muv.y;
		muv = clamp(muv, 0.001, 0.999);
		vec4 reflCol = texture2D(uMirrorTexture, muv);
		baseColor.rgb = mix(baseColor.rgb, reflCol.rgb * vColor.rgb, clamp(uMirrorStrength, 0.0, 1.0));
	}
	
	// Water ripples, LabPBR baked AO & porosity wetness / Rain Puddles surface shading
	if (uIsSky < 1 && baseColor.a > 0.01)
	{
		float porosity, matAo, matEmissive;
		getPbrFogInfo(tex, porosity, matAo, matEmissive);
		float aoTerm = mix(pow(max(matAo, 0.001), 0.5), 1.0, clamp(matEmissive, 0.0, 1.0));
		baseColor.rgb *= aoTerm;
		if (uUseNormalMap > 0 && uPbrPomEnable > 0 && uPbrPomDepth > 0.0001)
		{
			float pomH = texture2D(/* lod0 */uTextureNormal, tex).a;
			if (pomH > 0.005)
			{
				float cavity = mix(1.0, 0.68 + 0.32 * pomH, clamp(uPbrPomDepth * 6.0, 0.0, 1.0));
				baseColor.rgb *= mix(cavity, 1.0, clamp(matEmissive, 0.0, 1.0));
			}
		}
		
		vec3 geomN = normalize(vWorldNormal);
		vec3 N = getMappedNormal(tex);
		float distFade = 1.0 - smoothstep(220.0, 900.0, distance(vPosition, uCameraPosition));
		
		if (uIsWater > 0 && uWaterRipples > 0)
		{
			vec2 rip = getWaterRipple(vPosition.xy, uRippleTime * uWaterRippleSpeed) * (0.24 * uWaterRippleStrength * distFade);
			vec3 Nw = normalize(vec3(N.x + rip.x, N.y + rip.y, max(0.2, N.z)));
			vec3 R = reflect(-V, Nw);
			float fres = mix(0.18, 0.85, pow(1.0 - clamp(dot(Nw, V), 0.0, 1.0), 3.0));
			vec3 skyRefl = mix(uHorizonColor.rgb, uSkyColor.rgb, clamp(R.z * 0.7 + 0.3, 0.0, 1.0));
			
			// Wave slope shading + sun sparkle
			float waveShade = clamp(0.88 + (rip.x + rip.y) * 0.45, 0.72, 1.18);
			vec3 H = normalize(normalize(uSunDir) + V);
			float sparkle = pow(max(0.0, dot(Nw, H)), 64.0) * clamp(uSunDir.z * 3.0, 0.0, 1.0) * 1.15;
			
			baseColor.rgb = mix(baseColor.rgb * waveShade, skyRefl, fres * 0.65) + vec3(1.0, 0.97, 0.90) * sparkle;
		}
		else if (uWetness > 0.001)
		{
			float upMask = smoothstep(0.60, 0.88, geomN.z);
			if (upMask > 0.01)
			{
				float pMask = puddleMask(vPosition.xy) * upMask;
				float porousFactor = (uUseNormalMap > 0) ? mix(0.25, 1.35, clamp(porosity, 0.0, 1.0)) : 1.0;
				// Dampen porous surface albedo (wet stone/grass looks darker & richer)
				baseColor.rgb *= mix(1.0, 0.58, clamp(upMask * uWetness * (0.55 + 0.45 * pMask) * porousFactor, 0.0, 1.0));
				
				float wetAmt = pMask * uWetness;
				if (wetAmt > 0.02)
				{
					vec3 Nw = N;
					if (uWetnessRipples > 0 && distFade > 0.01)
					{
						vec2 rrip = getRainRipples(vPosition.xy, uRippleTime) * (0.55 * wetAmt * distFade);
						Nw = normalize(vec3(N.x + rrip.x, N.y + rrip.y, max(0.25, N.z)));
					}
					vec3 R = reflect(-V, Nw);
					float fres = mix(0.22, 0.92, pow(1.0 - clamp(dot(Nw, V), 0.0, 1.0), 3.0));
					vec3 skyRefl = mix(uHorizonColor.rgb, uSkyColor.rgb, clamp(R.z * 0.75 + 0.25, 0.0, 1.0));
					
					// Subtle raindrop ring shimmer + sun glint on puddle surface
					vec3 H = normalize(normalize(uSunDir) + V);
					float glint = pow(max(0.0, dot(Nw, H)), 72.0) * clamp(uSunDir.z * 3.0 + 0.15, 0.0, 1.0) * wetAmt * 1.1;
					float rippleHighlight = clamp((1.0 - Nw.z) * 4.5, 0.0, 0.45) * wetAmt;
					
					baseColor.rgb = mix(baseColor.rgb, skyRefl, clamp(fres * wetAmt * 0.72, 0.0, 0.82)) + skyRefl * rippleHighlight + vec3(1.0, 0.98, 0.94) * glint;
				}
			}
		}
	}
	
	if (uColorsExt > 0)
	{
		gl_FragColor = clamp(baseColor + uRGBAdd - uRGBSub, 0.0, 1.0); // Transform RGB
		gl_FragColor = hsbtorgb(clamp(rgbtohsb(gl_FragColor) + uHSBAdd - uHSBSub, 0.0, 1.0) * uHSBMul); // Transform HSB
		gl_FragColor = mix(gl_FragColor, uMixColor, uMixColor.a); // Mix
		gl_FragColor = mix(gl_FragColor, uFogColor, getFog()); // Mix fog
		gl_FragColor.a = baseColor.a; // Correct alpha
	}
	else 
	{
		gl_FragColor = mix(baseColor, uFogColor, getFog()); // Mix fog
		gl_FragColor.a = baseColor.a; // Correct alpha
	}
	
	if (uAlphaHash > 0)
	{
		if (gl_FragColor.a < hash(vec2(hash(vPosition.xy + (uSampleIndex / 255.0)), vPosition.z + (uSampleIndex / 255.0))))
			discard;
		else
			gl_FragColor.a = 1.0;
	}
	
	if (gl_FragColor.a == 0.0)
		discard;
}
