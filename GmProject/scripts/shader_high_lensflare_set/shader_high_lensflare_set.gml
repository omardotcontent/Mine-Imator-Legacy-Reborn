/// shader_high_lensflare_set(occsurf, sunu, sunv, visibility)
/// @arg occsurf
/// @arg sunu
/// @arg sunv
/// @arg visibility

function shader_high_lensflare_set(occsurf, sunu, sunv, visibility)
{
	texture_set_stage(sampler_map[?"uOcclusionMask"], surface_get_texture(occsurf))
	gpu_set_texfilter_ext(sampler_map[?"uOcclusionMask"], true)
	gpu_set_texrepeat_ext(sampler_map[?"uOcclusionMask"], false)
	
	render_set_uniform_vec2("uSunScreenPos", sunu, sunv)
	render_set_uniform_vec2("uScreenSize", render_width, render_height)
	render_set_uniform("uVisibility", visibility)
	
	if (render_camera != null && render_effects && render_camera.value[e_value.CAM_LENSFLARE])
	{
		render_set_uniform_color("uColor", render_camera.value[e_value.CAM_LENSFLARE_COLOR], 1)
		render_set_uniform("uIntensity", render_camera.value[e_value.CAM_LENSFLARE_INTENSITY])
		render_set_uniform("uGhosts", render_camera.value[e_value.CAM_LENSFLARE_GHOSTS])
		render_set_uniform("uHalo", render_camera.value[e_value.CAM_LENSFLARE_HALO])
		render_set_uniform("uStarburst", render_camera.value[e_value.CAM_LENSFLARE_STARBURST])
	}
	else
	{
		render_set_uniform_color("uColor", app.project_render_lensflare_color, 1)
		render_set_uniform("uIntensity", app.project_render_lensflare_intensity)
		render_set_uniform("uGhosts", app.project_render_lensflare_ghosts)
		render_set_uniform("uHalo", app.project_render_lensflare_halo)
		render_set_uniform("uStarburst", app.project_render_lensflare_starburst)
	}
}
