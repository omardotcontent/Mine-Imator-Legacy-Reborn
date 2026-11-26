varying vec2 vTexCoord;

uniform sampler2D uDepthBuffer; // static
uniform mat4 uProjMatrixInv; // static
uniform mat4 uViewMatrixInv; // static
uniform vec2 uDepthRange; // static
uniform vec2 uScreenSize; // static
uniform vec4 uCloudColor; // static
uniform vec3 uCloudSunDir; // static
uniform vec4 uCloudSunColor; // static
uniform int uCloudFog; // static
uniform vec2 uCloudFogRange; // static
uniform vec4 uCloudFogColor; // static
uniform int uCloudSteps; // static
uniform int uCloudLightSteps; // static

#include "sky_cloud_medium.glsl"

void main()
{
	vec2 ndc = vec2(vTexCoord.x * 2.0 - 1.0, 1.0 - vTexCoord.y * 2.0);
	vec4 viewPoint = uProjMatrixInv * vec4(ndc, 0.5, 1.0);
	vec3 viewDir = normalize(viewPoint.xyz / viewPoint.w);
	vec3 origin = (uViewMatrixInv * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 direction = normalize((uViewMatrixInv * vec4(viewDir, 0.0)).xyz);

	vec4 depth = texture2D(/* lod0 */uDepthBuffer, vTexCoord);
	float viewZ = uDepthRange.y;
	if (depth.a > 0.99)
	{
		float encodedDepth = dot(depth.rgb, vec3(1.0, 1.0 / 255.0, 1.0 / 65025.0));
		float clipZ = mix(uDepthRange.x, uDepthRange.y, encodedDepth);
		viewZ = uDepthRange.x + clipZ * (1.0 - uDepthRange.x / uDepthRange.y);
	}
	float limit = min(uDepthRange.y, viewZ / max(viewDir.z, 0.0001));
	if (uCloudFog > 0)
		limit = min(limit, uCloudFogRange.y);
	float start, end;
	if (!skyCloudRayInterval(origin, direction, limit, start, end))
		discard;

	float stepLength = (end - start) / float(uCloudSteps);
	float transmission = 1.0;
	vec3 scattered = vec3(0.0);
	float daylight = smoothstep(0.05, 0.22, uCloudSunDir.z);
	float silverLining = pow(max(0.0, dot(direction, uCloudSunDir)), 6.0);
	vec2 pixel = floor(vTexCoord * uScreenSize);
	float jitter = fract(52.9829189 * fract(dot(pixel, vec2(0.06711056, 0.00583715))));
	jitter = mix(0.5, jitter, smoothstep(3.0, 18.0, stepLength));
	for (int i = 0; i < 48; ++i)
	{
		if (i >= uCloudSteps || transmission < 0.015)
			break;
		float distance = start + (float(i) + jitter) * stepLength;
		vec3 position = origin + direction * distance;
		vec4 cloudTexel = skyCloudTexel(position.xy);
		float density = skyCloudDensity(position, cloudTexel.a);
		if (density <= 0.0)
			continue;

		float localAlpha = 1.0 - exp(-density * stepLength);
		float sunlight = 0.0;
		if (daylight > 0.0)
			sunlight = daylight * skyCloudSunTransmission(position, uCloudSunDir, uCloudLightSteps, 0.0);
		float height = clamp((position.z - uCloudHeight) / uCloudThickness, 0.0, 1.0);
		float localDetail = clamp(density * uCloudThickness / (4.2 * max(0.01, cloudTexel.a)), 0.0, 1.0);
		vec3 cloudColor = uCloudColor.rgb * cloudTexel.rgb;
		vec3 light = cloudColor * (0.54 + 0.24 * height + 0.16 * localDetail);
		light += cloudColor * uCloudSunColor.rgb * sunlight * (0.43 + 0.22 * silverLining);
		if (uCloudFog > 0)
		{
			float fog = smoothstep(uCloudFogRange.x, uCloudFogRange.y, distance);
			light = mix(light, uCloudFogColor.rgb, fog);
			localAlpha *= 1.0 - fog;
		}
		scattered += light * transmission * localAlpha;
		transmission *= 1.0 - localAlpha;
	}
	gl_FragColor = vec4(scattered, 1.0 - transmission);
}
