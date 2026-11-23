/// action_tl_frame_cam_lensflare_intensity(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_lensflare_intensity(val, add)
{
	tl_value_set_start(action_tl_frame_cam_lensflare_intensity, true)
	tl_value_set(e_value.CAM_LENSFLARE_INTENSITY, val / 100, add)
	tl_value_set_done()
}
