/// action_tl_frame_cam_godrays_samples(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_godrays_samples(val, add)
{
	tl_value_set_start(action_tl_frame_cam_godrays_samples, true)
	tl_value_set(e_value.CAM_GODRAYS_SAMPLES, val, add)
	tl_value_set_done()
}
