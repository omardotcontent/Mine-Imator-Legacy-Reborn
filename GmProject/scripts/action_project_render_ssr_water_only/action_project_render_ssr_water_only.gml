/// action_project_render_ssr_water_only(value)
/// @arg value

function action_project_render_ssr_water_only(val)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_ssr_water_only, project_render_ssr_water_only, val, 1)
	
	project_render_ssr_water_only = val
	render_samples = -1
}
