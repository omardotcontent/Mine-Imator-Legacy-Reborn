/// action_project_render_specular(value)
/// @arg value

function action_project_render_specular(val)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_specular, project_render_specular, val, 1)
	
	project_render_specular = val
	render_samples = -1
}
