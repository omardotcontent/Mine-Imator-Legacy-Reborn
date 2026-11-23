/// action_tl_frame_cam_wetness(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_wetness(val, add)
{
	tl_value_set_start(action_tl_frame_cam_wetness, true)
	tl_value_set(e_value.CAM_WETNESS, val / 100, add)
	tl_value_set_done()
}
