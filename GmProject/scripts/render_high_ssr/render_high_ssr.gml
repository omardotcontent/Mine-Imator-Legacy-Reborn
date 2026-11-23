/// render_high_ssr(prevsurf)
/// @arg prevsurf

function render_high_ssr(prevsurf)
{
	if (!surface_exists(render_surface_gbuf_depth) || !surface_exists(render_surface_gbuf_normal) || !surface_exists(render_surface_gbuf_mat))
		return prevsurf
	
	var ratio = clamp(project_render_ssr_ratio, 0.25, 1.0);
	var sw = max(1, round(render_width * ratio));
	var sh = max(1, round(render_height * ratio));
	
	render_surface[0] = surface_require(render_surface[0], sw, sh)
	var ssr_surf = render_surface[0];
	
	surface_set_target(ssr_surf)
	{
		draw_clear_alpha(c_black, 0)
		render_set_projection_ortho(0, 0, sw, sh, 0)
		gpu_set_blendmode_ext(bm_one, bm_zero)
		gpu_set_texrepeat(false)
		gpu_set_texfilter(true)
		render_shader_obj = shader_map[?shader_high_ssr]
		with (render_shader_obj)
		{
			shader_set(shader)
			shader_high_ssr_set()
		}
		draw_surface_ext(prevsurf, 0, 0, sw / max(1, render_width), sh / max(1, render_height), 0, c_white, 1)
		with (render_shader_obj)
			shader_clear()
		gpu_set_texfilter(false)
		gpu_set_texrepeat(true)
		gpu_set_blendmode(bm_normal)
	}
	surface_reset_target()
	
	var resultsurf = render_high_get_apply_surf();
	surface_set_target(resultsurf)
	{
		draw_clear_alpha(c_black, 0)
		render_set_projection_ortho(0, 0, render_width, render_height, 0)
		gpu_set_blendmode_ext(bm_one, bm_zero)
		draw_surface_exists(prevsurf, 0, 0)
		
		gpu_set_blendmode_ext_sepalpha(bm_src_alpha, bm_inv_src_alpha, bm_zero, bm_one)
		gpu_set_texfilter(sw != render_width || sh != render_height)
		draw_surface_ext(ssr_surf, 0, 0, render_width / max(1, sw), render_height / max(1, sh), 0, c_white, 1)
		gpu_set_texfilter(false)
		gpu_set_blendmode(bm_normal)
	}
	surface_reset_target()
	return resultsurf
}
