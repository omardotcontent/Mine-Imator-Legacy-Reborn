/// action_project_render_rim_power(value, add)
/// @arg value
/// @arg add

function action_project_render_rim_power(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_rim_power, project_render_rim_power, project_render_rim_power * add + val, 1)
	
	project_render_rim_power = project_render_rim_power * add + val
	render_samples = -1
}
