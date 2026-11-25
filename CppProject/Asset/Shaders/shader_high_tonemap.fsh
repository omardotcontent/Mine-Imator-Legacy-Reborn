varying vec2 vTexCoord;

uniform vec2 uScreenSize;
uniform int uTonemapper;
uniform float uExposure;
uniform float uGamma;
uniform float uContrast;
uniform float uSaturation;
uniform float uVibrance;
uniform float uSharpen;

// Cinema Color Grading Suite
uniform float uTemperature;
uniform float uTint;
uniform float uLiftShadows;
uniform float uLiftMidtones;
uniform float uLiftHighlights;
uniform float uGlobalCA;
uniform float uGlobalGrain;
uniform float uTime;
uniform float uGlobalVignette;
uniform float uGlobalVignetteRadius;
uniform vec4 uGlobalVignetteColor;

vec3 tonemapACES(vec3 x)
{
	float a = 2.51;
	float b = 0.03;
	float c = 2.43;
	float d = 0.59;
	float e = 0.14;
	return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

vec3 tonemapReinhard(vec3 x)
{
	return x / (vec3(1.0) + x);
}

vec3 tonemapAgX(vec3 col)
{
	vec3 m = vec3(
		0.84247906 * col.r + 0.07843360 * col.g + 0.07922375 * col.b,
		0.04232824 * col.r + 0.87846864 * col.g + 0.07916613 * col.b,
		0.04237565 * col.r + 0.07843360 * col.g + 0.87914297 * col.b
	);
	m = max(m, vec3(0.00001));
	vec3 logVal = clamp((log2(m) + 12.47393) / 16.5, 0.0, 1.0);
	vec3 x2 = logVal * logVal;
	vec3 x4 = x2 * x2;
	vec3 curved = 15.5 * x4 * x2 - 40.14 * x4 * logVal + 31.96 * x4 - 6.868 * x2 * logVal + 0.4298 * x2 + 0.1191 * logVal - 0.00232;
	vec3 outCol = vec3(
		 1.19687900 * curved.r - 0.09802088 * curved.g - 0.09902975 * curved.b,
		-0.05289685 * curved.r + 1.15190313 * curved.g - 0.09896118 * curved.b,
		-0.05297163 * curved.r - 0.09804345 * curved.g + 1.15107367 * curved.b
	);
	return clamp(outCol, 0.0, 1.0);
}

vec3 sampleBase(vec2 uv)
{
	if (uGlobalCA <= 0.001)
		return texture2D(/* lod0 */gm_BaseTexture, uv).rgb;
	vec2 dir = uv - vec2(0.5, 0.5);
	float dist = length(dir);
	vec2 off = dir * (dist * uGlobalCA * 0.015);
	float r = texture2D(/* lod0 */gm_BaseTexture, clamp(uv + off, vec2(0.0), vec2(1.0))).r;
	float g = texture2D(/* lod0 */gm_BaseTexture, uv).g;
	float b = texture2D(/* lod0 */gm_BaseTexture, clamp(uv - off, vec2(0.0), vec2(1.0))).b;
	return vec3(r, g, b);
}

vec3 applyCAS(vec2 uv, vec3 center)
{
	if (uSharpen <= 0.001)
		return center;
	
	vec2 texel = 1.0 / uScreenSize;
	vec3 n = max(texture2D(/* lod0 */gm_BaseTexture, uv + vec2(0.0, -texel.y)).rgb, vec3(0.0));
	vec3 s = max(texture2D(/* lod0 */gm_BaseTexture, uv + vec2(0.0,  texel.y)).rgb, vec3(0.0));
	vec3 w = max(texture2D(/* lod0 */gm_BaseTexture, uv + vec2(-texel.x, 0.0)).rgb, vec3(0.0));
	vec3 e = max(texture2D(/* lod0 */gm_BaseTexture, uv + vec2( texel.x, 0.0)).rgb, vec3(0.0));
	
	// Compress into [0, 1) for HDR-safe local contrast weight estimation without clipping >1.0 peaks
	vec3 cC = center / (vec3(1.0) + max(center, vec3(0.0)));
	vec3 nC = n / (vec3(1.0) + n);
	vec3 sC = s / (vec3(1.0) + s);
	vec3 wC = w / (vec3(1.0) + w);
	vec3 eC = e / (vec3(1.0) + e);
	
	vec3 mn = min(cC, min(min(nC, sC), min(wC, eC)));
	vec3 mx = max(cC, max(max(nC, sC), max(wC, eC)));
	
	vec3 amp = clamp(min(mn, vec3(1.0) - mx) / max(mx, vec3(0.0001)), 0.0, 1.0);
	amp = sqrt(amp);
	
	float peak = -1.0 / mix(8.0, 5.0, clamp(uSharpen, 0.0, 1.0));
	vec3 weight = amp * peak * min(uSharpen, 2.0);
	vec3 sharpened = (center + (n + s + w + e) * weight) / max(vec3(1.0) + 4.0 * weight, vec3(0.0001));
	return max(sharpened, vec3(0.0));
}

float grainHash(vec2 p)
{
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main()
{
	vec4 base = texture2D(gm_BaseTexture, vTexCoord);
	vec3 col = sampleBase(vTexCoord);
	col = applyCAS(vTexCoord, col);
	
	// White balance (Temperature warm/cool + Tint green/magenta)
	if (abs(uTemperature) > 0.001 || abs(uTint) > 0.001)
	{
		col.r *= (1.0 + uTemperature * 0.22 + uTint * 0.10);
		col.g *= (1.0 - uTint * 0.14);
		col.b *= (1.0 - uTemperature * 0.22 + uTint * 0.10);
		col = max(col, vec3(0.0));
	}
	
	// Exposure
	col *= uExposure;
	
	// Tone mapping
	if (uTonemapper == 1) // Reinhard
	{
		vec3 lin = pow(max(col, vec3(0.0)), vec3(2.2));
		lin = tonemapReinhard(lin);
		col = pow(max(lin, vec3(0.0)), vec3(1.0 / 2.2));
	}
	else if (uTonemapper == 2) // ACES Filmic
	{
		vec3 lin = pow(max(col, vec3(0.0)), vec3(2.2));
		lin = tonemapACES(lin);
		col = pow(max(lin, vec3(0.0)), vec3(1.0 / 2.2));
	}
	else if (uTonemapper == 3) // AgX
	{
		vec3 lin = pow(max(col, vec3(0.0)), vec3(2.2));
		col = tonemapAgX(lin);
	}
	else
		col = clamp(col, 0.0, 1.0);
	
	// Shadows / Midtones / Highlights adjustments
	if (abs(uLiftShadows) > 0.001 || abs(uLiftMidtones) > 0.001 || abs(uLiftHighlights) > 0.001)
	{
		float lum = dot(col, vec3(0.2126, 0.7152, 0.0722));
		float shW = pow(1.0 - clamp(lum, 0.0, 1.0), 2.0);
		float hiW = pow(clamp(lum, 0.0, 1.0), 2.0);
		float midW = clamp(1.0 - shW - hiW, 0.0, 1.0);
		col += vec3(uLiftShadows * 0.25 * shW + uLiftMidtones * 0.20 * midW + uLiftHighlights * 0.25 * hiW);
		col = clamp(col, 0.0, 1.0);
	}
	
	// Gamma
	if (abs(uGamma - 1.0) > 0.001)
		col = pow(max(col, vec3(0.0)), vec3(1.0 / max(0.05, uGamma)));
	
	// Contrast
	if (abs(uContrast - 1.0) > 0.001)
		col = clamp((col - 0.5) * uContrast + 0.5, 0.0, 1.0);
	
	// Saturation
	float luma = dot(col, vec3(0.2126, 0.7152, 0.0722));
	if (abs(uSaturation - 1.0) > 0.001)
		col = clamp(mix(vec3(luma), col, uSaturation), 0.0, 1.0);
	
	// Vibrance
	if (abs(uVibrance) > 0.001)
	{
		float maxC = max(col.r, max(col.g, col.b));
		float minC = min(col.r, min(col.g, col.b));
		float sat = maxC - minC;
		float vibAmt = uVibrance * (1.0 - sat);
		col = clamp(mix(vec3(luma), col, 1.0 + vibAmt), 0.0, 1.0);
	}
	
	// Global Film Grain
	if (uGlobalGrain > 0.001)
	{
		float n = grainHash(vTexCoord * uScreenSize + vec2(fract(uTime * 0.13) * 100.0, fract(uTime * 0.27) * 100.0)) - 0.5;
		col = clamp(col + vec3(n * uGlobalGrain * 0.16), 0.0, 1.0);
	}
	
	// Global Vignette
	if (uGlobalVignette > 0.001)
	{
		float d = distance(vTexCoord, vec2(0.5, 0.5)) * 1.4142;
		float vig = smoothstep(uGlobalVignetteRadius * 0.5, max(uGlobalVignetteRadius, 0.05) + 0.55, d);
		col = mix(col, uGlobalVignetteColor.rgb, clamp(vig * uGlobalVignette, 0.0, 1.0));
	}
	
	gl_FragColor = vec4(col, clamp(base.a, 0.0, 1.0));
}
