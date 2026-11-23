/// action_project_render_specular_shininess(value, add)
/// @arg value
/// @arg add

function action_project_render_specular_shininess(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_specular_shininess, project_render_specular_shininess, project_render_specular_shininess * add + val, 1)
	
	project_render_specular_shininess = project_render_specular_shininess * add + val
	render_samples = -1
}
