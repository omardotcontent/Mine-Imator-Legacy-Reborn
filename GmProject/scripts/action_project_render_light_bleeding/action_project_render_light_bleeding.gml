/// action_project_render_light_bleeding(enable)
/// @arg enable

function action_project_render_light_bleeding(enable)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_light_bleeding, project_render_light_bleeding, enable, true)
	
	project_render_light_bleeding = enable
}
