/// action_tl_frame_cam_cel_smoothness(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_cel_smoothness(val, add)
{
	tl_value_set_start(action_tl_frame_cam_cel_smoothness, true)
	tl_value_set(e_value.CAM_CEL_SMOOTHNESS, val / 100, add)
	tl_value_set_done()
}
