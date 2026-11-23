/// action_project_render_outline_dist_fade_enable(value)
/// @arg value

function action_project_render_outline_dist_fade_enable(val)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_outline_dist_fade_enable, project_render_outline_dist_fade_enable, val, 1)
	
	project_render_outline_dist_fade_enable = val
	render_samples = -1
}
