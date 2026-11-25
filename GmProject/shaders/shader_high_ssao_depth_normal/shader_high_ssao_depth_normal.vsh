/// shader_high_ssao_depth_normal
/// @desc Renders 3-MRT shared G-buffer: depth, view-space normal (normal maps + water/rain ripples), and (ssaoBright, reflectivity, waterMask)

attribute vec3 in_Position;
attribute vec3 in_Normal;
attribute vec4 in_Colour;
attribute vec2 in_TextureCoord;
attribute vec4 in_Wave;
attribute vec3 in_Tangent;

uniform float uFar; // static
uniform float uNear; // static
uniform vec4 uBlendColor;

varying vec3 vWorldPos;
varying vec3 vWorldNormal;
varying vec3 vViewPos;
varying vec2 vTexCoord;
varying float vDepth;
varying vec3 vNormal;
varying vec3 vTangent;
varying float vHasTangent;
varying vec4 vColor;
varying vec4 vCustom;

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

mat3 transpose2(mat3 mat)
{
	mat3 trans;
	
	trans[0][0] = mat[0][0];
	trans[1][0] = mat[0][1];
	trans[2][0] = mat[0][2];
	trans[0][1] = mat[1][0];
	trans[1][1] = mat[1][1];
	trans[2][1] = mat[1][2];
	trans[0][2] = mat[2][0];
	trans[1][2] = mat[2][1];
	trans[2][2] = mat[2][2];
	
	return trans;
}

mat3 inverse2(mat4 Original)
{
	float det = Original[0][0] * Original[1][1] * Original[2][2]
			  + Original[0][1] * Original[1][2] * Original[2][0]
			  + Original[0][2] * Original[1][0] * Original[2][1]
			  - Original[0][0] * Original[1][2] * Original[2][1]
			  - Original[0][1] * Original[1][0] * Original[2][2]
			  - Original[0][2] * Original[1][1] * Original[2][0];
						
	float inv_det = 1.0 / det;
	
	mat3 tmp;
	tmp[0][0] = Original[1][1] * Original[2][2] - Original[2][1] * Original[1][2];
	tmp[1][0] = Original[2][0] * Original[1][2] - Original[1][0] * Original[2][2];
	tmp[2][0] = Original[1][0] * Original[2][1] - Original[2][0] * Original[1][1];
	tmp[0][1] = Original[2][1] * Original[0][2] - Original[0][1] * Original[2][2];
	tmp[1][1] = Original[0][0] * Original[2][2] - Original[2][0] * Original[0][2];
	tmp[2][1] = Original[2][0] * Original[0][1] - Original[0][0] * Original[2][1];
	tmp[0][2] = Original[0][1] * Original[1][2] - Original[1][1] * Original[0][2];
	tmp[1][2] = Original[1][0] * Original[0][2] - Original[0][0] * Original[1][2];
	tmp[2][2] = Original[0][0] * Original[1][1] - Original[1][0] * Original[0][1];
	
	mat3 Result;
	Result[0][0] = inv_det * tmp[0][0];
	Result[1][0] = inv_det * tmp[1][0];
	Result[2][0] = inv_det * tmp[2][0];
	Result[0][1] = inv_det * tmp[0][1];
	Result[1][1] = inv_det * tmp[1][1];
	Result[2][1] = inv_det * tmp[2][1];
	Result[0][2] = inv_det * tmp[0][2];
	Result[1][2] = inv_det * tmp[1][2];
	Result[2][2] = inv_det * tmp[2][2];
	
	return transpose2(Result);
}

void main()
{
	vec3 pos;
	if (max((in_Wave.x + in_Wave.y) * uWindTerrain, uWindEnable) * uWindStrength > 0.0)
	{
		pos = (gm_Matrices[MATRIX_WORLD] * vec4(in_Position + getWind(), 1.0)).xyz;
		pos += getWindAngle(in_Position);
	}
	else
		pos = (gm_Matrices[MATRIX_WORLD] * vec4(in_Position, 1.0)).xyz;
	
	vec4 viewPos = gm_Matrices[MATRIX_VIEW] * vec4(pos, 1.0);
	gl_Position = gm_Matrices[MATRIX_PROJECTION] * viewPos;
	
	vWorldPos = pos;
	float wnLen = length((gm_Matrices[MATRIX_WORLD] * vec4(in_Normal, 0.0)).xyz);
	vWorldNormal = (wnLen > 0.0001) ? ((gm_Matrices[MATRIX_WORLD] * vec4(in_Normal, 0.0)).xyz / wnLen) : vec3(0.0, 0.0, 1.0);
	vViewPos = viewPos.xyz;
	vTexCoord = in_TextureCoord + uTextureOffset;
	vDepth = (viewPos.z - uNear) / (uFar - uNear);
	
	mat3 worldViewInv = inverse2(gm_Matrices[MATRIX_WORLD_VIEW]);
	vec3 nrm = normalize(worldViewInv * in_Normal);
	vNormal = nrm;
	
	vec3 tng = (gm_Matrices[MATRIX_WORLD_VIEW] * vec4(in_Tangent, 0.0)).xyz;
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
	
	vColor = uBlendColor * in_Colour;
	vCustom = in_Wave;
}
