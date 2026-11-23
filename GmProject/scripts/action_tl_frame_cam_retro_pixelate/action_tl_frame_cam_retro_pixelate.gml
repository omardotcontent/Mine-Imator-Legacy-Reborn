/// action_tl_frame_cam_retro_pixelate(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_retro_pixelate(val, add)
{
	tl_value_set_start(action_tl_frame_cam_retro_pixelate, true)
	tl_value_set(e_value.CAM_RETRO_PIXELATE, val, add)
	tl_value_set_done()
}
