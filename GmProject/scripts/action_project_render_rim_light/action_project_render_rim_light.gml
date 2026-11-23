/// action_project_render_rim_light(value)
/// @arg value

function action_project_render_rim_light(val)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_rim_light, project_render_rim_light, val, 1)
	
	project_render_rim_light = val
	render_samples = -1
}
