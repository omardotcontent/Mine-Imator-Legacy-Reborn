/// action_project_render_lensflare_halo(value, add)
/// @arg value
/// @arg add

function action_project_render_lensflare_halo(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_project_render_lensflare_halo, project_render_lensflare_halo, project_render_lensflare_halo * add + val / 100, 1)
	else
		val *= 100
	
	project_render_lensflare_halo = project_render_lensflare_halo * add + val / 100
	render_samples = -1
}
