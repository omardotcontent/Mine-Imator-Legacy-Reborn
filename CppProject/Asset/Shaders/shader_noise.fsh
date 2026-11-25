varying vec2 vTexCoord;

uniform float uTime;
uniform float uStrength;
uniform float uSaturation;
uniform vec2 uSize;
uniform vec2 uScreenSize;

vec3 hash32Grain(vec2 p, float t)
{
	vec3 q = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973) + vec3(fract(t * 17.31), fract(t * 29.73), fract(t * 43.17)));
	q += dot(q, q.yxz + 33.33);
	return fract((q.xxy + q.yzz) * q.zyx);
}

void main()
{
	vec4 baseColor = texture2D(gm_BaseTexture, vTexCoord);
	vec2 grainSize = max(uSize, vec2(0.5, 0.5));
	vec2 pixelPos = floor((vTexCoord * uScreenSize) / grainSize);
	vec3 grain = hash32Grain(pixelPos, uTime);
	vec3 luma = vec3(dot(grain, vec3(0.2125, 0.7154, 0.0721)));
	grain = mix(luma, grain, uSaturation);
	baseColor.rgb += grain * uStrength;
	gl_FragColor = vec4(baseColor);
}
