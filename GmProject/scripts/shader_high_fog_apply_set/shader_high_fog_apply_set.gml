/// shader_high_fog_apply_set(fogbuffer)
/// @arg fogbuffer

function shader_high_fog_apply_set(fogbuffer)
{
	texture_set_stage(sampler_map[?"uFogBuffer"], surface_get_texture(fogbuffer))
	render_set_uniform_color("uFogColor", app.background_fog_object_color_final, 1)
	render_set_uniform("uFogScatter", app.project_render_fog_scatter)
	render_set_uniform_color("uFogScatterColor", app.project_render_fog_scatter_color, 1)
	render_set_uniform_int("uHeightFogEnable", app.project_render_height_fog)
	render_set_uniform_color("uHeightFogColor", app.project_render_height_fog_color, 1)
}
