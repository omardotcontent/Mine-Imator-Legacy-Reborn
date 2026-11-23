/// action_tl_frame_cam_clrcor_temperature(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_clrcor_temperature(val, add)
{
	tl_value_set_start(action_tl_frame_cam_clrcor_temperature, true)
	tl_value_set(e_value.CAM_TEMPERATURE, val / 100, add)
	tl_value_set_done()
}
