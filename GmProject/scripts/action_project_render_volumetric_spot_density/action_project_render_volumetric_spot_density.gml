/// action_project_render_volumetric_spot_density(value, add)
/// @arg value
/// @arg add

function action_project_render_volumetric_spot_density(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_volumetric_spot_density, project_render_volumetric_spot_density, project_render_volumetric_spot_density * add + val / 100, 1)
	else
		val *= 100
	
	project_render_volumetric_spot_density = project_render_volumetric_spot_density * add + val / 100
	render_samples = -1
}
