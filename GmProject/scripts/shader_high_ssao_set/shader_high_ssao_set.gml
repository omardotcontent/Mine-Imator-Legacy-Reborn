/// shader_high_ssao_set(depthsurface, normalsurface, brightnesssurf, wid, hei)
/// @arg depthsurface
/// @arg normalsurface
/// @arg brightnesssurf
/// @arg wid
/// @arg hei

function shader_high_ssao_set(depthsurface, normalsurface, brightnesssurf, wid, hei)
{
	texture_set_stage(sampler_map[?"uDepthBuffer"], surface_get_texture(depthsurface))
	texture_set_stage(sampler_map[?"uNormalBuffer"], surface_get_texture(normalsurface))
	texture_set_stage(sampler_map[?"uBrightnessBuffer"], surface_get_texture(brightnesssurf))
	texture_set_stage(sampler_map[?"uNoiseBuffer"], surface_get_texture(render_ssao_noise))
	gpu_set_texrepeat_ext(sampler_map[?"uDepthBuffer"], false)
	gpu_set_texrepeat_ext(sampler_map[?"uNormalBuffer"], false)
	gpu_set_texrepeat_ext(sampler_map[?"uBrightnessBuffer"], false)
	gpu_set_texrepeat_ext(sampler_map[?"uNoiseBuffer"], true)
	
	render_set_uniform("uNear", render_gbuf_near)
	render_set_uniform("uFar", render_gbuf_far)
	render_set_uniform("uProjMatrix", render_gbuf_proj_matrix)
	render_set_uniform("uProjMatrixInv", matrix_inverse(render_gbuf_proj_matrix))
	render_set_uniform_vec2("uScreenSize", wid, hei)
	
	var samples = app.project_render_ssao_samples;
	if (samples >= 64)
		render_set_uniform("uKernel", render_ssao_kernel_64)
	else if (samples >= 32)
		render_set_uniform("uKernel", render_ssao_kernel_32)
	else
		render_set_uniform("uKernel", render_ssao_kernel_16)
	
	render_set_uniform_int("uSamples", samples)
	render_set_uniform("uRadius", app.project_render_ssao_radius)
	render_set_uniform("uPower", app.project_render_ssao_power)
	render_set_uniform("uBias", app.project_render_ssao_bias)
	render_set_uniform_color("uColor", app.project_render_ssao_color, 1)
}
