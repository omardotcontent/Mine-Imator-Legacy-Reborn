varying vec2 vTexCoord;

uniform sampler2D uOcclusionMask;
uniform vec2 uSunScreenPos;
uniform vec2 uScreenSize;
uniform vec4 uColor;
uniform float uIntensity;
uniform float uGhosts;
uniform float uHalo;
uniform float uStarburst;
uniform float uVisibility;

float hexDist(vec2 p)
{
	p = abs(p);
	return max(dot(p, normalize(vec2(1.0, 1.73205))), p.x);
}

float ghostHex(vec2 uv, vec2 pos, float radius, float aspect)
{
	vec2 d = uv - pos;
	d.x *= aspect;
	float h = hexDist(d);
	return smoothstep(radius, radius * 0.55, h);
}

void main()
{
	vec4 base = texture2D(gm_BaseTexture, vTexCoord);
	if (uVisibility <= 0.001 || uIntensity <= 0.001)
	{
		gl_FragColor = base;
		return;
	}
	
	// Sample occlusion around the sun disc (5-tap soft visibility check so flare fades smoothly behind objects)
	vec2 off = vec2(0.012, 0.012);
	float occ = 0.0;
	occ += 1.0 - texture2D(uOcclusionMask, clamp(uSunScreenPos, vec2(0.0), vec2(1.0))).r;
	occ += 1.0 - texture2D(uOcclusionMask, clamp(uSunScreenPos + vec2(off.x, 0.0), vec2(0.0), vec2(1.0))).r;
	occ += 1.0 - texture2D(uOcclusionMask, clamp(uSunScreenPos - vec2(off.x, 0.0), vec2(0.0), vec2(1.0))).r;
	occ += 1.0 - texture2D(uOcclusionMask, clamp(uSunScreenPos + vec2(0.0, off.y), vec2(0.0), vec2(1.0))).r;
	occ += 1.0 - texture2D(uOcclusionMask, clamp(uSunScreenPos - vec2(0.0, off.y), vec2(0.0), vec2(1.0))).r;
	float sunOpen = (occ / 5.0) * uVisibility;
	
	if (sunOpen <= 0.001)
	{
		gl_FragColor = base;
		return;
	}
	
	float aspect = uScreenSize.x / max(1.0, uScreenSize.y);
	vec2 toSun = vTexCoord - uSunScreenPos;
	vec2 toSunAsp = vec2(toSun.x * aspect, toSun.y);
	float dSun = length(toSunAsp);
	
	vec3 flare = vec3(0.0);
	
	// 1. Soft sun corona + 6-point starburst + subtle horizontal anamorphic streak
	if (uStarburst > 0.001)
	{
		float angle = atan(toSunAsp.y, toSunAsp.x);
		float rays = pow(abs(cos(angle * 3.0)), 14.0) * 0.65 + pow(abs(cos(angle * 6.0 + 0.5)), 24.0) * 0.35;
		float starburst = rays * exp(-dSun * 4.5);
		float streak = exp(-abs(toSunAsp.y) * 42.0) * exp(-abs(toSunAsp.x) * 2.2) * 0.55;
		float core = exp(-dSun * 10.0) * 0.45;
		flare += uColor.rgb * (starburst + streak + core) * uStarburst;
	}
	
	// 2. Chromatic halo ring centered opposite/around axis
	if (uHalo > 0.001)
	{
		vec2 axis = vec2(0.5, 0.5) - uSunScreenPos;
		vec2 haloCenter = vec2(0.5, 0.5) + axis * 0.35;
		vec2 hd = vTexCoord - haloCenter;
		hd.x *= aspect;
		float hr = length(hd);
		float ringR = smoothstep(0.07, 0.0, abs(hr - 0.36));
		float ringG = smoothstep(0.07, 0.0, abs(hr - 0.38));
		float ringB = smoothstep(0.07, 0.0, abs(hr - 0.40));
		flare += vec3(ringR, ringG, ringB) * uColor.rgb * 0.22 * uHalo;
	}
	
	// 3. Hexagonal cinema ghosts along sun-to-center axis
	if (uGhosts > 0.001)
	{
		vec2 axis = vec2(0.5, 0.5) - uSunScreenPos;
		vec3 g = vec3(0.0);
		g += vec3(1.0, 0.65, 0.35) * ghostHex(vTexCoord, uSunScreenPos + axis * 0.55, 0.055, aspect) * 0.25;
		g += vec3(0.55, 0.85, 1.0) * ghostHex(vTexCoord, uSunScreenPos + axis * 0.90, 0.032, aspect) * 0.30;
		g += vec3(0.95, 0.55, 0.85) * ghostHex(vTexCoord, uSunScreenPos + axis * 1.35, 0.075, aspect) * 0.22;
		g += vec3(0.65, 1.0, 0.70) * ghostHex(vTexCoord, uSunScreenPos + axis * 1.75, 0.042, aspect) * 0.28;
		g += vec3(1.0, 0.80, 0.45) * ghostHex(vTexCoord, uSunScreenPos + axis * 2.15, 0.110, aspect) * 0.18;
		flare += g * uColor.rgb * uGhosts;
	}
	
	gl_FragColor = vec4(base.rgb + flare * uIntensity * sunOpen, base.a);
}
