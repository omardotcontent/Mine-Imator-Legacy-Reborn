/// action_project_render_ssr_max_dist(value, add)
/// @arg value
/// @arg add

function action_project_render_ssr_max_dist(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_ssr_max_dist, project_render_ssr_max_dist, project_render_ssr_max_dist * add + val, 1)
	
	project_render_ssr_max_dist = project_render_ssr_max_dist * add + val
	render_samples = -1
}
