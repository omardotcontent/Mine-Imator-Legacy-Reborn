/// render_high()
/// @desc Renders the scene in high quality using the enhanced classic 1.2.9 render engine (with SSAA supersampling).

function render_high()
{
	var starttime, finalsurf;
	var orig_w, orig_h, ssaa, maxsurf;
	
	starttime = current_time
	render_surface_time = 0
	render_alpha_hash = false
	render_sample_current = 0
	render_sun_occ_ready = false
	taa_matrix = MAT_IDENTITY
	
	// Internal Supersampling (SSAA) + Viewport Render Resolution Scale
	orig_w = render_width
	orig_h = render_height
	ssaa = project_render_ssaa
	if (render_view_current != null)
		ssaa *= setting_viewport_render_scale
	maxsurf = surface_get_max_size()
	
	if (ssaa != 1 && !render_pass)
	{
		render_width = clamp(round(orig_w * ssaa), 1, maxsurf)
		render_height = clamp(round(orig_h * ssaa), 1, maxsurf)
		render_ratio = render_width / max(1, render_height)
	}
	
	// Shared 3-MRT G-buffer (depth, view normal, material/SSAO/water/outline mask) rendered once per frame
	if (render_ssao || render_ssr || render_contact_shadows || render_outline || render_volumetric_lights || render_motion_fx)
		render_high_gbuffer()
	
	// SSAO
	if (render_ssao)
		render_surface_ssao = render_high_ssao()
	else
		render_surface_ssao = null
	
	// Shadows
	if (render_shadows)
		render_surface_shadows = render_high_shadows()
	else
		render_surface_shadows = null
	
	// Fog (distance fog and/or height mist)
	if (background_fog_show || project_render_height_fog)
		render_surface_fog = render_high_fog()
	else
		render_surface_fog = null
	
	// Composite current effects onto the scene
	finalsurf = render_high_scene(render_surface_ssao, render_surface_shadows)
	render_high_scene_post(finalsurf, render_surface_shadows, render_surface_fog)
	
	// Post processing (God-Rays, DOF, Bloom, Glow, FXAA, CA, Distort, Lens Dirt, CC, Grain, Vignette, Tone Map / CAS, Overlay)
	if (!render_pass)
	{
		render_refresh_effects(true, true)
		finalsurf = render_post(finalsurf, true, true)
	}
	
	// Restore output target size and downsample cleanly if SSAA was active
	var src_w = render_width;
	var src_h = render_height;
	render_width = orig_w
	render_height = orig_h
	render_ratio = render_width / max(1, render_height)
	
	render_target = surface_require(render_target, render_width, render_height)
	gpu_set_blendmode_ext(bm_one, bm_zero)
	gpu_set_texfilter(src_w != render_width || src_h != render_height)
	surface_set_target(render_target)
	{
		render_set_projection_ortho(0, 0, render_width, render_height, 0)
		if (render_pass && surface_exists(render_pass_surf))
		{
			draw_clear_alpha(c_black, 1)
			draw_surface_exists(render_pass_surf, 0, 0)
		}
		else
		{
			draw_clear_alpha(c_black, 0)
			if (surface_exists(finalsurf))
			{
				if (src_w != render_width || src_h != render_height)
					draw_surface_ext(finalsurf, 0, 0, render_width / max(1, src_w), render_height / max(1, src_h), 0, c_white, 1)
				else
					draw_surface_exists(finalsurf, 0, 0)
			}
		}
	}
	surface_reset_target()
	gpu_set_texfilter(false)
	gpu_set_blendmode(bm_normal)
	
	render_samples = 1
	render_samples_done = true
	render_samples_clear = false
	
	render_time = current_time - starttime - render_surface_time
}
