/// action_tl_frame_cam_godrays_decay(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_godrays_decay(val, add)
{
	tl_value_set_start(action_tl_frame_cam_godrays_decay, true)
	tl_value_set(e_value.CAM_GODRAYS_DECAY, val / 100, add)
	tl_value_set_done()
}
