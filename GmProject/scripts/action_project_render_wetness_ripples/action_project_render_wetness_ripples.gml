/// action_project_render_wetness_ripples(value)
/// @arg value

function action_project_render_wetness_ripples(val)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_wetness_ripples, project_render_wetness_ripples, val, 1)
	
	project_render_wetness_ripples = val
	render_samples = -1
}
