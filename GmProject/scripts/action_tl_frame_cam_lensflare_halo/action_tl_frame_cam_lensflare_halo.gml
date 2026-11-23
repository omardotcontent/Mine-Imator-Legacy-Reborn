/// action_tl_frame_cam_lensflare_halo(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_lensflare_halo(val, add)
{
	tl_value_set_start(action_tl_frame_cam_lensflare_halo, true)
	tl_value_set(e_value.CAM_LENSFLARE_HALO, val / 100, add)
	tl_value_set_done()
}
