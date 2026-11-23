/// action_project_render_retro(value)
/// @arg value

function action_project_render_retro(val)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_retro, project_render_retro, val, 1)
	
	project_render_retro = val
	render_samples = -1
}
