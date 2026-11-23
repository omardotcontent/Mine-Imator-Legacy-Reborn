/// render_high_ssao()
/// @desc Enhanced 1.2.9 SSAO with selectable 16/32/64 samples, resolution scale, bias & bilateral blur

function render_high_ssao()
{
	var depthsurf, normalsurf, brightnesssurf, resultsurf;
	var ssaow, ssaoh;
	
	// Reuse shared 3-MRT G-buffer rendered in render_high_gbuffer()
	if (!surface_exists(render_surface_gbuf_depth) || !surface_exists(render_surface_gbuf_normal) || !surface_exists(render_surface_gbuf_mat))
		render_high_gbuffer()
	
	depthsurf = render_surface_gbuf_depth
	normalsurf = render_surface_gbuf_normal
	brightnesssurf = render_surface_gbuf_mat
	ssaow = surface_get_width(depthsurf)
	ssaoh = surface_get_height(depthsurf)
	
	// Noise texture (4x4 normalized random vectors)
	if (!surface_exists(render_ssao_noise))
		render_ssao_noise = render_generate_noise(4, 4, null, true)
	
	// Calculate SSAO
	render_surface[0] = surface_require(render_surface[0], ssaow, ssaoh)
	resultsurf = render_surface[0]
	surface_set_target(resultsurf)
	{
		gpu_set_texrepeat(false)
		draw_clear(c_white)
		render_shader_obj = shader_map[?shader_high_ssao]
		with (render_shader_obj)
		{
			shader_set(shader)
			shader_high_ssao_set(depthsurf, normalsurf, brightnesssurf, ssaow, ssaoh)
		}
		draw_blank(0, 0, ssaow, ssaoh)
		with (render_shader_obj)
			shader_clear()
		gpu_set_texrepeat(true)
	}
	surface_reset_target()
	
	// Bilateral blur passes
	repeat (project_render_ssao_blur_passes)
	{
		var ssaosurftemp;
		render_surface[3] = surface_require(render_surface[3], ssaow, ssaoh)
		ssaosurftemp = render_surface[3]
		
		render_shader_obj = shader_map[?shader_high_ssao_blur]
		with (render_shader_obj)
			shader_set(shader)
		
		// Horizontal
		surface_set_target(ssaosurftemp)
		{
			with (render_shader_obj)
				shader_high_ssao_blur_set(depthsurf, normalsurf, 1, 0, ssaow, ssaoh)
			draw_surface_exists(resultsurf, 0, 0)
		}
		surface_reset_target()
		
		// Vertical
		surface_set_target(resultsurf)
		{
			with (render_shader_obj)
				shader_high_ssao_blur_set(depthsurf, normalsurf, 0, 1, ssaow, ssaoh)
			draw_surface_exists(ssaosurftemp, 0, 0)
		}
		surface_reset_target()
		
		with (render_shader_obj)
			shader_clear()
	}
	gpu_set_texrepeat(true)
	
	if (render_pass = e_render_pass.AO)
		render_pass_surf = surface_duplicate(resultsurf)
	else if (render_pass = e_render_pass.DEPTH_U24)
		render_pass_surf = surface_duplicate(depthsurf)
	else if (render_pass = e_render_pass.NORMAL)
		render_pass_surf = surface_duplicate(normalsurf)
	
	return resultsurf
}
