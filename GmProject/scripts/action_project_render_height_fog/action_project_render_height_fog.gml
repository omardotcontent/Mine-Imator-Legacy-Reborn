/// action_project_render_height_fog(value)
/// @arg value

function action_project_render_height_fog(val)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_height_fog, project_render_height_fog, val, 1)
	
	project_render_height_fog = val
	render_samples = -1
}
