varying vec2 vTexCoord;

uniform sampler2D uDepthBuffer;

uniform float uNear;
uniform float uFar;
uniform mat4 uProjMatrixInv;
uniform mat4 uViewInvMatrix;
uniform mat4 uPrevViewProjMatrix;

uniform float uTime;
uniform float uMotionBlur;
uniform float uRadialBlur;
uniform float uSpeedLines;
uniform float uSpeedLinesRadius;
uniform vec4 uSpeedLinesColor;

float unpackDepth(vec4 c)
{
	if (c.a < 0.99)
		return 1.0;
	return c.r + c.g / 255.0 + c.b / (255.0 * 255.0);
}

float transformDepth(float depth)
{
	return (uFar - (uNear * uFar) / (depth * (uFar - uNear) + uNear)) / (uFar - uNear);
}

vec3 posFromBuffer(vec2 coord, float depth)
{
	vec4 pos = uProjMatrixInv * vec4(coord.x * 2.0 - 1.0, 1.0 - coord.y * 2.0, transformDepth(depth), 1.0);
	return pos.xyz / pos.w;
}

float hash11(float p)
{
	p = fract(p * 0.1031);
	p *= p + 33.33;
	p *= p + p;
	return fract(p);
}

void main()
{
	vec4 base = texture2D(gm_BaseTexture, vTexCoord);
	vec3 col = base.rgb;
	
	vec2 velocity = vec2(0.0);
	
	// 1. Velocity Camera / Scene Motion Blur
	if (uMotionBlur > 0.001)
	{
		float d = unpackDepth(texture2D(uDepthBuffer, vTexCoord));
		vec3 viewPos = posFromBuffer(vTexCoord, d);
		vec4 worldPos = uViewInvMatrix * vec4(viewPos, 1.0);
		vec4 prevClip = uPrevViewProjMatrix * worldPos;
		if (prevClip.w > 0.0001)
		{
			vec2 prevUV = (prevClip.xy / prevClip.w) * 0.5 + 0.5;
			prevUV.y = 1.0 - prevUV.y;
			vec2 v = (vTexCoord - prevUV) * uMotionBlur * 0.5;
			float vLen = length(v);
			if (vLen > 0.04)
				v = (v / vLen) * 0.04;
			velocity += v;
		}
	}
	
	// 2. Radial Action Zoom Blur
	if (uRadialBlur > 0.001)
	{
		vec2 toCenter = vec2(0.5, 0.5) - vTexCoord;
		velocity += toCenter * (uRadialBlur * 0.08);
	}
	
	if (length(velocity) > 0.0002)
	{
		vec3 acc = vec3(0.0);
		for (int i = -4; i <= 4; i++)
		{
			float t = float(i) / 4.0;
			vec2 suv = clamp(vTexCoord + velocity * t, vec2(0.001), vec2(0.999));
			acc += texture2D(gm_BaseTexture, suv).rgb;
		}
		col = acc / 9.0;
	}
	
	// 3. Anime / Manga Action Speed Lines
	if (uSpeedLines > 0.001)
	{
		vec2 p = vTexCoord - vec2(0.5);
		p.x *= 1.5;
		float r = length(p);
		float ang = atan(p.y, p.x);
		
		float tick = floor(uTime * 14.0);
		float sector1 = floor((ang + 3.14159265) * 42.0);
		float sector2 = floor((ang + 3.14159265) * 95.0);
		float rnd1 = hash11(sector1 + tick * 19.7);
		float rnd2 = hash11(sector2 + tick * 37.3);
		
		float innerR = mix(0.15, 0.72, uSpeedLinesRadius) + rnd1 * 0.14;
		float spike1 = smoothstep(0.84, 0.96, rnd1) * smoothstep(innerR, innerR + 0.14, r);
		float spike2 = smoothstep(0.88, 0.98, rnd2) * smoothstep(innerR * 0.9, innerR + 0.08, r);
		float lineMask = clamp((spike1 + spike2) * uSpeedLines, 0.0, 1.0);
		
		col = mix(col, uSpeedLinesColor.rgb, lineMask);
	}
	
	gl_FragColor = vec4(col, base.a);
}
