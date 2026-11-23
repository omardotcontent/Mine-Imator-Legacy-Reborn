/// action_tl_frame_cam_retro_scanlines(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_retro_scanlines(val, add)
{
	tl_value_set_start(action_tl_frame_cam_retro_scanlines, true)
	tl_value_set(e_value.CAM_RETRO_SCANLINES, val / 100, add)
	tl_value_set_done()
}
