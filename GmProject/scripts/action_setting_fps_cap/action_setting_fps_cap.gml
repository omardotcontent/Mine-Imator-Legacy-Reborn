/// action_setting_fps_cap(value, add)
/// @arg value
/// @arg add

function action_setting_fps_cap(val, add)
{
	setting_fps_cap = setting_fps_cap * add + val
	setting_fps_cap = clamp(round(setting_fps_cap), 15, 360)
	if (!setting_fps_unlimited)
		room_speed = setting_fps_cap
}
