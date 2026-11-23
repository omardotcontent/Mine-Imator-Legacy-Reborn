/// action_tl_frame_cam_weather_lens_drops(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_weather_lens_drops(val, add)
{
	tl_value_set_start(action_tl_frame_cam_weather_lens_drops, true)
	tl_value_set(e_value.CAM_WEATHER_LENS_DROPS, val / 100, add)
	tl_value_set_done()
}
