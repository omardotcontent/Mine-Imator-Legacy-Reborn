/// action_project_render_outline(value)
/// @arg value

function action_project_render_outline(val)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_outline, project_render_outline, val, 1)
	
	project_render_outline = val
	render_samples = -1
}
