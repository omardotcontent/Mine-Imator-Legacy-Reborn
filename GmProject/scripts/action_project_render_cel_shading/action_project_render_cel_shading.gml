/// action_project_render_cel_shading(value)
/// @arg value

function action_project_render_cel_shading(val)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_cel_shading, project_render_cel_shading, val, 1)
	
	project_render_cel_shading = val
	render_samples = -1
}
