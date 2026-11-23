/// action_tl_frame_cam_retro_curvature(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_retro_curvature(val, add)
{
	tl_value_set_start(action_tl_frame_cam_retro_curvature, true)
	tl_value_set(e_value.CAM_RETRO_CURVATURE, val / 100, add)
	tl_value_set_done()
}
