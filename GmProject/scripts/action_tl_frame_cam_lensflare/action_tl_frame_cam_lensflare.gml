/// action_tl_frame_cam_lensflare(enable)
/// @arg enable

function action_tl_frame_cam_lensflare(enable)
{
	tl_value_set_start(action_tl_frame_cam_lensflare, false)
	tl_value_set(e_value.CAM_LENSFLARE, enable, false)
	tl_value_set_done()
}
