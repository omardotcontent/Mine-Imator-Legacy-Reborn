/// action_project_render_weather_lens_drops(value, add)
/// @arg value
/// @arg add

function action_project_render_weather_lens_drops(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_weather_lens_drops, project_render_weather_lens_drops, project_render_weather_lens_drops * add + val / 100, 1)
	else
		val *= 100
	
	project_render_weather_lens_drops = project_render_weather_lens_drops * add + val / 100
	render_samples = -1
}
