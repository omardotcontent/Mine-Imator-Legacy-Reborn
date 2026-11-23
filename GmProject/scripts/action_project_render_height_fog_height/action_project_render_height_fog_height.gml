/// action_project_render_height_fog_height(value, add)
/// @arg value
/// @arg add

function action_project_render_height_fog_height(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_height_fog_height, project_render_height_fog_height, project_render_height_fog_height * add + val, 1)
	
	project_render_height_fog_height = project_render_height_fog_height * add + val
	render_samples = -1
}
