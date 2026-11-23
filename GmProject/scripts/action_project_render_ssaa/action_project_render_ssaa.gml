/// action_project_render_ssaa(value)
/// @arg value

function action_project_render_ssaa(val)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_ssaa, project_render_ssaa, val, 1)
	
	project_render_ssaa = val
	render_samples = -1
}
