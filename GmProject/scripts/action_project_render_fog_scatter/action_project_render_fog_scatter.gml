/// action_project_render_fog_scatter(value, add)
/// @arg value
/// @arg add

function action_project_render_fog_scatter(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_fog_scatter, project_render_fog_scatter, project_render_fog_scatter * add + val / 100, 1)
	else
		val *= 100
	
	project_render_fog_scatter = project_render_fog_scatter * add + val / 100
	render_samples = -1
}
