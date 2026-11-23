/// action_tl_frame_cam_speed_lines(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_speed_lines(val, add)
{
	tl_value_set_start(action_tl_frame_cam_speed_lines, true)
	tl_value_set(e_value.CAM_SPEED_LINES, val / 100, add)
	tl_value_set_done()
}
