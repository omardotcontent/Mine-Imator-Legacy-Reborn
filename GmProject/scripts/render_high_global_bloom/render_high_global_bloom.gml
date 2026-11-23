/// render_high_global_bloom(prevsurf)
/// @arg prevsurf
/// @desc Global HDR-style multi-pass bloom (works on Work Camera too)

function render_high_global_bloom(prevsurf)
{
	var thresholdsurf, bloomsurf, bloomsurftemp, resultsurf, baseradius;
	render_surface[0] = surface_require(render_surface[0], render_width, render_height)
	render_surface[1] = surface_require(render_surface[1], render_width, render_height)
	render_surface[2] = surface_require(render_surface[2], render_width, render_height)
	thresholdsurf = render_surface[0]
	bloomsurf = render_surface[1]
	bloomsurftemp = render_surface[2]
	
	// Extract bright pixels above threshold
	surface_set_target(thresholdsurf)
	{
		draw_clear_alpha(c_black, 1)
		render_set_projection_ortho(0, 0, render_width, render_height, 0)
		render_shader_obj = shader_map[?shader_high_bloom_threshold]
		with (render_shader_obj)
		{
			shader_set(shader)
			render_set_uniform("uThreshold", app.project_render_global_bloom_threshold)
		}
		draw_surface_exists(prevsurf, 0, 0)
		with (render_shader_obj)
			shader_clear()
	}
	surface_reset_target()
	
	baseradius = ((project_render_global_bloom_radius * 12) * render_height / 500)
	gpu_set_tex_repeat(false)
	gpu_set_texfilter(true)
	
	render_shader_obj = shader_map[?shader_blur]
	with (render_shader_obj)
		shader_set(shader)
	
	for (var i = 0; i < 3; i++)
	{
		var r = baseradius / (1 + 1.333 * i);
		surface_set_target(bloomsurftemp)
		{
			with (render_shader_obj)
				shader_blur_set(render_blur_kernel, r, 1, 0)
			if (i = 0)
				draw_surface_exists(thresholdsurf, 0, 0)
			else
				draw_surface_exists(bloomsurf, 0, 0)
		}
		surface_reset_target()
		
		surface_set_target(bloomsurf)
		{
			with (render_shader_obj)
				shader_blur_set(render_blur_kernel, r, 0, 1)
			draw_surface_exists(bloomsurftemp, 0, 0)
		}
		surface_reset_target()
	}
	
	with (render_shader_obj)
		shader_clear()
	gpu_set_tex_repeat(true)
	gpu_set_texfilter(false)
	
	resultsurf = render_high_get_apply_surf()
	surface_set_target(resultsurf)
	{
		draw_clear_alpha(c_black, 0)
		render_shader_obj = shader_map[?shader_add]
		with (render_shader_obj)
		{
			shader_set(shader)
			shader_add_set(bloomsurf, app.project_render_global_bloom_intensity, app.project_render_global_bloom_color)
		}
		draw_surface_exists(prevsurf, 0, 0)
		with (render_shader_obj)
			shader_clear()
	}
	surface_reset_target()
	return resultsurf
}
