/// shader_use()
/// @desc Sets the shader and defines the common uniforms

function shader_use()
{
	shader_set(shader)
	
	// Default color
	shader_blend_color = c_white
	shader_blend_alpha = 1
	render_set_uniform_color("uBlendColor", c_white, 1)
	
	render_set_uniform("uTAAMatrix", MAT_IDENTITY)
	render_set_uniform("uSampleIndex", 0)
	render_set_uniform_int("uAlphaHash", 0)
	
	// Set wind
	if (!is_undefined(uniform_map[?"uTime"]) && uniform_map[?"uTime"] > -1)
	{
		render_set_uniform("uTime", app.background_time)
		render_set_uniform("uWindEnable", 0)
		render_set_uniform("uWindTerrain", 1)
		render_set_uniform("uWindSpeed", app.background_wind * app.background_wind_speed)
		render_set_uniform("uWindStrength", app.background_wind_strength * app.setting_wind_enable)
		
		render_set_uniform_vec2("uWindDirection", sin(degtorad(app.background_wind_direction)), cos(degtorad(app.background_wind_direction)))
		render_set_uniform("uWindDirectionalSpeed", app.background_wind * app.background_wind_directional_speed * .1 * app.background_time)
		render_set_uniform("uWindDirectionalStrength", app.background_wind * app.background_wind_directional_strength * app.setting_wind_enable)
	}
	
	// Set fog
	if (!is_undefined(uniform_map[?"uFogShow"]) && uniform_map[?"uFogShow"] > -1)
	{
		var fog = (render_lights && app.background_fog_show && render_mode != e_render_mode.COLOR);
		render_set_uniform_int("uFogShow", bool_to_float(fog))
		
		render_set_uniform_color("uFogColor", app.background_fog_object_color_final, 1)
		render_set_uniform("uFogDistance", app.background_fog_distance)
		render_set_uniform("uFogSize", app.background_fog_size + (app.background_fog_size * 3 * max(app.background_sunrise_alpha, app.background_sunset_alpha)))
		render_set_uniform("uFogHeight", app.background_fog_height)
	}
	
	// Set camera position
	if (!is_undefined(uniform_map[?"uCameraPosition"]) && uniform_map[?"uCameraPosition"] > -1)
		render_set_uniform_vec3("uCameraPosition", cam_from[X], cam_from[Y], cam_from[Z])
	
	// Classic 1.2.9 block brightness / glow / light bleeding
	if (!is_undefined(uniform_map[?"uBlockBrightness"]) && uniform_map[?"uBlockBrightness"] > -1)
		render_set_uniform("uBlockBrightness", app.project_render_block_emissive)
	
	if (!is_undefined(uniform_map[?"uBlockGlow"]) && uniform_map[?"uBlockGlow"] > -1)
		render_set_uniform_int("uBlockGlow", app.project_render_block_glow)
	
	if (!is_undefined(uniform_map[?"uGlowThreshold"]) && uniform_map[?"uGlowThreshold"] > -1)
		render_set_uniform("uGlowThreshold", app.project_render_block_glow_threshold)
	
	if (!is_undefined(uniform_map[?"uLightBleed"]) && uniform_map[?"uLightBleed"] > -1)
		render_set_uniform("uLightBleed", bool_to_float(app.project_render_light_bleeding))
	
	if (!is_undefined(uniform_map[?"uLightBleedStrength"]) && uniform_map[?"uLightBleedStrength"] > -1)
		render_set_uniform("uLightBleedStrength", app.project_render_light_bleeding_strength)
	
	if (!is_undefined(uniform_map[?"uBrightness"]) && uniform_map[?"uBrightness"] > -1)
		render_set_uniform("uBrightness", 0)
	
	if (!is_undefined(uniform_map[?"uBleedLight"]) && uniform_map[?"uBleedLight"] > -1)
		render_set_uniform("uBleedLight", 0)
	
	if (!is_undefined(uniform_map[?"uSubsurfaceColor"]) && uniform_map[?"uSubsurfaceColor"] > -1)
		render_set_uniform_color("uSubsurfaceColor", c_white, 1)
	
	if (!is_undefined(uniform_map[?"uSSAOEnable"]) && uniform_map[?"uSSAOEnable"] > -1)
		render_set_uniform_int("uSSAOEnable", 1)
	
	// Object Material & Normal Maps
	if (!is_undefined(uniform_map[?"uUseNormalMap"]) && uniform_map[?"uUseNormalMap"] > -1)
		render_set_uniform_int("uUseNormalMap", app.project_render_material_maps)
	
	if (!is_undefined(uniform_map[?"uUseMaterialMap"]) && uniform_map[?"uUseMaterialMap"] > -1)
		render_set_uniform_int("uUseMaterialMap", app.project_render_material_maps)
	
	if (!is_undefined(uniform_map[?"uMaterialFormat"]) && uniform_map[?"uMaterialFormat"] > -1)
		render_set_uniform_int("uMaterialFormat", e_material.FORMAT_NONE)
	
	if (!is_undefined(uniform_map[?"uRoughness"]) && uniform_map[?"uRoughness"] > -1)
		render_set_uniform("uRoughness", 0.5)
	
	if (!is_undefined(uniform_map[?"uMetallic"]) && uniform_map[?"uMetallic"] > -1)
		render_set_uniform("uMetallic", 0)
	
	if (!is_undefined(uniform_map[?"uDefaultEmissive"]) && uniform_map[?"uDefaultEmissive"] > -1)
		render_set_uniform("uDefaultEmissive", app.project_render_block_emissive)
	
	// Enhanced 1.2.9 Lighting uniforms
	if (!is_undefined(uniform_map[?"uShadowBias"]) && uniform_map[?"uShadowBias"] > -1)
		render_set_uniform("uShadowBias", app.project_render_shadows_bias)
	
	if (!is_undefined(uniform_map[?"uShadowDarkness"]) && uniform_map[?"uShadowDarkness"] > -1)
		render_set_uniform("uShadowDarkness", app.project_render_shadows_darkness)
	
	if (!is_undefined(uniform_map[?"uShadowTint"]) && uniform_map[?"uShadowTint"] > -1)
		render_set_uniform_color("uShadowTint", app.project_render_shadows_tint, 1)
	
	if (!is_undefined(uniform_map[?"uHemiEnable"]) && uniform_map[?"uHemiEnable"] > -1)
	{
		render_set_uniform_int("uHemiEnable", app.project_render_hemi_light)
		render_set_uniform("uHemiStrength", app.project_render_hemi_strength)
		render_set_uniform_color("uHemiSkyColor", app.project_render_hemi_sky_color, 1)
		render_set_uniform_color("uHemiGroundColor", app.project_render_hemi_ground_color, 1)
	}
	
	if (!is_undefined(uniform_map[?"uRimEnable"]) && uniform_map[?"uRimEnable"] > -1)
	{
		render_set_uniform_int("uRimEnable", app.project_render_rim_light)
		render_set_uniform("uRimStrength", app.project_render_rim_strength)
		render_set_uniform("uRimPower", app.project_render_rim_power)
		render_set_uniform_color("uRimColor", app.project_render_rim_color, 1)
	}
	
	if (!is_undefined(uniform_map[?"uSpecularEnable"]) && uniform_map[?"uSpecularEnable"] > -1)
	{
		render_set_uniform_int("uSpecularEnable", app.project_render_specular)
		render_set_uniform("uSpecularStrength", app.project_render_specular_strength)
		render_set_uniform("uSpecularShininess", app.project_render_specular_shininess)
	}
	
	var highmode = (render_quality = e_view_mode.RENDER && render_mode != e_render_mode.PREVIEW);
	
	if (!is_undefined(uniform_map[?"uRippleTime"]) && uniform_map[?"uRippleTime"] > -1)
	{
		var rtime;
		if (app.window_state = "export_movie" || app.window_state = "export_image")
			rtime = app.background_time / 60
		else
			rtime = app.background_time / 60 + current_time / 1000
		render_set_uniform("uRippleTime", rtime)
	}
	
	if (!is_undefined(uniform_map[?"uIsSky"]) && uniform_map[?"uIsSky"] > -1)
		render_set_uniform_int("uIsSky", 0)
	
	if (!is_undefined(uniform_map[?"uIsGround"]) && uniform_map[?"uIsGround"] > -1)
		render_set_uniform_int("uIsGround", 0)
	
	if (!is_undefined(uniform_map[?"uOutlineEnable"]) && uniform_map[?"uOutlineEnable"] > -1)
		render_set_uniform_int("uOutlineEnable", 1)
	
	if (!is_undefined(uniform_map[?"uSkyColor"]) && uniform_map[?"uSkyColor"] > -1)
		render_set_uniform_color("uSkyColor", app.background_sky_color_final, 1)
	
	if (!is_undefined(uniform_map[?"uHorizonColor"]) && uniform_map[?"uHorizonColor"] > -1)
		render_set_uniform_color("uHorizonColor", app.background_fog_color_final, 1)
	
	var cam_wet_ov = (render_camera != null && render_effects && render_camera.value[e_value.CAM_WETNESS_OVERRIDE]);
	
	if (!is_undefined(uniform_map[?"uWaterRipples"]) && uniform_map[?"uWaterRipples"] > -1)
	{
		if (cam_wet_ov)
		{
			render_set_uniform_int("uWaterRipples", highmode && render_camera.value[e_value.CAM_WATER_RIPPLES])
			render_set_uniform("uWaterRippleStrength", render_camera.value[e_value.CAM_WATER_RIPPLE_STRENGTH])
			render_set_uniform("uWaterRippleSpeed", render_camera.value[e_value.CAM_WATER_RIPPLE_SPEED])
		}
		else
		{
			render_set_uniform_int("uWaterRipples", highmode && app.project_render_water_ripples)
			render_set_uniform("uWaterRippleStrength", app.project_render_water_ripple_strength)
			render_set_uniform("uWaterRippleSpeed", app.project_render_water_ripple_speed)
		}
	}
	
	if (!is_undefined(uniform_map[?"uWetness"]) && uniform_map[?"uWetness"] > -1)
	{
		if (!highmode)
			render_set_uniform("uWetness", 0)
		else if (cam_wet_ov)
			render_set_uniform("uWetness", render_camera.value[e_value.CAM_WETNESS])
		else
			render_set_uniform("uWetness", app.project_render_wetness)
	}
	
	if (!is_undefined(uniform_map[?"uWetnessRipples"]) && uniform_map[?"uWetnessRipples"] > -1)
	{
		if (cam_wet_ov)
			render_set_uniform_int("uWetnessRipples", render_camera.value[e_value.CAM_WETNESS_RIPPLES])
		else
			render_set_uniform_int("uWetnessRipples", app.project_render_wetness_ripples)
	}
	
	if (!is_undefined(uniform_map[?"uCelEnable"]) && uniform_map[?"uCelEnable"] > -1)
	{
		if (render_camera != null && render_effects && render_camera.value[e_value.CAM_CEL_SHADING])
		{
			render_set_uniform_int("uCelEnable", 1)
			render_set_uniform("uCelSteps", render_camera.value[e_value.CAM_CEL_STEPS])
			render_set_uniform("uCelSmooth", render_camera.value[e_value.CAM_CEL_SMOOTHNESS])
		}
		else
		{
			render_set_uniform_int("uCelEnable", app.project_render_cel_shading)
			render_set_uniform("uCelSteps", app.project_render_cel_steps)
			render_set_uniform("uCelSmooth", app.project_render_cel_smoothness)
		}
	}
	
	if (!is_undefined(uniform_map[?"uSunDir"]) && uniform_map[?"uSunDir"] > -1)
		render_set_uniform_vec3("uSunDir", app.background_sun_direction[X], app.background_sun_direction[Y], app.background_sun_direction[Z])
	
	if (!is_undefined(uniform_map[?"uHeightFogEnable"]) && uniform_map[?"uHeightFogEnable"] > -1)
	{
		render_set_uniform_int("uHeightFogEnable", app.project_render_height_fog)
		render_set_uniform("uHeightFogHeight", app.project_render_height_fog_height)
		render_set_uniform("uHeightFogDensity", app.project_render_height_fog_density)
	}
	
	if (!is_undefined(uniform_map[?"uSkipTranslucent"]) && uniform_map[?"uSkipTranslucent"] > -1)
		render_set_uniform_int("uSkipTranslucent", (render_mode = e_render_mode.HIGH_LIGHT_SUN_DEPTH && app.project_render_colored_shadows) ? 1 : 0)
	
	if (!is_undefined(uniform_map[?"uIsWater"]) && uniform_map[?"uIsWater"] > -1)
		render_set_uniform_int("uIsWater", 0)
	
	// Default material & normal textures
	render_set_texture(spr_default_material, "Material")
	render_set_texture(spr_default_normal, "Normal")
	
	// Glint
	if (!is_undefined(uniform_map[?"uGlintEnabled"]) && uniform_map[?"uGlintEnabled"] > -1)
	{
		var tex = mc_res.glint_armor_texture;
		texture_set_stage(sampler_map[?"uGlintTexture"], sprite_get_texture(tex, 0))
		gpu_set_texrepeat_ext(sampler_map[?"uGlintTexture"], true)
		if (platform_get() == e_platform.WINDOWS) // OpenGL bug workaround
			gpu_set_tex_filter_ext(sampler_map[?"uGlintTexture"], true)
		
		render_set_uniform_vec2("uGlintSize", sprite_get_width(tex)*2, sprite_get_height(tex)*2)
		render_set_uniform_vec2("uGlintOffset", app.background_time * (0.000625) * app.project_render_glint_speed, app.background_time * (0.00125) * app.project_render_glint_speed)
		render_set_uniform_int("uGlintEnabled", 1)
		render_set_uniform("uGlintStrength", app.project_render_glint_strength)
	}
	
	// Texture drawing
	render_set_uniform("uMask", bool_to_float(shader_mask))
	
	if (!is_undefined(uniform_map[?"uReplaceColor"]) && uniform_map[?"uReplaceColor"] > -1)
		render_set_uniform_color("uReplaceColor", c_white, 1)
	
	if (!is_undefined(uniform_map[?"uTextureOffset"]) && uniform_map[?"uTextureOffset"] > -1)
		render_set_uniform_vec2("uTextureOffset", 0, 0)
	
	// Init script
	if (script > -1)
		script_execute(script)
}
