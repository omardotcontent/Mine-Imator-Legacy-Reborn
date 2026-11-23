/// action_tl_frame_cam_lensflare_ghosts(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_lensflare_ghosts(val, add)
{
	tl_value_set_start(action_tl_frame_cam_lensflare_ghosts, true)
	tl_value_set(e_value.CAM_LENSFLARE_GHOSTS, val / 100, add)
	tl_value_set_done()
}
