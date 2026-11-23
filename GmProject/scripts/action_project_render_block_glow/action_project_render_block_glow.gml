/// action_project_render_block_glow(enable)
/// @arg enable

function action_project_render_block_glow(enable)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_block_glow, project_render_block_glow, enable, true)
	
	project_render_block_glow = enable
}
