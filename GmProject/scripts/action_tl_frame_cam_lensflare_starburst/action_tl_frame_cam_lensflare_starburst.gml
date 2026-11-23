/// action_tl_frame_cam_lensflare_starburst(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_lensflare_starburst(val, add)
{
	tl_value_set_start(action_tl_frame_cam_lensflare_starburst, true)
	tl_value_set(e_value.CAM_LENSFLARE_STARBURST, val / 100, add)
	tl_value_set_done()
}
