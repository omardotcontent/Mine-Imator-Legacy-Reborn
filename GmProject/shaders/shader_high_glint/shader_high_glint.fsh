uniform sampler2D uTexture; // static
uniform vec2 uTextureSize;

uniform sampler2D uGlintTexture; // static
uniform vec2 uGlintOffset;
uniform vec2 uGlintSize;
uniform int uGlintEnabled;
uniform float uGlintStrength;

varying vec3 vPosition;
varying vec4 vColor;
varying vec2 vTexCoord;

void main()
{
	vec2 tex = vTexCoord;
	vec4 baseColor = vColor * texture2D(uTexture, tex);
	
	if (baseColor.a < 0.0001)
		discard;
	
	if (uGlintEnabled > 0 && baseColor.a > 0.0)
		baseColor.rgb = texture2D(uGlintTexture, (tex * (uTextureSize / uGlintSize)) + uGlintOffset).rgb * baseColor.a * uGlintStrength;
	else
		baseColor.rgb = vec3(0.0);
	
	gl_FragColor = baseColor;
}
