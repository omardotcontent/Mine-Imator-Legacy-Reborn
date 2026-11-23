/// render_high_outline(prevsurf)
/// @arg prevsurf

function render_high_outline(prevsurf)
{
	if (!surface_exists(render_surface_gbuf_depth) || !surface_exists(render_surface_gbuf_normal))
		return prevsurf
	
	var resultsurf = render_high_get_apply_surf();
	surface_set_target(resultsurf)
	{
		draw_clear_alpha(c_black, 0)
		render_set_projection_ortho(0, 0, render_width, render_height, 0)
		render_shader_obj = shader_map[?shader_high_outline]
		with (render_shader_obj)
		{
			shader_set(shader)
			shader_high_outline_set()
		}
		draw_surface_exists(prevsurf, 0, 0)
		with (render_shader_obj)
			shader_clear()
	}
	surface_reset_target()
	return resultsurf
}
