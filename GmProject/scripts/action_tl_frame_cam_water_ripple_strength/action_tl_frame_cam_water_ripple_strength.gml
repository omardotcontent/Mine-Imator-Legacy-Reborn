/// action_tl_frame_cam_water_ripple_strength(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_water_ripple_strength(val, add)
{
	tl_value_set_start(action_tl_frame_cam_water_ripple_strength, true)
	tl_value_set(e_value.CAM_WATER_RIPPLE_STRENGTH, val / 100, add)
	tl_value_set_done()
}
