/// action_project_render_outline_opacity(value, add)
/// @arg value
/// @arg add

function action_project_render_outline_opacity(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_outline_opacity, project_render_outline_opacity, project_render_outline_opacity * add + val / 100, 1)
	else
		val *= 100
	
	project_render_outline_opacity = project_render_outline_opacity * add + val / 100
	render_samples = -1
}
