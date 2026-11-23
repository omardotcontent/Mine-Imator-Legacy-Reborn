/// action_tl_frame_cam_speed_lines_radius(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_speed_lines_radius(val, add)
{
	tl_value_set_start(action_tl_frame_cam_speed_lines_radius, true)
	tl_value_set(e_value.CAM_SPEED_LINES_RADIUS, val / 100, add)
	tl_value_set_done()
}
