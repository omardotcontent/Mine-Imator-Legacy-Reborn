/// action_project_render_glow_passes(value, add)
/// @arg value
/// @arg add

function action_project_render_glow_passes(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_glow_passes, project_render_glow_passes, project_render_glow_passes * add + val, 1)
	
	project_render_glow_passes = project_render_glow_passes * add + val
	render_samples = -1
}
