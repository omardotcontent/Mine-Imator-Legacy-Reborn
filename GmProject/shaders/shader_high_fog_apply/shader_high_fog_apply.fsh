uniform sampler2D uFogBuffer;
uniform vec4 uFogColor;
uniform float uFogScatter;
uniform vec4 uFogScatterColor;
uniform int uHeightFogEnable;
uniform vec4 uHeightFogColor;

varying vec2 vTexCoord;

void main()
{
	vec3 fogData = texture2D(uFogBuffer, vTexCoord).rgb;
	float distFog = fogData.r;
	float heightMist = (uHeightFogEnable > 0) ? fogData.g : 0.0;
	float sunScatter = fogData.b;
	
	vec3 distCol = mix(uFogColor.rgb, uFogScatterColor.rgb, clamp(sunScatter * uFogScatter, 0.0, 1.0));
	vec3 mistCol = mix(uHeightFogColor.rgb, uFogScatterColor.rgb, clamp(sunScatter * uFogScatter * 0.65, 0.0, 1.0));
	
	float totalAlpha = clamp(1.0 - (1.0 - distFog) * (1.0 - heightMist), 0.0, 1.0);
	vec3 finalCol = (totalAlpha > 0.0001) ? mix(distCol, mistCol, heightMist / max(0.0001, distFog + heightMist)) : distCol;
	
	gl_FragColor = vec4(finalCol, totalAlpha);
}
