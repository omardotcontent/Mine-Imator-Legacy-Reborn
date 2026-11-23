varying vec2 vTexCoord;

uniform vec2 uScreenSize;
uniform float uTime;
uniform float uRain;
uniform float uSnow;
uniform float uWind;
uniform float uLensDrops;

float hash21(vec2 p)
{
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

// Multi-layer falling rain streaks
float rainLayer(vec2 uv, float scale, float speed, float t)
{
	vec2 p = uv;
	p.x += p.y * uWind * 0.45;
	p *= vec2(scale * 2.6, scale * 0.22);
	p.y -= t * speed;
	
	vec2 id = floor(p);
	vec2 f = fract(p) - 0.5;
	float rnd = hash21(id);
	if (rnd < 0.72)
		return 0.0;
	
	float xOff = (fract(rnd * 17.3) - 0.5) * 0.55;
	float dx = abs(f.x - xOff);
	float streak = smoothstep(0.09, 0.01, dx) * smoothstep(0.48, 0.0, abs(f.y));
	return streak * (0.4 + 0.6 * fract(rnd * 31.7));
}

// Multi-layer drifting snowflakes
float snowLayer(vec2 uv, float scale, float speed, float t)
{
	vec2 p = uv * scale;
	p.y -= t * speed;
	p.x -= t * uWind * speed * 0.55;
	
	vec2 id = floor(p);
	vec2 f = fract(p) - 0.5;
	float rnd = hash21(id);
	if (rnd < 0.65)
		return 0.0;
	
	vec2 wobble = vec2(sin(t * 2.2 + rnd * 6.28) * 0.22, cos(t * 1.7 + rnd * 6.28) * 0.15);
	float d = length(f - wobble);
	float size = 0.06 + 0.08 * fract(rnd * 13.7);
	return smoothstep(size, size * 0.15, d);
}

// Refractive water droplets on camera lens
vec2 lensDropOffset(vec2 uv, float t)
{
	float aspect = uScreenSize.x / max(1.0, uScreenSize.y);
	vec2 p = vec2(uv.x * aspect, uv.y) * 9.0;
	p.y -= t * 0.22;
	
	vec2 id = floor(p);
	vec2 f = fract(p) - 0.5;
	float rnd = hash21(id);
	if (rnd > uLensDrops * 0.85)
		return vec2(0.0);
	
	float slide = sin(t * 1.4 + rnd * 6.28) * 0.12;
	vec2 dropPos = vec2((fract(rnd * 19.1) - 0.5) * 0.45, slide);
	vec2 delta = f - dropPos;
	delta.y *= 0.82;
	float d = length(delta);
	float rad = 0.14 + 0.08 * fract(rnd * 7.3);
	float mask = smoothstep(rad, rad * 0.2, d);
	return delta * mask * 0.085;
}

void main()
{
	vec2 uv = vTexCoord;
	float dropHighlight = 0.0;
	
	if (uLensDrops > 0.001)
	{
		vec2 off1 = lensDropOffset(uv, uTime);
		vec2 off2 = lensDropOffset(uv * 1.55 + vec2(3.7, 1.9), uTime * 1.25) * 0.7;
		vec2 totOff = (off1 + off2) * uLensDrops;
		uv = clamp(uv + totOff, vec2(0.001), vec2(0.999));
		dropHighlight = clamp(length(totOff) * 9.0, 0.0, 0.35);
	}
	
	vec4 base = texture2D(gm_BaseTexture, uv);
	vec3 col = base.rgb + vec3(0.85, 0.92, 1.0) * dropHighlight;
	
	float aspect = uScreenSize.x / max(1.0, uScreenSize.y);
	vec2 wuv = vec2(vTexCoord.x * aspect, vTexCoord.y);
	
	if (uRain > 0.001)
	{
		float r = 0.0;
		r += rainLayer(wuv, 24.0, 3.8, uTime) * 0.55;
		r += rainLayer(wuv + vec2(1.7, 0.4), 42.0, 3.1, uTime) * 0.35;
		r += rainLayer(wuv + vec2(4.3, 2.1), 68.0, 2.4, uTime) * 0.22;
		col = mix(col, vec3(0.82, 0.88, 0.96), clamp(r * uRain, 0.0, 0.75));
	}
	
	if (uSnow > 0.001)
	{
		float s = 0.0;
		s += snowLayer(wuv, 14.0, 0.55, uTime) * 0.65;
		s += snowLayer(wuv + vec2(2.3, 1.1), 26.0, 0.40, uTime) * 0.45;
		s += snowLayer(wuv + vec2(5.7, 3.4), 44.0, 0.28, uTime) * 0.30;
		col = mix(col, vec3(0.96, 0.98, 1.0), clamp(s * uSnow, 0.0, 0.88));
	}
	
	gl_FragColor = vec4(col, base.a);
}
