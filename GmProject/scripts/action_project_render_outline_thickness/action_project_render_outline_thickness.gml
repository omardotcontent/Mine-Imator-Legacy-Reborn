/// action_project_render_outline_thickness(value, add)
/// @arg value
/// @arg add

function action_project_render_outline_thickness(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_outline_thickness, project_render_outline_thickness, project_render_outline_thickness * add + val, 1)
	
	project_render_outline_thickness = project_render_outline_thickness * add + val
	render_samples = -1
}
