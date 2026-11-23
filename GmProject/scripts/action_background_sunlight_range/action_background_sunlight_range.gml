/// action_background_sunlight_range(value, add)
/// @arg value
/// @arg add

function action_background_sunlight_range(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_background_sunlight_range, background_sunlight_range, background_sunlight_range * add + val, true)
	
	background_sunlight_range = background_sunlight_range * add + val
}
