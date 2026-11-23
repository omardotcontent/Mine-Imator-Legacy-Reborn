/// shader_high_ssr_set()

function shader_high_ssr_set()
{
	texture_set_stage(sampler_map[?"uDepthBuffer"], surface_get_texture(render_surface_gbuf_depth))
	texture_set_stage(sampler_map[?"uNormalBuffer"], surface_get_texture(render_surface_gbuf_normal))
	texture_set_stage(sampler_map[?"uMaterialBuffer"], surface_get_texture(render_surface_gbuf_mat))
	gpu_set_texrepeat_ext(sampler_map[?"uDepthBuffer"], false)
	gpu_set_texrepeat_ext(sampler_map[?"uNormalBuffer"], false)
	gpu_set_texrepeat_ext(sampler_map[?"uMaterialBuffer"], false)
	
	render_set_uniform("uNear", render_gbuf_near)
	render_set_uniform("uFar", render_gbuf_far)
	render_set_uniform("uProjMatrix", render_gbuf_proj_matrix)
	render_set_uniform("uProjMatrixInv", matrix_inverse(render_gbuf_proj_matrix))
	
	if (render_camera != null && render_effects && render_camera.value[e_value.CAM_SSR])
	{
		render_set_uniform_int("uSteps", render_camera.value[e_value.CAM_SSR_STEPS])
		render_set_uniform("uMaxDist", render_camera.value[e_value.CAM_SSR_MAX_DIST])
		render_set_uniform("uThickness", render_camera.value[e_value.CAM_SSR_THICKNESS])
		render_set_uniform("uStrength", render_camera.value[e_value.CAM_SSR_STRENGTH])
		render_set_uniform("uFresnel", render_camera.value[e_value.CAM_SSR_FRESNEL])
		render_set_uniform_int("uWaterOnly", render_camera.value[e_value.CAM_SSR_WATER_ONLY])
	}
	else
	{
		render_set_uniform_int("uSteps", app.project_render_ssr_steps)
		render_set_uniform("uMaxDist", app.project_render_ssr_max_dist)
		render_set_uniform("uThickness", app.project_render_ssr_thickness)
		render_set_uniform("uStrength", app.project_render_ssr_strength)
		render_set_uniform("uFresnel", app.project_render_ssr_fresnel)
		render_set_uniform_int("uWaterOnly", app.project_render_ssr_water_only)
	}
	render_set_uniform_color("uSkyColor", app.background_sky_color_final, 1)
	render_set_uniform_color("uHorizonColor", app.background_fog_color_final, 1)
}
