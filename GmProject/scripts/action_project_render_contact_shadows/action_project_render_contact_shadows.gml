/// action_project_render_contact_shadows(value)
/// @arg value

function action_project_render_contact_shadows(val)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_contact_shadows, project_render_contact_shadows, val, 1)
	
	project_render_contact_shadows = val
	render_samples = -1
}
