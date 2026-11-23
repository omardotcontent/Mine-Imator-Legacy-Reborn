/// action_project_render_retro_pixelate(value, add)
/// @arg value
/// @arg add

function action_project_render_retro_pixelate(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_retro_pixelate, project_render_retro_pixelate, project_render_retro_pixelate * add + val, 1)
	
	project_render_retro_pixelate = project_render_retro_pixelate * add + val
	render_samples = -1
}
