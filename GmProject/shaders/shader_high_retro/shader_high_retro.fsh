varying vec2 vTexCoord;

uniform vec2 uScreenSize;
uniform float uTime;
uniform float uPixelate;
uniform int uDither;
uniform float uColors;
uniform float uScanlines;
uniform float uCurvature;
uniform float uVHS;

float bayer4x4(vec2 pos)
{
	int x = int(mod(pos.x, 4.0));
	int y = int(mod(pos.y, 4.0));
	int idx = y * 4 + x;
	if (idx == 0)  return  0.0 / 16.0;
	if (idx == 1)  return  8.0 / 16.0;
	if (idx == 2)  return  2.0 / 16.0;
	if (idx == 3)  return 10.0 / 16.0;
	if (idx == 4)  return 12.0 / 16.0;
	if (idx == 5)  return  4.0 / 16.0;
	if (idx == 6)  return 14.0 / 16.0;
	if (idx == 7)  return  6.0 / 16.0;
	if (idx == 8)  return  3.0 / 16.0;
	if (idx == 9)  return 11.0 / 16.0;
	if (idx == 10) return  1.0 / 16.0;
	if (idx == 11) return  9.0 / 16.0;
	if (idx == 12) return 15.0 / 16.0;
	if (idx == 13) return  7.0 / 16.0;
	if (idx == 14) return 13.0 / 16.0;
	return 5.0 / 16.0;
}

float hash11(float p)
{
	return fract(sin(p * 127.1) * 43758.5453);
}

void main()
{
	vec2 uv = vTexCoord;
	
	// CRT Barrel Curvature
	if (uCurvature > 0.001)
	{
		vec2 cc = uv * 2.0 - 1.0;
		vec2 offset = abs(cc.yx) / max(1.2, 6.0 - uCurvature * 4.2);
		cc = cc + cc * offset * offset;
		uv = cc * 0.5 + 0.5;
		if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0)
		{
			gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
			return;
		}
	}
	
	// VHS horizontal jitter
	if (uVHS > 0.001)
	{
		float lineNoise = (hash11(floor(uv.y * uScreenSize.y * 0.5) + floor(uTime * 12.0)) - 0.5);
		float glitchBand = smoothstep(0.94, 1.0, sin(uv.y * 14.0 + uTime * 0.35));
		uv.x += (lineNoise * 0.0015 + glitchBand * 0.008 * lineNoise) * uVHS;
		uv.x = clamp(uv.x, 0.0, 1.0);
	}
	
	// Pixelation
	vec2 sampleUV = uv;
	if (uPixelate > 1.01)
	{
		vec2 grid = max(vec2(1.0), floor(uScreenSize / uPixelate));
		sampleUV = (floor(uv * grid) + 0.5) / grid;
	}
	
	vec4 base = texture2D(gm_BaseTexture, sampleUV);
	vec3 col = base.rgb;
	
	// VHS chroma bleed
	if (uVHS > 0.001)
	{
		float bleed = 0.0035 * uVHS;
		col.r = mix(col.r, texture2D(gm_BaseTexture, clamp(sampleUV + vec2(bleed, 0.0), vec2(0.0), vec2(1.0))).r, 0.75);
		col.b = mix(col.b, texture2D(gm_BaseTexture, clamp(sampleUV - vec2(bleed, 0.0), vec2(0.0), vec2(1.0))).b, 0.75);
	}
	
	// PS1 Ordered Bayer Dithering & Color Quantization
	if (uDither > 0)
	{
		float levels = max(2.0, uColors);
		vec2 ditherCoord = (uPixelate > 1.01) ? floor((uv * uScreenSize) / uPixelate) : floor(uv * uScreenSize);
		float b = bayer4x4(ditherCoord) - 0.5;
		col = clamp(floor((col + b / levels) * levels + 0.5) / levels, 0.0, 1.0);
	}
	
	// CRT Scanlines
	if (uScanlines > 0.001)
	{
		float scan = 0.5 + 0.5 * sin(uv.y * uScreenSize.y * 3.14159265);
		col *= mix(1.0, 0.55 + 0.45 * scan, clamp(uScanlines, 0.0, 1.0));
	}
	
	gl_FragColor = vec4(col, base.a);
}
