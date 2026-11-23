/// action_project_render_retro_colors(value, add)
/// @arg value
/// @arg add

function action_project_render_retro_colors(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_retro_colors, project_render_retro_colors, project_render_retro_colors * add + val, 1)
	
	project_render_retro_colors = project_render_retro_colors * add + val
	render_samples = -1
}
