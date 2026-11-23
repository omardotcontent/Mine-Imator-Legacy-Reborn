/// render_high_tonemap(prevsurf)
/// @arg prevsurf
/// @desc Applies global tone mapping (Classic/ACES/Reinhard/AgX), color grading & CAS sharpening

function render_high_tonemap(prevsurf)
{
	var resultsurf = render_high_get_apply_surf();
	
	surface_set_target(resultsurf)
	{
		draw_clear_alpha(c_black, 0)
		render_shader_obj = shader_map[?shader_high_tonemap]
		with (render_shader_obj)
		{
			shader_set(shader)
			shader_high_tonemap_set()
		}
		draw_surface_exists(prevsurf, 0, 0)
		with (render_shader_obj)
			shader_clear()
	}
	surface_reset_target()
	
	return resultsurf
}
