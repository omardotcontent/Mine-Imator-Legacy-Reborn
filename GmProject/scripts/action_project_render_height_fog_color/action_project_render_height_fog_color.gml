/// action_project_render_height_fog_color(value)
/// @arg value

function action_project_render_height_fog_color(val)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_height_fog_color, project_render_height_fog_color, val, 1)
	
	project_render_height_fog_color = val
	render_samples = -1
}
