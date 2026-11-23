/// action_project_render_shadows_blur_quality(value, add)
/// @arg value
/// @arg add

function action_project_render_shadows_blur_quality(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_shadows_blur_quality, project_render_shadows_blur_quality, project_render_shadows_blur_quality * add + val, true)
	
	project_render_shadows_blur_quality = project_render_shadows_blur_quality * add + val
}
