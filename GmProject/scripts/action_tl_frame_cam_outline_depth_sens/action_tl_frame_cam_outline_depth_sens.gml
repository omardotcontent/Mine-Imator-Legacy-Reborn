/// action_tl_frame_cam_outline_depth_sens(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_outline_depth_sens(val, add)
{
	tl_value_set_start(action_tl_frame_cam_outline_depth_sens, true)
	tl_value_set(e_value.CAM_OUTLINE_DEPTH_SENS, val / 100, add)
	tl_value_set_done()
}
