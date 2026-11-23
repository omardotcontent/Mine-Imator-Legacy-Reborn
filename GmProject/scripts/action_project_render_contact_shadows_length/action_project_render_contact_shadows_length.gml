/// action_project_render_contact_shadows_length(value, add)
/// @arg value
/// @arg add

function action_project_render_contact_shadows_length(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_contact_shadows_length, project_render_contact_shadows_length, project_render_contact_shadows_length * add + val, 1)
	
	project_render_contact_shadows_length = project_render_contact_shadows_length * add + val
	render_samples = -1
}
