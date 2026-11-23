/// action_project_render_water_ripples(value)
/// @arg value

function action_project_render_water_ripples(val)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_water_ripples, project_render_water_ripples, val, 1)
	
	project_render_water_ripples = val
	render_samples = -1
}
