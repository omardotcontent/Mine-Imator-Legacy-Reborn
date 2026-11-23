/// action_setting_fps_unlimited(value)
/// @arg value

function action_setting_fps_unlimited(val)
{
	setting_fps_unlimited = val
	room_speed = (setting_fps_unlimited ? 1000 : setting_fps_cap)
}
