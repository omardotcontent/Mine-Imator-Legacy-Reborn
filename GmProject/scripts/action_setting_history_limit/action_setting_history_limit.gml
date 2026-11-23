/// action_setting_history_limit(value, add)
/// @arg value
/// @arg add

function action_setting_history_limit(val, add)
{
	setting_history_limit = setting_history_limit * add + val
	setting_history_limit = clamp(round(setting_history_limit), 10, 500)
}
