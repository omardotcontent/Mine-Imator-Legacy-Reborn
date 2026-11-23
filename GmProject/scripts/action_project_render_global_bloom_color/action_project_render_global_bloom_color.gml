/// action_project_render_global_bloom_color(value)
/// @arg value

function action_project_render_global_bloom_color(val)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_global_bloom_color, project_render_global_bloom_color, val, 1)
	
	project_render_global_bloom_color = val
	render_samples = -1
}
