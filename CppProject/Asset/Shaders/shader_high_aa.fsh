uniform vec2 uScreenSize;
uniform float uPower;
uniform float uThreshold;

varying vec2 vTexCoord;

float rgbLuma(vec3 c)
{
	vec3 t = max(c, vec3(0.0, 0.0, 0.0));
	t = t / (vec3(1.0, 1.0, 1.0) + t);
	return dot(t, vec3(0.299, 0.587, 0.114));
}

void main()
{
	vec2 texel = 1.0 / max(uScreenSize, vec2(1.0, 1.0));
	vec4 centerCol = texture2D(gm_BaseTexture, vTexCoord);
	float lumaM = rgbLuma(centerCol.rgb);
	
	float lumaN = rgbLuma(texture2D(gm_BaseTexture, vTexCoord + vec2(0.0, -texel.y)).rgb);
	float lumaS = rgbLuma(texture2D(gm_BaseTexture, vTexCoord + vec2(0.0,  texel.y)).rgb);
	float lumaW = rgbLuma(texture2D(gm_BaseTexture, vTexCoord + vec2(-texel.x, 0.0)).rgb);
	float lumaE = rgbLuma(texture2D(gm_BaseTexture, vTexCoord + vec2( texel.x, 0.0)).rgb);
	
	float rangeMin = min(lumaM, min(min(lumaN, lumaS), min(lumaW, lumaE)));
	float rangeMax = max(lumaM, max(max(lumaN, lumaS), max(lumaW, lumaE)));
	float range = rangeMax - rangeMin;
	
	float edgeThresh = max(0.0312, uThreshold * 0.25);
	if (range < max(edgeThresh, rangeMax * 0.125) || uPower <= 0.001)
	{
		gl_FragColor = vec4(centerCol.rgb, clamp(centerCol.a, 0.0, 1.0));
		return;
	}
	
	float lumaNW = rgbLuma(texture2D(/* lod0 */gm_BaseTexture, vTexCoord + vec2(-texel.x, -texel.y)).rgb);
	float lumaNE = rgbLuma(texture2D(/* lod0 */gm_BaseTexture, vTexCoord + vec2( texel.x, -texel.y)).rgb);
	float lumaSW = rgbLuma(texture2D(/* lod0 */gm_BaseTexture, vTexCoord + vec2(-texel.x,  texel.y)).rgb);
	float lumaSE = rgbLuma(texture2D(/* lod0 */gm_BaseTexture, vTexCoord + vec2( texel.x,  texel.y)).rgb);
	
	float lumaL = (lumaN + lumaS + lumaW + lumaE) * 0.25;
	float rangeL = abs(lumaL - lumaM);
	float blendL = clamp(rangeL / max(range, 0.0001), 0.0, 1.0);
	float subpix = smoothstep(0.0, 1.0, blendL);
	subpix = subpix * subpix * clamp(uPower * 0.60, 0.0, 0.85);
	
	float edgeHorz = abs(-2.0 * lumaW + lumaNW + lumaSW) + 2.0 * abs(-2.0 * lumaM + lumaN + lumaS) + abs(-2.0 * lumaE + lumaNE + lumaSE);
	float edgeVert = abs(-2.0 * lumaN + lumaNW + lumaNE) + 2.0 * abs(-2.0 * lumaM + lumaW + lumaE) + abs(-2.0 * lumaS + lumaSW + lumaSE);
	bool isHorz = (edgeHorz >= edgeVert);
	
	float luma1 = isHorz ? lumaN : lumaW;
	float luma2 = isHorz ? lumaS : lumaE;
	float grad1 = abs(luma1 - lumaM);
	float grad2 = abs(luma2 - lumaM);
	bool is1Steeper = (grad1 >= grad2);
	float gradScaled = 0.25 * max(grad1, grad2);
	
	float stepLen = isHorz ? texel.y : texel.x;
	float lumaLocalAvg = 0.0;
	if (is1Steeper)
	{
		stepLen = -stepLen;
		lumaLocalAvg = 0.5 * (luma1 + lumaM);
	}
	else
	{
		lumaLocalAvg = 0.5 * (luma2 + lumaM);
	}
	
	vec2 curUV = vTexCoord;
	if (isHorz)
		curUV.y += stepLen * 0.5;
	else
		curUV.x += stepLen * 0.5;
	
	vec2 spanOff = isHorz ? vec2(texel.x, 0.0) : vec2(0.0, texel.y);
	vec2 uv1 = curUV - spanOff;
	vec2 uv2 = curUV + spanOff;
	
	float lumaEnd1 = rgbLuma(texture2D(/* lod0 */gm_BaseTexture, uv1).rgb) - lumaLocalAvg;
	float lumaEnd2 = rgbLuma(texture2D(/* lod0 */gm_BaseTexture, uv2).rgb) - lumaLocalAvg;
	bool done1 = (abs(lumaEnd1) >= gradScaled);
	bool done2 = (abs(lumaEnd2) >= gradScaled);
	bool bothDone = (done1 && done2);
	
	for (int i = 0; i < 5; i++)
	{
		if (bothDone)
			break;
		float stride = (i == 0) ? 1.5 : ((i < 3) ? 2.0 : ((i == 3) ? 4.0 : 8.0));
		if (!done1)
		{
			uv1 -= spanOff * stride;
			lumaEnd1 = rgbLuma(texture2D(/* lod0 */gm_BaseTexture, uv1).rgb) - lumaLocalAvg;
			done1 = (abs(lumaEnd1) >= gradScaled);
		}
		if (!done2)
		{
			uv2 += spanOff * stride;
			lumaEnd2 = rgbLuma(texture2D(/* lod0 */gm_BaseTexture, uv2).rgb) - lumaLocalAvg;
			done2 = (abs(lumaEnd2) >= gradScaled);
		}
		bothDone = (done1 && done2);
	}
	
	float dst1 = isHorz ? (vTexCoord.x - uv1.x) : (vTexCoord.y - uv1.y);
	float dst2 = isHorz ? (uv2.x - vTexCoord.x) : (uv2.y - vTexCoord.y);
	bool isDir1 = (dst1 < dst2);
	float dstMin = min(dst1, dst2);
	float spanLen = max(dst1 + dst2, 0.0001);
	
	bool goodSpan = isDir1 ? ((lumaEnd1 < 0.0) != ((lumaM - lumaLocalAvg) < 0.0)) : ((lumaEnd2 < 0.0) != ((lumaM - lumaLocalAvg) < 0.0));
	float pixelOffset = goodSpan ? (0.5 - dstMin / spanLen) : 0.0;
	pixelOffset = max(pixelOffset * clamp(uPower, 0.0, 1.5), subpix);
	
	vec2 finalUV = vTexCoord;
	if (isHorz)
		finalUV.y += pixelOffset * stepLen;
	else
		finalUV.x += pixelOffset * stepLen;
	
	vec4 aaCol = texture2D(/* lod0 */gm_BaseTexture, clamp(finalUV, vec2(0.0, 0.0), vec2(1.0, 1.0)));
	gl_FragColor = vec4(aaCol.rgb, clamp(centerCol.a, 0.0, 1.0));
}
