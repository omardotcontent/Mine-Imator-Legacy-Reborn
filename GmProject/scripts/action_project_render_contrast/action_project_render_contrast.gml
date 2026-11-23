/// action_project_render_contrast(value, add)
/// @arg value
/// @arg add

function action_project_render_contrast(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_contrast, project_render_contrast, project_render_contrast * add + val / 100, 1)
	else
		val *= 100
	
	project_render_contrast = project_render_contrast * add + val / 100
	render_samples = -1
}
