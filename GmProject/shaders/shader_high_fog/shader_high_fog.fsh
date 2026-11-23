uniform sampler2D uTexture; // static

uniform float uSampleIndex;
uniform int uAlphaHash;

uniform int uFogShow;
uniform vec4 uFogColor; // static
uniform float uFogDistance; // static
uniform float uFogSize; // static
uniform float uFogHeight; // static

// Atmospheric Mie scatter & Height Mist
uniform vec3 uSunDir; // static
uniform int uHeightFogEnable; // static
uniform float uHeightFogHeight; // static
uniform float uHeightFogDensity; // static

uniform vec3 uCameraPosition; // static

varying vec3 vPosition;
uniform vec4 uMirrorClipPlane; // static
varying vec4 vColor;
varying vec2 vTexCoord;
varying float vDepth;

float getFog()
{
	float fog;
	if (uFogShow > 0)
	{
		float fogDepth = distance(vPosition, uCameraPosition);
		
		fog = clamp(1.0 - (uFogDistance - fogDepth) / max(1.0, uFogSize), 0.0, 1.0);
		fog *= clamp(1.0 - (vPosition.z - uFogHeight) / max(1.0, uFogSize), 0.0, 1.0);
	}
	else
		fog = 0.0;
	
	return fog;
}

float getHeightMist()
{
	if (uHeightFogEnable < 1)
		return 0.0;
	float dist = distance(vPosition, uCameraPosition);
	float hFactor = exp(-max(0.0, vPosition.z - uHeightFogHeight) / 140.0);
	float dFactor = 1.0 - exp(-dist * (uHeightFogDensity * 0.0018));
	return clamp(hFactor * dFactor, 0.0, 1.0);
}

float hash(vec2 c)
{
	return fract(10000.0 * sin(17.0 * c.x + 0.1 * c.y) *
	(0.1 + abs(sin(13.0 * c.y + c.x))));
}

void main()
{
	if (dot(uMirrorClipPlane.xyz, uMirrorClipPlane.xyz) > 0.25 && dot(vPosition, uMirrorClipPlane.xyz) + uMirrorClipPlane.w < -0.25)
		discard;
	vec2 tex = vTexCoord;
	vec4 baseColor = vColor * texture2D(uTexture, tex);
	
	if (baseColor.a > 0.0)
	{
		float distFog = getFog();
		float heightMist = getHeightMist();
		vec3 viewDir = normalize(vPosition - uCameraPosition);
		float sunScatter = pow(max(0.0, dot(viewDir, normalize(uSunDir))), 6.0);
		gl_FragColor = vec4(distFog, heightMist, sunScatter, 1.0);
	}
	else
		discard;
	
	if (uAlphaHash > 0 && (baseColor.a < hash(vec2(hash(vPosition.xy + (uSampleIndex / 255.0)), vPosition.z + (uSampleIndex / 255.0)))))
		discard;
}
