/// shader_high_outline_set()

function shader_high_outline_set()
{
	texture_set_stage(sampler_map[?"uDepthBuffer"], surface_get_texture(render_surface_gbuf_depth))
	texture_set_stage(sampler_map[?"uNormalBuffer"], surface_get_texture(render_surface_gbuf_normal))
	texture_set_stage(sampler_map[?"uMaterialBuffer"], surface_get_texture(render_surface_gbuf_mat))
	gpu_set_texrepeat_ext(sampler_map[?"uDepthBuffer"], false)
	gpu_set_texrepeat_ext(sampler_map[?"uNormalBuffer"], false)
	gpu_set_texrepeat_ext(sampler_map[?"uMaterialBuffer"], false)
	
	render_set_uniform_vec2("uScreenSize", render_width, render_height)
	
	if (render_camera != null && render_effects && render_camera.value[e_value.CAM_OUTLINE])
	{
		render_set_uniform("uThickness", render_camera.value[e_value.CAM_OUTLINE_THICKNESS])
		render_set_uniform("uDepthSens", render_camera.value[e_value.CAM_OUTLINE_DEPTH_SENS])
		render_set_uniform("uNormalSens", render_camera.value[e_value.CAM_OUTLINE_NORMAL_SENS])
		render_set_uniform("uOpacity", render_camera.value[e_value.CAM_OUTLINE_OPACITY])
		render_set_uniform_int("uDistFadeEnable", render_camera.value[e_value.CAM_OUTLINE_DIST_FADE_ENABLE])
		render_set_uniform("uDistFade", render_camera.value[e_value.CAM_OUTLINE_DIST_FADE])
		render_set_uniform_color("uColor", render_camera.value[e_value.CAM_OUTLINE_COLOR], 1)
	}
	else
	{
		render_set_uniform("uThickness", app.project_render_outline_thickness)
		render_set_uniform("uDepthSens", app.project_render_outline_depth_sens)
		render_set_uniform("uNormalSens", app.project_render_outline_normal_sens)
		render_set_uniform("uOpacity", app.project_render_outline_opacity)
		render_set_uniform_int("uDistFadeEnable", app.project_render_outline_dist_fade_enable)
		render_set_uniform("uDistFade", app.project_render_outline_dist_fade)
		render_set_uniform_color("uColor", app.project_render_outline_color, 1)
	}
}
