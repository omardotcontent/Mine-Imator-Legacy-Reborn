/// action_project_render_lift_highlights(value, add)
/// @arg value
/// @arg add

function action_project_render_lift_highlights(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_lift_highlights, project_render_lift_highlights, project_render_lift_highlights * add + val / 100, 1)
	else
		val *= 100
	
	project_render_lift_highlights = project_render_lift_highlights * add + val / 100
	render_samples = -1
}
