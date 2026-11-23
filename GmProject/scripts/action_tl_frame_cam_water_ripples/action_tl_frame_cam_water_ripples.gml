/// action_tl_frame_cam_water_ripples(enable)
/// @arg enable

function action_tl_frame_cam_water_ripples(enable)
{
	tl_value_set_start(action_tl_frame_cam_water_ripples, false)
	tl_value_set(e_value.CAM_WATER_RIPPLES, enable, false)
	tl_value_set_done()
}
