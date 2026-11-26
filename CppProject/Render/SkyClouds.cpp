#include "SkyClouds.hpp"

namespace CppProject
{
	static IntType cloudDepth = null_;

	BoolType SkyCloudsVolumetric()
	{
		return global::_app->background_sky_clouds_mode == StringType("volumetric");
	}

	BoolType SkyCloudsVisible()
	{
		return SkyCloudsVolumetric() && global::render_background &&
			global::_app->background_sky_clouds_show > 0 && global::_app->background_sky_clouds_thickness > 0;
	}

	RealType SkyCloudTileSize()
	{
		return max({ 1.0, global::_app->background_sky_clouds_size * 32.0 });
	}

	RealType SkyCloudOffset(RealType tileSize)
	{
		auto* app = global::_app;
		return mod(app->background_sky_clouds_speed * (app->background_time * 0.25 + app->background_sky_time * 100.0) +
			app->background_sky_clouds_offset, tileSize);
	}

	IntType SkyCloudTexture()
	{
		VarType res = global::_app->background_sky_clouds_tex;
		if (!res_is_ready(res))
			res = global::mc_res;
		return idVar(res, type) == e_res_type_PACK ? idVar(res, clouds_texture) : idVar(res, texture);
	}

	void BindSkyCloudTexture(IntType sampler, IntType texture, BoolType linear)
	{
		texture_set_stage(sampler, sprite_get_texture(texture, IntType(0)));
		gpu_set_texfilter_ext(sampler, linear);
		gpu_set_texrepeat_ext(sampler, true);
	}

	void FreeSkyCloudDepth()
	{
		surface_free(cloudDepth);
		cloudDepth = null_;
	}

	void RenderSkyClouds(ScopeAny self, IntType colorSurface, BoolType highQuality, BoolType allowFog)
	{
		if (!SkyCloudsVisible())
			return;
		const IntType cloudTexture = SkyCloudTexture();
		if (!sprite_exists(cloudTexture))
			return;

		// The post-effect G-buffer is clipped at 5000 units. Use scene depth out to the camera's far plane.
		cloudDepth = surface_require(cloudDepth, global::render_width, global::render_height);
		surface_set_target(cloudDepth);
		gpu_set_blendmode_ext(bm_one, bm_zero);
		draw_clear_alpha(c_white, 0.0);
		render_world_start();
		const MatrixType projectionInv = matrix_inverse(global::proj_matrix);
		const MatrixType viewInv = matrix_inverse(global::view_matrix);
		const RealType nearPlane = global::cam_near;
		const RealType farPlane = global::cam_far;
		render_world(self, e_render_mode_DEPTH_NO_SKY);
		render_world_done();
		surface_reset_target();

		const RealType tileSize = SkyCloudTileSize();
		auto* app = global::_app;
		surface_set_target(colorSurface);
		render_set_projection_ortho(0, 0, global::render_width, global::render_height, 0);
		gpu_set_blendmode_ext_sepalpha(bm_one, bm_inv_src_alpha, bm_zero, bm_one);
		global::render_shader_obj = DsMap(global::shader_map).Value(ID_shader_sky_clouds);
		withOne (obj_shader, global::render_shader_obj, noone)
		{
			shader_set(self->shader);
			const IntType depthSampler = DsMap(self->sampler_map).Value(StringType("uDepthBuffer"));
			texture_set_stage(depthSampler, surface_get_texture(cloudDepth));
			gpu_set_texfilter_ext(depthSampler, false);
			gpu_set_texrepeat_ext(depthSampler, false);
			BindSkyCloudTexture(DsMap(self->sampler_map).Value(StringType("uCloudTexture")), cloudTexture, false);

			render_set_uniform(StringType("uProjMatrixInv"), projectionInv);
			render_set_uniform(StringType("uViewMatrixInv"), viewInv);
			render_set_uniform_vec2(StringType("uDepthRange"), nearPlane, farPlane);
			render_set_uniform_vec2(StringType("uScreenSize"), global::render_width, global::render_height);
			render_set_uniform(StringType("uCloudTileSize"), tileSize);
			render_set_uniform(StringType("uCloudOffset"), SkyCloudOffset(tileSize));
			render_set_uniform(StringType("uCloudHeight"), app->background_sky_clouds_height);
			render_set_uniform(StringType("uCloudThickness"), app->background_sky_clouds_thickness);
			render_set_uniform_color(StringType("uCloudColor"), app->background_sky_clouds_final, 1.0);
			render_set_uniform_color(StringType("uCloudFogColor"), app->background_fog_color_final, 1.0);
			render_set_uniform_vec2(StringType("uCloudFogRange"),
				app->background_fog_distance - max({ 1.0, app->background_fog_size }), app->background_fog_distance);
			render_set_uniform_int(StringType("uCloudFog"), allowFog && app->background_fog_show > 0 && app->background_fog_sky > 0);
			render_set_uniform_int(StringType("uCloudHeightFog"), highQuality && allowFog && app->project_render_height_fog > 0);
			render_set_uniform_vec2(StringType("uCloudHeightFogParams"), app->project_render_height_fog_height, app->project_render_height_fog_density);
			render_set_uniform_color(StringType("uCloudHeightFogColor"), app->project_render_height_fog_color, 1.0);
			render_set_uniform(StringType("uCloudFogScatter"), (highQuality && allowFog) ? (RealType)app->project_render_fog_scatter : 0.0);
			render_set_uniform_color(StringType("uCloudFogScatterColor"), app->project_render_fog_scatter_color, 1.0);
			VecType& sun = app->background_sun_direction;
			render_set_uniform_vec3(StringType("uCloudSunDir"), sun.Real(X_), sun.Real(Y_), sun.Real(Z_));
			render_set_uniform_color(StringType("uCloudSunColor"), app->background_sunlight_color_final, 1.0);
			render_set_uniform_int(StringType("uCloudSteps"), highQuality ? 48 : 12);
			render_set_uniform_int(StringType("uCloudLightSteps"), highQuality ? 4 : 1);
			draw_blank(0, 0, global::render_width, global::render_height);
			shader_clear();
		}
		gpu_set_blendmode(bm_normal);
		surface_reset_target();
	}
}
