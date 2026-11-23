uniform sampler2D uTexture; // static

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
varying float vDepth;
varying vec4 vColor;
varying vec2 vTexCoord;

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
	vec2 tex = vTexCoord;
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
	
	// Water ripples & Global Wetness / Rain Puddles surface shading
	if (uIsSky < 1 && baseColor.a > 0.01)
	{
		vec3 N = normalize(vWorldNormal);
		vec3 V = normalize(uCameraPosition - vPosition);
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
			float upMask = smoothstep(0.60, 0.88, N.z);
			if (upMask > 0.01)
			{
				float pMask = puddleMask(vPosition.xy) * upMask;
				// Dampen porous surface albedo (wet stone/grass looks darker & richer)
				baseColor.rgb *= mix(1.0, 0.64, upMask * uWetness * (0.55 + 0.45 * pMask));
				
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
