/// action_project_render_global_bloom(value)
/// @arg value

function action_project_render_global_bloom(val)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_global_bloom, project_render_global_bloom, val, 1)
	
	project_render_global_bloom = val
	render_samples = -1
}
