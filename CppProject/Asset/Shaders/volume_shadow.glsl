uniform int uVolumeShadowCount; // static
uniform vec4 uVolumeShadowData[80]; // static
uniform vec4 uVolumeWind; // static

float volumeShadowOpacity(vec3 worldPos, vec3 lightDir, float lightDistance)
{
	float opticalDepth = 0.0;
	for (int i = 0; i < uVolumeShadowCount; ++i)
	{
		int offset = i * 5;
		vec4 rowX = uVolumeShadowData[offset];
		vec4 rowY = uVolumeShadowData[offset + 1];
		vec4 rowZ = uVolumeShadowData[offset + 2];
		vec4 worldPoint = vec4(worldPos, 1.0);
		vec3 localOrigin = vec3(dot(rowX, worldPoint), dot(rowY, worldPoint), dot(rowZ, worldPoint));
		vec3 localDir = vec3(dot(rowX.xyz, lightDir), dot(rowY.xyz, lightDir), dot(rowZ.xyz, lightDir));
		vec2 bounds = volumeRayBounds(localOrigin, localDir);
		float start = max(0.0, bounds.x);
		float end = min(lightDistance, bounds.y);
		if (end <= start)
			continue;

		vec4 shape = uVolumeShadowData[offset + 3];
		vec4 medium = uVolumeShadowData[offset + 4];
		float edgeSoft = clamp(shape.y, 0.0, 1.0);
		float noiseSoft = clamp(shape.z, 0.0, 1.0);
		float noiseScale = max(0.1, medium.y) * 0.035;
		vec3 wind = uVolumeWind.xyz * medium.z;
		const int shadowSteps = 8;
		float stepLength = (end - start) / float(shadowSteps);
		for (int stepIndex = 0; stepIndex < shadowSteps; ++stepIndex)
		{
			float t = start + stepLength * (float(stepIndex) + 0.5);
			vec3 localP = localOrigin + localDir * t;
			vec3 noiseP = (worldPos + lightDir * t) * noiseScale + wind;
			opticalDepth += volumeMediumDensity(localP, noiseP, shape.x, medium.x, edgeSoft, noiseSoft) * shape.w * stepLength;
		}
		if (opticalDepth >= 5.0)
			break;
	}
	return 1.0 - exp(-opticalDepth);
}
