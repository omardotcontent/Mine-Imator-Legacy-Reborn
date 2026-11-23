uniform sampler2D uTexture; // static

varying vec4 vColor;
varying vec2 vTexCoord;

void main()
{
	vec4 base = vColor * texture2D(uTexture, vTexCoord);
	// Only semi-transparent stained glass / colored translucent pixels filter sunlight
	if (base.a < 0.05 || base.a > 0.96)
		discard;
	
	vec3 filterCol = mix(vec3(1.0), clamp(base.rgb * 1.25, 0.0, 1.0), clamp(base.a * 1.25, 0.0, 1.0));
	gl_FragColor = vec4(filterCol, 1.0);
}
