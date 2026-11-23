/// shader_high_volumetric_lights_set(lcount, ldata)
/// @arg lcount
/// @arg ldata

function shader_high_volumetric_lights_set(lcount, ldata)
{
	texture_set_stage(sampler_map[?"uDepthBuffer"], surface_get_texture(render_surface_gbuf_depth))
	gpu_set_texrepeat_ext(sampler_map[?"uDepthBuffer"], false)
	
	render_set_uniform("uNear", render_gbuf_near)
	render_set_uniform("uFar", render_gbuf_far)
	render_set_uniform("uProjMatrixInv", matrix_inverse(render_gbuf_proj_matrix))
	
	render_set_uniform_int("uLightCount", lcount)
	render_set_uniform("uLightData", ldata)
	
	if (render_camera != null && render_effects && render_camera.value[e_value.CAM_VOLUMETRIC_LIGHTS])
	{
		render_set_uniform_int("uSteps", render_camera.value[e_value.CAM_VOLUMETRIC_STEPS])
		render_set_uniform("uIntensity", render_camera.value[e_value.CAM_VOLUMETRIC_INTENSITY])
		render_set_uniform("uSpotDensity", render_camera.value[e_value.CAM_VOLUMETRIC_SPOT_DENSITY])
		render_set_uniform("uPointRadius", render_camera.value[e_value.CAM_VOLUMETRIC_POINT_RADIUS])
	}
	else
	{
		render_set_uniform_int("uSteps", app.project_render_volumetric_steps)
		render_set_uniform("uIntensity", app.project_render_volumetric_intensity)
		render_set_uniform("uSpotDensity", app.project_render_volumetric_spot_density)
		render_set_uniform("uPointRadius", app.project_render_volumetric_point_radius)
	}
}
