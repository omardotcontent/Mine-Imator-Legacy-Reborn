/// action_project_render_ssr(value)
/// @arg value

function action_project_render_ssr(val)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_ssr, project_render_ssr, val, 1)
	
	project_render_ssr = val
	render_samples = -1
}
