/// action_setting_zoom_speed(value, add)
/// @arg value
/// @arg add

function action_setting_zoom_speed(val, add)
{
	setting_zoom_speed = setting_zoom_speed * add + val
	setting_zoom_speed = clamp(setting_zoom_speed, 0.1, 5.0)
}
