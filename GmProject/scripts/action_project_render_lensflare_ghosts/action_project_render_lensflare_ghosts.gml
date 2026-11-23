/// action_project_render_lensflare_ghosts(value, add)
/// @arg value
/// @arg add

function action_project_render_lensflare_ghosts(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_lensflare_ghosts, project_render_lensflare_ghosts, project_render_lensflare_ghosts * add + val / 100, 1)
	else
		val *= 100
	
	project_render_lensflare_ghosts = project_render_lensflare_ghosts * add + val / 100
	render_samples = -1
}
