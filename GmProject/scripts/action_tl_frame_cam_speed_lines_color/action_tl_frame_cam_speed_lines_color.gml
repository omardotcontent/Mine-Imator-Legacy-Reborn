/// action_tl_frame_cam_speed_lines_color(color)
/// @arg color

function action_tl_frame_cam_speed_lines_color(color)
{
	tl_value_set_start(action_tl_frame_cam_speed_lines_color, true)
	tl_value_set(e_value.CAM_SPEED_LINES_COLOR, color, false)
	tl_value_set_done()
}
