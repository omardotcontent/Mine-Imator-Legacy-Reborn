/// action_tl_frame_cam_outline_normal_sens(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_outline_normal_sens(val, add)
{
	tl_value_set_start(action_tl_frame_cam_outline_normal_sens, true)
	tl_value_set(e_value.CAM_OUTLINE_NORMAL_SENS, val / 100, add)
	tl_value_set_done()
}
