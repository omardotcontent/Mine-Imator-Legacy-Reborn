/// action_project_render_godrays(value)
/// @arg value

function action_project_render_godrays(val)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_godrays, project_render_godrays, val, 1)
	
	project_render_godrays = val
	render_samples = -1
}
