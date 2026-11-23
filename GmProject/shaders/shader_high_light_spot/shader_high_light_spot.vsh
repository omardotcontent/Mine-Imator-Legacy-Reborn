/// shader_high_light_spot
/// @desc Add shadows, normal/material maps & specular from a spot light (Enhanced 1.2.9 renderer)

attribute vec3 in_Position;
attribute vec3 in_Normal;
attribute vec4 in_Colour;
attribute vec2 in_TextureCoord;
attribute vec4 in_Wave;
attribute vec3 in_Tangent;

uniform vec4 uBlendColor;
uniform int uLightAmount; // static
uniform mat4 uLightMatrix; // static
uniform float uBrightness;
uniform float uBlockBrightness; // static
uniform float uLightBleed; // static

varying vec3 vPosition;
varying vec3 vNormal;
varying vec3 vTangent;
varying float vHasTangent;
varying vec2 vTexCoord;
varying vec4 vColor;
varying vec4 vScreenCoord;
varying float vBrightness;
varying float vLightBleed;

// Texture
uniform vec2 uTextureOffset;

// Wind
uniform float uTime; // static
uniform float uWindEnable;
uniform float uWindTerrain;
uniform float uWindSpeed; // static
uniform float uWindStrength;
uniform vec2 uWindDirection; // static
uniform float uWindDirectionalSpeed; // static
uniform float uWindDirectionalStrength;

#define PI 3.14159265
float getNoise(float v)
{
	return cos(v * PI) * cos(v * 3.0 * PI) * cos(v * 5.0 * PI) * cos(v * 7.0 * PI) + sin(v * 5.0 * PI) * 0.1;
}

vec3 getWind()
{
	return vec3(
		sin((uTime + in_Position.x * 10.0 + in_Position.y + in_Position.z) * (uWindSpeed / 5.0)) * max(in_Wave.x * uWindTerrain, uWindEnable) * uWindStrength,
		sin((uTime + in_Position.x + in_Position.y * 10.0 + in_Position.z) * (uWindSpeed / 7.5)) * max(in_Wave.x * uWindTerrain, uWindEnable) * uWindStrength,
		sin((uTime + in_Position.x + in_Position.y + in_Position.z * 10.0) * (uWindSpeed / 10.0)) * max(in_Wave.y * uWindTerrain, uWindEnable) * uWindStrength
	);
}

vec3 getWindAngle(vec3 pos)
{
	float strength = dot(pos.xy/16.0, uWindDirection) / dot(uWindDirection, uWindDirection);
	float diroff = getNoise(((uWindDirectionalSpeed - (strength / 3.0) - (pos.z/64.0)) * .075));
	return vec3(uWindDirection * diroff, 0.0) * (1.0 - step(max(in_Wave.x * uWindTerrain, uWindEnable), 0.0)) * uWindDirectionalStrength;
}

void main()
{
	if (max((in_Wave.x + in_Wave.y) * uWindTerrain, uWindEnable) * uWindStrength > 0.0)
	{
		vPosition = (gm_Matrices[MATRIX_WORLD] * vec4(in_Position + getWind(), 1.0)).xyz;
		vPosition += getWindAngle(in_Position);
	}
	else
		vPosition = (gm_Matrices[MATRIX_WORLD] * vec4(in_Position, 1.0)).xyz;
	
	vec3 nrm = normalize((gm_Matrices[MATRIX_WORLD] * vec4(in_Normal, 0.0)).xyz);
	vNormal = nrm;
	
	vec3 tng = (gm_Matrices[MATRIX_WORLD] * vec4(in_Tangent, 0.0)).xyz;
	float tLen = length(tng);
	if (tLen > 0.0001)
	{
		tng = tng / tLen;
		tng = tng - dot(tng, nrm) * nrm;
		float oLen = length(tng);
		vTangent = (oLen > 0.0001) ? (tng / oLen) : vec3(1.0, 0.0, 0.0);
		vHasTangent = (oLen > 0.0001) ? 1.0 : 0.0;
	}
	else
	{
		vTangent = vec3(1.0, 0.0, 0.0);
		vHasTangent = 0.0;
	}
	
	vTexCoord = in_TextureCoord + uTextureOffset;
	vColor = uBlendColor * in_Colour;
	vScreenCoord = uLightMatrix * vec4(vPosition, 1.0);
	vBrightness = clamp(in_Wave.z * uBlockBrightness + uBrightness / float(max(uLightAmount, 1)), 0.0, 1.0);
	vLightBleed = in_Wave.w * uLightBleed;
	
	gl_Position = gm_Matrices[MATRIX_PROJECTION] * (gm_Matrices[MATRIX_VIEW] * vec4(vPosition, 1.0));
}
