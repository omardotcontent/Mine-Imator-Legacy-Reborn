/// action_project_render_shadows_tint(value)
/// @arg value

function action_project_render_shadows_tint(val)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_shadows_tint, project_render_shadows_tint, val, 1)
	
	project_render_shadows_tint = val
	render_samples = -1
}
