/// render_high_scene(ssaosurf, shadowsurf)
/// @arg ssaosurf
/// @arg shadowsurf
/// @desc Classic 1.2.9 scene composite (diffuse + SSAO + shadows + glint)

function render_high_scene(ssaosurf, shadowsurf)
{
	var resultsurf, glintsurf;
	
	render_surface[3] = surface_require(render_surface[3], render_width, render_height)
	resultsurf = render_surface[3]
	
	// Render glint overlay (2.0.2 feature preserved on 1.2.9 renderer)
	render_surface[4] = surface_require(render_surface[4], render_width, render_height)
	glintsurf = render_surface[4]
	surface_set_target(glintsurf)
	{
		draw_clear(c_black)
		render_world_start()
		render_world(e_render_mode.GLINT)
		render_world_done()
		
		render_set_projection_ortho(0, 0, render_width, render_height, 0)
		gpu_set_blendmode_ext(bm_src_color, bm_one)
		draw_box(0, 0, render_width, render_height, false, c_black, 1)
		gpu_set_blendmode(bm_normal)
	}
	surface_reset_target()
	
	surface_set_target(resultsurf)
	{
		// Background
		draw_clear_alpha(c_black, 0)
		render_world_background()
		
		// World
		render_world_start()
		render_world_sky()
		render_world(e_render_mode.COLOR_FOG)
		render_world_done()
		
		// 2D mode
		render_set_projection_ortho(0, 0, render_width, render_height, 0)
		
		// Multiply by SSAO
		gpu_set_blendmode_ext(bm_zero, bm_src_color)
		if (render_ssao && surface_exists(ssaosurf))
		{
			var sw = surface_get_width(ssaosurf);
			var sh = surface_get_height(ssaosurf);
			if (sw != render_width || sh != render_height)
			{
				gpu_set_texfilter(true)
				draw_surface_ext(ssaosurf, 0, 0, render_width / max(1, sw), render_height / max(1, sh), 0, c_white, 1)
				gpu_set_texfilter(false)
			}
			else
				draw_surface_exists(ssaosurf, 0, 0)
		}
		
		// Multiply by shadows
		if (render_shadows)
		{
			render_shader_obj = shader_map[?shader_high_light_apply]
			with (render_shader_obj)
				shader_use()
			draw_surface_exists(shadowsurf, 0, 0)
			with (render_shader_obj)
				shader_clear()
		}
		
		// Add enchantment glint
		gpu_set_blendmode(bm_add)
		draw_surface_exists(glintsurf, 0, 0)
		
		// Alpha fix
		gpu_set_blendmode_ext(bm_src_color, bm_one)
		if (render_background)
			draw_box(0, 0, render_width, render_height, false, c_black, 1)
		else
		{
			render_world_start()
			render_world(e_render_mode.ALPHA_FIX)
			render_world_done()
		}
		gpu_set_blendmode(bm_normal)
	}
	surface_reset_target()
	
	if (render_pass = e_render_pass.DIFFUSE)
		render_pass_surf = surface_duplicate(resultsurf)
	else if (render_pass = e_render_pass.SPECULAR)
		render_pass_surf = surface_duplicate(glintsurf)
	
	return resultsurf
}
