/// action_tl_frame_cam_clrcor_lift_shadows(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_clrcor_lift_shadows(val, add)
{
	tl_value_set_start(action_tl_frame_cam_clrcor_lift_shadows, true)
	tl_value_set(e_value.CAM_LIFT_SHADOWS, val / 100, add)
	tl_value_set_done()
}
