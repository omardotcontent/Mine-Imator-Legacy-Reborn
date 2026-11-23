/// action_tl_frame_cam_weather_wind(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_weather_wind(val, add)
{
	tl_value_set_start(action_tl_frame_cam_weather_wind, true)
	tl_value_set(e_value.CAM_WEATHER_WIND, val / 100, add)
	tl_value_set_done()
}
