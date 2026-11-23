/// action_tl_frame_cam_weather_snow(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_weather_snow(val, add)
{
	tl_value_set_start(action_tl_frame_cam_weather_snow, true)
	tl_value_set(e_value.CAM_WEATHER_SNOW, val / 100, add)
	tl_value_set_done()
}
