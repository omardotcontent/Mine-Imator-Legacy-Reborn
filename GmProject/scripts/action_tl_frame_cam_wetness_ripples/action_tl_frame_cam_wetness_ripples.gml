/// action_tl_frame_cam_wetness_ripples(enable)
/// @arg enable

function action_tl_frame_cam_wetness_ripples(enable)
{
	tl_value_set_start(action_tl_frame_cam_wetness_ripples, false)
	tl_value_set(e_value.CAM_WETNESS_RIPPLES, enable, false)
	tl_value_set_done()
}
