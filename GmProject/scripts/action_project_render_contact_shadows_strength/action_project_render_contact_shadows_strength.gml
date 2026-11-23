/// action_project_render_contact_shadows_strength(value, add)
/// @arg value
/// @arg add

function action_project_render_contact_shadows_strength(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_contact_shadows_strength, project_render_contact_shadows_strength, project_render_contact_shadows_strength * add + val / 100, 1)
	else
		val *= 100
	
	project_render_contact_shadows_strength = project_render_contact_shadows_strength * add + val / 100
	render_samples = -1
}
