/// shader_high_contact_shadows_set()

function shader_high_contact_shadows_set()
{
	texture_set_stage(sampler_map[?"uDepthBuffer"], surface_get_texture(render_surface_gbuf_depth))
	texture_set_stage(sampler_map[?"uNormalBuffer"], surface_get_texture(render_surface_gbuf_normal))
	texture_set_stage(sampler_map[?"uMaterialBuffer"], surface_get_texture(render_surface_gbuf_mat))
	gpu_set_texrepeat_ext(sampler_map[?"uDepthBuffer"], false)
	gpu_set_texrepeat_ext(sampler_map[?"uNormalBuffer"], false)
	gpu_set_texrepeat_ext(sampler_map[?"uMaterialBuffer"], false)
	
	render_set_uniform("uNear", render_gbuf_near)
	render_set_uniform("uFar", render_gbuf_far)
	render_set_uniform("uProjMatrix", render_gbuf_proj_matrix)
	render_set_uniform("uProjMatrixInv", matrix_inverse(render_gbuf_proj_matrix))
	
	// Transform sun direction from world space into view space
	var vdir = vec4_mul_matrix(vec4(app.background_sun_direction[X], app.background_sun_direction[Y], app.background_sun_direction[Z], 0), render_gbuf_view_matrix);
	var sdir = vec3_normalize([vdir[X], vdir[Y], vdir[Z]]);
	render_set_uniform_vec3("uSunViewDir", sdir[X], sdir[Y], sdir[Z])
	
	if (render_camera != null && render_effects && render_camera.value[e_value.CAM_CONTACT_SHADOWS])
	{
		render_set_uniform_int("uSteps", render_camera.value[e_value.CAM_CONTACT_SHADOWS_STEPS])
		render_set_uniform("uLength", render_camera.value[e_value.CAM_CONTACT_SHADOWS_LENGTH])
		render_set_uniform("uThickness", render_camera.value[e_value.CAM_CONTACT_SHADOWS_THICKNESS])
		render_set_uniform("uStrength", render_camera.value[e_value.CAM_CONTACT_SHADOWS_STRENGTH])
	}
	else
	{
		render_set_uniform_int("uSteps", app.project_render_contact_shadows_steps)
		render_set_uniform("uLength", app.project_render_contact_shadows_length)
		render_set_uniform("uThickness", app.project_render_contact_shadows_thickness)
		render_set_uniform("uStrength", app.project_render_contact_shadows_strength)
	}
}
