/// action_tl_frame_cam_cel_steps(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_cel_steps(val, add)
{
	tl_value_set_start(action_tl_frame_cam_cel_steps, true)
	tl_value_set(e_value.CAM_CEL_STEPS, val, add)
	tl_value_set_done()
}
