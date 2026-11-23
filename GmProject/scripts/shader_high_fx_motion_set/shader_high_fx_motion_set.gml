/// shader_high_fx_motion_set()

function shader_high_fx_motion_set()
{
	if (surface_exists(render_surface_gbuf_depth))
	{
		texture_set_stage(sampler_map[?"uDepthBuffer"], surface_get_texture(render_surface_gbuf_depth))
		gpu_set_texrepeat_ext(sampler_map[?"uDepthBuffer"], false)
	}
	
	render_set_uniform("uNear", render_gbuf_near)
	render_set_uniform("uFar", render_gbuf_far)
	render_set_uniform("uProjMatrixInv", matrix_inverse(render_gbuf_proj_matrix))
	render_set_uniform("uViewInvMatrix", matrix_inverse(render_gbuf_view_matrix))
	if (render_has_prev_view_proj)
		render_set_uniform("uPrevViewProjMatrix", render_prev_view_proj_matrix)
	else
		render_set_uniform("uPrevViewProjMatrix", view_proj_matrix)
	
	render_set_uniform("uTime", app.background_time / 60 + (current_time / 1000))
	
	if (render_camera != null && render_effects && render_camera.value[e_value.CAM_MOTION_FX])
	{
		render_set_uniform("uMotionBlur", render_camera.value[e_value.CAM_MOTION_BLUR])
		render_set_uniform("uRadialBlur", render_camera.value[e_value.CAM_RADIAL_BLUR])
		render_set_uniform("uSpeedLines", render_camera.value[e_value.CAM_SPEED_LINES])
		render_set_uniform("uSpeedLinesRadius", render_camera.value[e_value.CAM_SPEED_LINES_RADIUS])
		render_set_uniform_color("uSpeedLinesColor", render_camera.value[e_value.CAM_SPEED_LINES_COLOR], 1)
	}
	else
	{
		render_set_uniform("uMotionBlur", app.project_render_motion_blur)
		render_set_uniform("uRadialBlur", app.project_render_radial_blur)
		render_set_uniform("uSpeedLines", app.project_render_speed_lines)
		render_set_uniform("uSpeedLinesRadius", app.project_render_speed_lines_radius)
		render_set_uniform_color("uSpeedLinesColor", app.project_render_speed_lines_color, 1)
	}
}
