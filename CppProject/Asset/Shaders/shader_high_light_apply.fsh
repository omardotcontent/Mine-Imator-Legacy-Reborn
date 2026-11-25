uniform vec4 uAmbientColor;

varying vec2 vTexCoord;

void main()
{
	vec4 baseColor = texture2D(gm_BaseTexture, vTexCoord);
	vec3 lit = baseColor.rgb + uAmbientColor.rgb * max(vec3(0.0), vec3(1.0) - baseColor.rgb);
	gl_FragColor = vec4(max(lit, vec3(0.0)), clamp(baseColor.a, 0.0, 1.0));
}
