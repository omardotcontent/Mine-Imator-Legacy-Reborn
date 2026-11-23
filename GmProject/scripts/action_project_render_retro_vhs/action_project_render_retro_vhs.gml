/// action_project_render_retro_vhs(value, add)
/// @arg value
/// @arg add

function action_project_render_retro_vhs(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_retro_vhs, project_render_retro_vhs, project_render_retro_vhs * add + val / 100, 1)
	else
		val *= 100
	
	project_render_retro_vhs = project_render_retro_vhs * add + val / 100
	render_samples = -1
}
