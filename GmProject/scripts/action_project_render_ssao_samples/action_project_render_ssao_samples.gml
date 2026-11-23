/// action_project_render_ssao_samples(value)
/// @arg value

function action_project_render_ssao_samples(val)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_ssao_samples, project_render_ssao_samples, val, 1)
	
	project_render_ssao_samples = val
	render_samples = -1
}
