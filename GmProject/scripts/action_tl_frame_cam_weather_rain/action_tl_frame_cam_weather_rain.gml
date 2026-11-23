/// action_tl_frame_cam_weather_rain(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_weather_rain(val, add)
{
	tl_value_set_start(action_tl_frame_cam_weather_rain, true)
	tl_value_set(e_value.CAM_WEATHER_RAIN, val / 100, add)
	tl_value_set_done()
}
