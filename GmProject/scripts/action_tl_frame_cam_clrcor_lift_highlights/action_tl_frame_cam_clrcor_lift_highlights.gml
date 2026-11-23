/// action_tl_frame_cam_clrcor_lift_highlights(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_clrcor_lift_highlights(val, add)
{
	tl_value_set_start(action_tl_frame_cam_clrcor_lift_highlights, true)
	tl_value_set(e_value.CAM_LIFT_HIGHLIGHTS, val / 100, add)
	tl_value_set_done()
}
