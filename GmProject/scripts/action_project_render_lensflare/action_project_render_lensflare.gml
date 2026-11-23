/// action_project_render_lensflare(value)
/// @arg value

function action_project_render_lensflare(val)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_lensflare, project_render_lensflare, val, 1)
	
	project_render_lensflare = val
	render_samples = -1
}
