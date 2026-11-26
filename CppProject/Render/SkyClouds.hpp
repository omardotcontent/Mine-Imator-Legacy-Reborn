#pragma once

#include "Generated/Scripts.hpp"

namespace CppProject
{
	inline constexpr IntType ID_shader_sky_clouds = 3015;

	BoolType SkyCloudsVolumetric();
	BoolType SkyCloudsVisible();
	RealType SkyCloudTileSize();
	RealType SkyCloudOffset(RealType tileSize);
	IntType SkyCloudTexture();
	void BindSkyCloudTexture(IntType sampler, IntType texture, BoolType linear);
	void RenderSkyClouds(ScopeAny self, IntType colorSurface, BoolType highQuality);
	void FreeSkyCloudDepth();
}
