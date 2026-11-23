/// action_tl_frame_cam_clrcor_lift_midtones(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_clrcor_lift_midtones(val, add)
{
	tl_value_set_start(action_tl_frame_cam_clrcor_lift_midtones, true)
	tl_value_set(e_value.CAM_LIFT_MIDTONES, val / 100, add)
	tl_value_set_done()
}
