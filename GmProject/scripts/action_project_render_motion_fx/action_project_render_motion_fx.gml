/// action_project_render_motion_fx(value)
/// @arg value

function action_project_render_motion_fx(val)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_motion_fx, project_render_motion_fx, val, 1)
	
	project_render_motion_fx = val
	render_samples = -1
}
