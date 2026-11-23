/// action_tl_frame_cam_godrays_density(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_godrays_density(val, add)
{
	tl_value_set_start(action_tl_frame_cam_godrays_density, true)
	tl_value_set(e_value.CAM_GODRAYS_DENSITY, val / 100, add)
	tl_value_set_done()
}
