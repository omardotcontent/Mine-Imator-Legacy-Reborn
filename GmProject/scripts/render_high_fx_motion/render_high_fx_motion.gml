/// render_high_fx_motion(prevsurf)
/// @arg prevsurf

function render_high_fx_motion(prevsurf)
{
	var resultsurf = render_high_get_apply_surf();
	surface_set_target(resultsurf)
	{
		draw_clear_alpha(c_black, 0)
		render_set_projection_ortho(0, 0, render_width, render_height, 0)
		gpu_set_texrepeat(false)
		gpu_set_texfilter(true)
		render_shader_obj = shader_map[?shader_high_fx_motion]
		with (render_shader_obj)
		{
			shader_set(shader)
			shader_high_fx_motion_set()
		}
		draw_surface_exists(prevsurf, 0, 0)
		with (render_shader_obj)
			shader_clear()
		gpu_set_texfilter(false)
		gpu_set_texrepeat(true)
	}
	surface_reset_target()
	
	render_prev_view_proj_matrix = view_proj_matrix
	render_has_prev_view_proj = true
	return resultsurf
}
