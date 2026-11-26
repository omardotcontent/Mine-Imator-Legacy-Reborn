uniform sampler2D uCloudTexture; // static
uniform float uCloudTileSize; // static
uniform float uCloudOffset; // static
uniform float uCloudHeight; // static
uniform float uCloudThickness; // static

vec4 skyCloudTexel(vec2 worldXY)
{
	vec2 uv = (worldXY + vec2(0.0, uCloudOffset)) / uCloudTileSize;
	return texture2D(/* lod0 */uCloudTexture, fract(uv));
}

float skyCloudDensity(vec3 worldPos, float coverage)
{
	if (coverage <= 0.0)
		return 0.0;

	float height = (worldPos.z - uCloudHeight) / uCloudThickness;
	float profile = smoothstep(0.0, 0.20, height) * (1.0 - smoothstep(0.72, 1.0, height));
	// Keep the texture's horizontal silhouette intact and vary density within the layer.
	vec2 drifted = worldPos.xy + vec2(0.0, uCloudOffset);
	vec3 detail = vec3(drifted / max(24.0, uCloudTileSize / 512.0), height * 7.0);
	float billows = sin(detail.x * 0.63 + sin(detail.y * 0.41))
	              * sin(detail.y * 0.47 + detail.z * 0.8);
	float wisps = sin(detail.x * 1.19 - detail.y * 1.47 + detail.z);
	float density = (0.80 + 0.16 * billows + 0.04 * wisps) * profile;
	return coverage * density * (4.2 / uCloudThickness);
}

bool skyCloudRayInterval(vec3 origin, vec3 direction, float limit, out float start, out float end)
{
	float top = uCloudHeight + uCloudThickness;
	if (abs(direction.z) < 0.00001)
	{
		start = 0.0;
		end = limit;
		return limit > 0.0 && origin.z >= uCloudHeight && origin.z < top;
	}

	float a = (uCloudHeight - origin.z) / direction.z;
	float b = (top - origin.z) / direction.z;
	start = max(0.0, min(a, b));
	end = min(limit, max(a, b));
	return end > start;
}

float skyCloudSunTransmission(vec3 position, vec3 sunDirection, int steps, float softness)
{
	float start, end;
	if (sunDirection.z <= 0.05 || !skyCloudRayInterval(position, sunDirection, 1.0e8, start, end))
		return 1.0;

	float stepLength = (end - start) / float(steps);
	float opticalDepth = 0.0;
	for (int i = 0; i < 6; ++i)
	{
		if (i >= steps)
			break;
		float distance = start + (float(i) + 0.5) * stepLength;
		vec3 samplePos = position + sunDirection * distance;
		// Vary the offsets across the layer to soften projected shadows at the edges.
		if (softness > 0.0)
		{
			float angle = float(i) * 2.399963;
			samplePos.xy += vec2(cos(angle), sin(angle)) * softness * sqrt((float(i) + 0.5) / float(steps));
		}
		opticalDepth += skyCloudDensity(samplePos, skyCloudTexel(samplePos.xy).a) * stepLength;
	}
	return exp(-opticalDepth);
}
