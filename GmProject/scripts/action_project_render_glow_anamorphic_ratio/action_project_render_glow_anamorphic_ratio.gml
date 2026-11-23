/// action_project_render_glow_anamorphic_ratio(value, add)
/// @arg value
/// @arg add

function action_project_render_glow_anamorphic_ratio(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_glow_anamorphic_ratio, project_render_glow_anamorphic_ratio, project_render_glow_anamorphic_ratio * add + val / 100, 1)
	else
		val *= 100
	
	project_render_glow_anamorphic_ratio = project_render_glow_anamorphic_ratio * add + val / 100
	render_samples = -1
}
