/// action_project_render_fog_scatter_color(value)
/// @arg value

function action_project_render_fog_scatter_color(val)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_fog_scatter_color, project_render_fog_scatter_color, val, 1)
	
	project_render_fog_scatter_color = val
	render_samples = -1
}
