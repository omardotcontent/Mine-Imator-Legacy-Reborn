/// action_project_render_ssao_ratio(value)
/// @arg value

function action_project_render_ssao_ratio(val)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_ssao_ratio, project_render_ssao_ratio, val, 1)
	
	project_render_ssao_ratio = val
	render_samples = -1
}
