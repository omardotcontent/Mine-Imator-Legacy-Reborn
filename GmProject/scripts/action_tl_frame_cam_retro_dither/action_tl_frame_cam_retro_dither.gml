/// action_tl_frame_cam_retro_dither(enable)
/// @arg enable

function action_tl_frame_cam_retro_dither(enable)
{
	tl_value_set_start(action_tl_frame_cam_retro_dither, false)
	tl_value_set(e_value.CAM_RETRO_DITHER, enable, false)
	tl_value_set_done()
}
