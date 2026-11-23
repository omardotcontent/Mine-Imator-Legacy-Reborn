/// shader_high_light_sun_set()

function shader_high_light_sun_set()
{
	render_set_uniform("uBrightness", 0)
	
	render_set_uniform_int("uIsGround", 0)
	render_set_uniform_int("uIsSky", 0)
	render_set_uniform_int("uIsWater", 0)
	
	render_set_uniform("uLightMatrix", render_light_matrix)
	if (app.background_sunlight_follow)
		render_set_uniform_vec3("uSunAt", cam_from[X], cam_from[Y], 0)
	else
		render_set_uniform_vec3("uSunAt", 0, 0, 0)
	
	render_set_uniform_vec3("uLightPosition", render_light_from[X], render_light_from[Y], render_light_from[Z])
	render_set_uniform("uLightNear", render_light_near)
	render_set_uniform("uLightFar", render_light_far)
	render_set_uniform_color("uLightColor", render_light_color, 1)
	
	texture_set_stage(sampler_map[?"uDepthBuffer"], surface_get_texture(render_surface_sun_buffer))
	gpu_set_texfilter_ext(sampler_map[?"uDepthBuffer"], true)
	gpu_set_texrepeat_ext(sampler_map[?"uDepthBuffer"], false)
	
	if (app.project_render_shadows_blur_size > 0)
		render_set_uniform_int("uBlurQuality", app.project_render_shadows_blur_quality)
	else
		render_set_uniform_int("uBlurQuality", 1)
	
	if (app.project_render_shadows_blur_quality > 1)
		render_set_uniform("uBlurSize", app.project_render_shadows_blur_size)
	else
		render_set_uniform("uBlurSize", 0)
	
	render_set_uniform("uDiffuseBoost", app.background_sunlight_strength)
	
	// Cloud Shadows (aligned 1:1 with actual sky clouds texture & background_sky_update)
	var cloudshow = (app.project_render_cloud_shadows && app.background_sky_clouds_show);
	var cloudsize = max(1, app.background_sky_clouds_size * 32);
	var cloudoff = ((app.background_sky_clouds_speed * (app.background_time * 0.25 + app.background_sky_time * 100) + app.background_sky_clouds_offset) mod cloudsize);
	render_set_uniform_int("uCloudShadows", cloudshow)
	render_set_uniform("uCloudShadowsStrength", app.project_render_cloud_shadows_strength)
	render_set_uniform("uCloudShadowsScale", app.project_render_cloud_shadows_scale)
	render_set_uniform("uCloudTileSize", cloudsize)
	render_set_uniform("uCloudOffset", cloudoff)
	render_set_uniform("uCloudHeight", app.background_sky_clouds_height)
	
	var cloudres = app.background_sky_clouds_tex;
	if (!res_is_ready(cloudres))
		cloudres = mc_res
	var cloudtex;
	if (cloudres.type = e_res_type.PACK)
		cloudtex = cloudres.clouds_texture
	else
		cloudtex = cloudres.texture
	if (sprite_exists(cloudtex))
		texture_set_stage(sampler_map[?"uCloudTexture"], sprite_get_texture(cloudtex, 0))
	else
		texture_set_stage(sampler_map[?"uCloudTexture"], surface_get_texture(render_surface_sun_buffer))
	gpu_set_texfilter_ext(sampler_map[?"uCloudTexture"], true)
	gpu_set_texrepeat_ext(sampler_map[?"uCloudTexture"], true)
	
	// Stained Glass Colored Shadows
	var usecolsh = (app.project_render_colored_shadows && surface_exists(render_surface_sun_color));
	render_set_uniform_int("uColoredShadows", usecolsh)
	render_set_uniform("uColoredShadowsStrength", app.project_render_colored_shadows_strength)
	if (usecolsh)
	{
		texture_set_stage(sampler_map[?"uTransColorBuffer"], surface_get_texture(render_surface_sun_color))
		gpu_set_texfilter_ext(sampler_map[?"uTransColorBuffer"], true)
		gpu_set_texrepeat_ext(sampler_map[?"uTransColorBuffer"], false)
	}
	else
		texture_set_stage(sampler_map[?"uTransColorBuffer"], surface_get_texture(render_surface_sun_buffer))
}
