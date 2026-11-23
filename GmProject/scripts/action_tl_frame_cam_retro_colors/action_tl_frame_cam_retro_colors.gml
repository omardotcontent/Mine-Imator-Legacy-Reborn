/// action_tl_frame_cam_retro_colors(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_retro_colors(val, add)
{
	tl_value_set_start(action_tl_frame_cam_retro_colors, true)
	tl_value_set(e_value.CAM_RETRO_COLORS, val, add)
	tl_value_set_done()
}
