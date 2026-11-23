/// action_project_render_shadows_darkness(value, add)
/// @arg value
/// @arg add

function action_project_render_shadows_darkness(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_shadows_darkness, project_render_shadows_darkness, project_render_shadows_darkness * add + val / 100, 1)
	else
		val *= 100
	
	project_render_shadows_darkness = project_render_shadows_darkness * add + val / 100
	render_samples = -1
}
