/// shader_high_godrays_set(occsurf, sunu, sunv, visibility)
/// @arg occsurf
/// @arg sunu
/// @arg sunv
/// @arg visibility

function shader_high_godrays_set(occsurf, sunu, sunv, visibility)
{
	texture_set_stage(sampler_map[?"uOcclusionMask"], surface_get_texture(occsurf))
	gpu_set_texfilter_ext(sampler_map[?"uOcclusionMask"], true)
	gpu_set_texrepeat_ext(sampler_map[?"uOcclusionMask"], false)
	
	render_set_uniform_vec2("uSunScreenPos", sunu, sunv)
	render_set_uniform("uSunVisibility", visibility)
	
	if (render_camera != null && render_effects && render_camera.value[e_value.CAM_GODRAYS])
	{
		render_set_uniform_color("uSunColor", render_camera.value[e_value.CAM_GODRAYS_COLOR], 1)
		render_set_uniform_int("uSamples", render_camera.value[e_value.CAM_GODRAYS_SAMPLES])
		render_set_uniform("uDensity", render_camera.value[e_value.CAM_GODRAYS_DENSITY])
		render_set_uniform("uDecay", render_camera.value[e_value.CAM_GODRAYS_DECAY])
		render_set_uniform("uWeight", render_camera.value[e_value.CAM_GODRAYS_WEIGHT])
		render_set_uniform("uExposure", render_camera.value[e_value.CAM_GODRAYS_EXPOSURE])
	}
	else
	{
		render_set_uniform_color("uSunColor", app.project_render_godrays_color, 1)
		render_set_uniform_int("uSamples", app.project_render_godrays_samples)
		render_set_uniform("uDensity", app.project_render_godrays_density)
		render_set_uniform("uDecay", app.project_render_godrays_decay)
		render_set_uniform("uWeight", app.project_render_godrays_weight)
		render_set_uniform("uExposure", app.project_render_godrays_exposure)
	}
}
