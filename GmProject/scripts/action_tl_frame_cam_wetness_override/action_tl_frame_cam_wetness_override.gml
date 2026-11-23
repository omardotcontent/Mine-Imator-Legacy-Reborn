/// action_tl_frame_cam_wetness_override(enable)
/// @arg enable

function action_tl_frame_cam_wetness_override(enable)
{
	tl_value_set_start(action_tl_frame_cam_wetness_override, false)
	tl_value_set(e_value.CAM_WETNESS_OVERRIDE, enable, false)
	tl_value_set_done()
}
