uniform float uThreshold;

varying vec2 vTexCoord;

void main()
{
	vec4 baseColor = texture2D(gm_BaseTexture, vTexCoord);
	vec3 col = clamp(baseColor.rgb, vec3(0.0), vec3(64.0));
	float lum = max(col.r, max(col.g, col.b));
	float knee = max(uThreshold * 0.5, 0.05);
	float soft = lum - uThreshold + knee;
	soft = clamp(soft, 0.0, 2.0 * knee);
	soft = (soft * soft) / max(4.0 * knee, 0.0001);
	float contrib = max(soft, lum - uThreshold) / max(lum, 0.0001);
	contrib = max(contrib, 0.0);
	gl_FragColor = vec4(col * contrib, 1.0);
}
