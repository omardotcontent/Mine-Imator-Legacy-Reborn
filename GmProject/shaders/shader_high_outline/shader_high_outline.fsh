varying vec2 vTexCoord;

uniform sampler2D uDepthBuffer;
uniform sampler2D uNormalBuffer;
uniform sampler2D uMaterialBuffer;

uniform vec2 uScreenSize;
uniform float uThickness;
uniform float uDepthSens;
uniform float uNormalSens;
uniform float uOpacity;
uniform int uDistFadeEnable;
uniform float uDistFade;
uniform vec4 uColor;

float unpackDepth(vec4 c)
{
	if (c.a < 0.99)
		return 1.0;
	return c.r + c.g / 255.0 + c.b / (255.0 * 255.0);
}

vec3 unpackNormal(vec4 c)
{
	return normalize(c.rgb * 2.0 - 1.0);
}

void main()
{
	vec4 base = texture2D(gm_BaseTexture, vTexCoord);
	vec2 texel = (uThickness / uScreenSize);
	
	// Per-object outline mask (.a = 1 for outline-enabled objects, 0 for infinite ground / sky / disabled objects)
	float mC = texture2D(uMaterialBuffer, vTexCoord).a;
	float mL = texture2D(uMaterialBuffer, vTexCoord + vec2(-texel.x, 0.0)).a;
	float mR = texture2D(uMaterialBuffer, vTexCoord + vec2( texel.x, 0.0)).a;
	float mU = texture2D(uMaterialBuffer, vTexCoord + vec2(0.0, -texel.y)).a;
	float mD = texture2D(uMaterialBuffer, vTexCoord + vec2(0.0,  texel.y)).a;
	
	float objMask = max(mC, max(max(mL, mR), max(mU, mD)));
	if (objMask < 0.5)
	{
		gl_FragColor = base;
		return;
	}
	
	vec4 dTexC = texture2D(uDepthBuffer, vTexCoord);
	float dC = unpackDepth(dTexC);
	float dL = unpackDepth(texture2D(uDepthBuffer, vTexCoord + vec2(-texel.x, 0.0)));
	float dR = unpackDepth(texture2D(uDepthBuffer, vTexCoord + vec2( texel.x, 0.0)));
	float dU = unpackDepth(texture2D(uDepthBuffer, vTexCoord + vec2(0.0, -texel.y)));
	float dD = unpackDepth(texture2D(uDepthBuffer, vTexCoord + vec2(0.0,  texel.y)));
	
	vec3 nC = unpackNormal(texture2D(uNormalBuffer, vTexCoord));
	vec3 nL = unpackNormal(texture2D(uNormalBuffer, vTexCoord + vec2(-texel.x, 0.0)));
	vec3 nR = unpackNormal(texture2D(uNormalBuffer, vTexCoord + vec2( texel.x, 0.0)));
	vec3 nU = unpackNormal(texture2D(uNormalBuffer, vTexCoord + vec2(0.0, -texel.y)));
	vec3 nD = unpackNormal(texture2D(uNormalBuffer, vTexCoord + vec2(0.0,  texel.y)));
	
	// 2nd-order Laplacian depth discontinuity + grazing-angle compensation (zero false trigger on flat angled planes!)
	float lapDepth = abs(dL + dR - 2.0 * dC) + abs(dU + dD - 2.0 * dC);
	float grazeComp = clamp(abs(nC.z) * 2.2, 0.10, 1.0);
	float depthEdge = smoothstep(0.0020, 0.0110, lapDepth * grazeComp * uDepthSens * (1.0 / max(0.04, dC)));
	
	// Only allow normal crease outlines on pixels belonging to an outline-enabled object
	float normalDiff = (length(nL - nR) + length(nU - nD)) * mC;
	float normalEdge = smoothstep(0.45, 1.15, normalDiff * uNormalSens);
	
	// Optional distance fade (safe smoothstep bounds; disabled = pure crisp outlines at all distances)
	float distFade = 1.0;
	if (uDistFadeEnable > 0 && uDistFade > 0.001)
	{
		float minD = min(dC, min(min(dL, dR), min(dU, dD)));
		float startD = clamp(1.0 - uDistFade, 0.02, 0.97);
		distFade = 1.0 - smoothstep(startD, 0.995, minD);
	}
	
	float edge = clamp(max(depthEdge, normalEdge) * distFade * uOpacity, 0.0, 1.0);
	gl_FragColor = vec4(mix(base.rgb, uColor.rgb, edge), base.a);
}
