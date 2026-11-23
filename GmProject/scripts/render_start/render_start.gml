/// render_start(target, camera, [width, height])
/// @arg target
/// @arg camera
/// @arg [width
/// @arg height]

function render_start()
{
	render_target = argument[0]
	render_camera = argument[1]
	render_width = project_video_width
	render_height = project_video_height
	
	if (surface_exists(render_pass_surf))
		surface_free(render_pass_surf)
	
	render_pass_surf = null
	render_world_count = 0
	
	render_pass = project_render_pass
	
	// Classic 1.2.9 rendering effects
	render_ssao = project_render_ssao
	render_shadows = project_render_shadows
	render_indirect = false
	render_reflections = false
	render_depth_normals = false
	
	var cam_godrays = false;
	var cam_lensflare = false;
	var cam_outline = false;
	var cam_retro = false;
	var cam_ssr = false;
	var cam_contact_shadows = false;
	var cam_volumetric = false;
	var cam_motion_fx = false;
	var cam_weather_fx = false;
	var cam_tonemap_extra = false;
	if (render_camera != null && render_effects)
	{
		cam_godrays = render_camera.value[e_value.CAM_GODRAYS]
		cam_lensflare = render_camera.value[e_value.CAM_LENSFLARE]
		cam_outline = render_camera.value[e_value.CAM_OUTLINE]
		cam_retro = render_camera.value[e_value.CAM_RETRO]
		cam_ssr = render_camera.value[e_value.CAM_SSR]
		cam_contact_shadows = render_camera.value[e_value.CAM_CONTACT_SHADOWS]
		cam_volumetric = render_camera.value[e_value.CAM_VOLUMETRIC_LIGHTS]
		cam_motion_fx = render_camera.value[e_value.CAM_MOTION_FX]
		cam_weather_fx = render_camera.value[e_value.CAM_WEATHER_FX]
		if (render_camera.value[e_value.CAM_LIGHT_MANAGEMENT])
			cam_tonemap_extra = true
		if (render_camera.value[e_value.CAM_COLOR_CORRECTION])
		{
			if (abs(render_camera.value[e_value.CAM_TEMPERATURE]) > 0.001 ||
				abs(render_camera.value[e_value.CAM_TINT]) > 0.001 ||
				abs(render_camera.value[e_value.CAM_LIFT_SHADOWS]) > 0.001 ||
				abs(render_camera.value[e_value.CAM_LIFT_MIDTONES]) > 0.001 ||
				abs(render_camera.value[e_value.CAM_LIFT_HIGHLIGHTS]) > 0.001 ||
				render_camera.value[e_value.CAM_SHARPEN] > 0.001)
				cam_tonemap_extra = true
		}
	}
	
	render_glow = project_render_glow && (render_quality = e_view_mode.RENDER)
	render_glow_falloff = project_render_glow && project_render_glow_falloff && (render_quality = e_view_mode.RENDER)
	render_aa = project_render_aa && (render_quality = e_view_mode.RENDER)
	render_godrays = (project_render_godrays || cam_godrays) && (render_quality = e_view_mode.RENDER) && !render_pass
	render_ssr = (project_render_ssr || cam_ssr) && (render_quality = e_view_mode.RENDER) && !render_pass
	render_contact_shadows = (project_render_contact_shadows || cam_contact_shadows) && (render_quality = e_view_mode.RENDER) && !render_pass
	render_lensflare = (project_render_lensflare || cam_lensflare) && (render_quality = e_view_mode.RENDER) && !render_pass
	render_global_bloom = project_render_global_bloom && (render_quality = e_view_mode.RENDER) && !render_pass
	render_outline = (project_render_outline || cam_outline) && (render_quality = e_view_mode.RENDER) && !render_pass
	render_retro = (project_render_retro || cam_retro) && (render_quality = e_view_mode.RENDER) && !render_pass
	render_volumetric_lights = (project_render_volumetric_lights || cam_volumetric) && (render_quality = e_view_mode.RENDER) && !render_pass
	render_motion_fx = (project_render_motion_fx || cam_motion_fx) && (render_quality = e_view_mode.RENDER) && !render_pass
	render_weather_fx = (project_render_weather_fx || cam_weather_fx) && (render_quality = e_view_mode.RENDER) && !render_pass
	render_tonemap_pass = (render_quality = e_view_mode.RENDER) && !render_pass && (
		cam_tonemap_extra ||
		project_render_tonemapper > 0 ||
		abs(project_render_exposure - 1) > 0.001 ||
		abs(project_render_gamma - 1) > 0.001 ||
		abs(project_render_contrast - 1) > 0.001 ||
		abs(project_render_saturation - 1) > 0.001 ||
		abs(project_render_vibrance) > 0.001 ||
		project_render_sharpen > 0.001 ||
		abs(project_render_temperature) > 0.001 ||
		abs(project_render_tint) > 0.001 ||
		abs(project_render_lift_shadows) > 0.001 ||
		abs(project_render_lift_midtones) > 0.001 ||
		abs(project_render_lift_highlights) > 0.001 ||
		project_render_global_ca > 0.001 ||
		project_render_global_grain > 0.001 ||
		project_render_global_vignette > 0.001
	)
	
	// Use camera settings
	if (render_camera != null)
	{
		if (!render_camera.value[e_value.CAM_SIZE_USE_PROJECT])
		{
			render_width = render_camera.value[e_value.CAM_WIDTH]
			render_height = render_camera.value[e_value.CAM_HEIGHT]
		}
		
		render_camera_bloom = (render_effects && render_camera.value[e_value.CAM_BLOOM]) && !render_pass
		render_camera_lens_dirt = (render_effects && render_camera.value[e_value.CAM_LENS_DIRT] && render_camera.value[e_value.TEXTURE_OBJ] != null) && !render_pass
		render_camera_dof = (render_effects && render_camera.value[e_value.CAM_DOF]) && !render_pass
		render_camera_color_correction = (render_effects && render_camera.value[e_value.CAM_COLOR_CORRECTION]) && !render_pass
		render_camera_grain = (render_effects && render_camera.value[e_value.CAM_GRAIN]) && !render_pass
		render_camera_vignette = (render_effects && render_camera.value[e_value.CAM_VIGNETTE]) && !render_pass
		render_camera_ca = (render_effects && render_camera.value[e_value.CAM_CA]) && !render_pass
		render_camera_distort = (render_effects && render_camera.value[e_value.CAM_DISTORT]) && !render_pass
		
		render_camera_lens_dirt = render_camera_lens_dirt && ((render_camera_bloom && render_camera.value[e_value.CAM_LENS_DIRT_BLOOM]) || (render_glow && render_camera.value[e_value.CAM_LENS_DIRT_GLOW])) && !render_pass
		render_camera_lens_dirt_bloom = render_camera_lens_dirt && render_camera.value[e_value.CAM_LENS_DIRT_BLOOM] && !render_pass
		render_camera_lens_dirt_glow = render_camera_lens_dirt && render_camera.value[e_value.CAM_LENS_DIRT_GLOW] && !render_pass
		
		render_camera_colors = (render_camera.value[e_value.ALPHA] < 1 || 
								render_camera.value[e_value.EMISSIVE] > 0 || 
								render_camera.value[e_value.MIX_COLOR] > 0 ||
								render_camera.value[e_value.RGB_ADD] != c_black ||
								render_camera.value[e_value.RGB_SUB] != c_black ||
								render_camera.value[e_value.RGB_MUL] != c_white ||
								render_camera.value[e_value.HSB_ADD] != c_black ||
								render_camera.value[e_value.HSB_SUB] != c_black ||
								render_camera.value[e_value.HSB_MUL] != c_red)
	}
	else 
	{
		render_camera_bloom = false
		render_camera_dof = false
		render_camera_color_correction = false
		render_camera_grain = false
		render_camera_vignette = false
		render_camera_ca = false
		render_camera_distort = false
		
		render_camera_lens_dirt = false
		render_camera_lens_dirt_bloom = false
		render_camera_lens_dirt_glow = false
		
		render_camera_colors = false
	}
	
	render_tonemapper = e_tonemapper.NONE
	render_exposure = 1
	render_gamma = 1
	
	// Argument overwrites size
	if (argument_count > 2)
	{
		render_width = argument[2]
		render_height = argument[3]
	}
	
	render_ratio = render_width / render_height
	render_overlay = (render_camera_colors || render_watermark)
	
	// Effects must be in the order they're done in rendering
	render_refresh_effects()
	
	// Update timeline visibility
	with (obj_timeline)
		render_visible = tl_get_visible()
	
	render_prev_color = draw_get_color()
	render_prev_alpha = draw_get_alpha()
	draw_set_color(c_white)
	draw_set_alpha(1)
	
	render_update_text()
	render_update_item()
	render_update_camera()
	
	camera_apply(cam_render)
}
