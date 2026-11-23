/// action_project_render_outline_dist_fade(value, add)
/// @arg value
/// @arg add

function action_project_render_outline_dist_fade(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_outline_dist_fade, project_render_outline_dist_fade, project_render_outline_dist_fade * add + val / 100, 1)
	else
		val *= 100
	
	project_render_outline_dist_fade = project_render_outline_dist_fade * add + val / 100
	render_samples = -1
}
