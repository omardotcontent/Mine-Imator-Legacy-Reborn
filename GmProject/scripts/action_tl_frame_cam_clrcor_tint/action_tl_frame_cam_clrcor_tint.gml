/// action_tl_frame_cam_clrcor_tint(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_clrcor_tint(val, add)
{
	tl_value_set_start(action_tl_frame_cam_clrcor_tint, true)
	tl_value_set(e_value.CAM_TINT, val / 100, add)
	tl_value_set_done()
}
