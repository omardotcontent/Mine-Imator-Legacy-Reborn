/// action_tl_frame_cam_godrays(enable)
/// @arg enable

function action_tl_frame_cam_godrays(enable)
{
	tl_value_set_start(action_tl_frame_cam_godrays, false)
	tl_value_set(e_value.CAM_GODRAYS, enable, false)
	tl_value_set_done()
}
