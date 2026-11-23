/// action_tl_frame_cam_motion_blur(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_motion_blur(val, add)
{
	tl_value_set_start(action_tl_frame_cam_motion_blur, true)
	tl_value_set(e_value.CAM_MOTION_BLUR, val / 100, add)
	tl_value_set_done()
}
