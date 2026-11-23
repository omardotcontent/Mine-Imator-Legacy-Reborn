/// action_tl_frame_cam_retro(enable)
/// @arg enable

function action_tl_frame_cam_retro(enable)
{
	tl_value_set_start(action_tl_frame_cam_retro, false)
	tl_value_set(e_value.CAM_RETRO, enable, false)
	tl_value_set_done()
}
