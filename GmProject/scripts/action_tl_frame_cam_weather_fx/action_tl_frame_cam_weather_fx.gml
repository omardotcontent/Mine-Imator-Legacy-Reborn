/// action_tl_frame_cam_weather_fx(enable)
/// @arg enable

function action_tl_frame_cam_weather_fx(enable)
{
	tl_value_set_start(action_tl_frame_cam_weather_fx, false)
	tl_value_set(e_value.CAM_WEATHER_FX, enable, false)
	tl_value_set_done()
}
