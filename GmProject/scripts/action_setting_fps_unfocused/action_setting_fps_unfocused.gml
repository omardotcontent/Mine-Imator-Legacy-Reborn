/// action_setting_fps_unfocused(value, add)
/// @arg value
/// @arg add

function action_setting_fps_unfocused(val, add)
{
	setting_fps_unfocused = setting_fps_unfocused * add + val
	setting_fps_unfocused = clamp(round(setting_fps_unfocused), 5, 60)
}
