/// action_project_render_volumetric_lights(value)
/// @arg value

function action_project_render_volumetric_lights(val)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_volumetric_lights, project_render_volumetric_lights, val, 1)
	
	project_render_volumetric_lights = val
	render_samples = -1
}
