/// action_project_render_lift_midtones(value, add)
/// @arg value
/// @arg add

function action_project_render_lift_midtones(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_lift_midtones, project_render_lift_midtones, project_render_lift_midtones * add + val / 100, 1)
	else
		val *= 100
	
	project_render_lift_midtones = project_render_lift_midtones * add + val / 100
	render_samples = -1
}
