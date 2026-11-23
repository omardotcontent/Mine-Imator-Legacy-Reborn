/// action_project_render_retro_dither(value)
/// @arg value

function action_project_render_retro_dither(val)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_retro_dither, project_render_retro_dither, val, 1)
	
	project_render_retro_dither = val
	render_samples = -1
}
