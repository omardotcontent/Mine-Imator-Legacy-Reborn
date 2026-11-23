/// action_tl_frame_cam_godrays_exposure(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_godrays_exposure(val, add)
{
	tl_value_set_start(action_tl_frame_cam_godrays_exposure, true)
	tl_value_set(e_value.CAM_GODRAYS_EXPOSURE, val / 100, add)
	tl_value_set_done()
}
