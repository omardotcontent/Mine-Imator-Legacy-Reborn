/// action_background_desaturate_night_amount(value, add)
/// @arg value
/// @arg add

function action_background_desaturate_night_amount(val, add)
{
	if (!history_undo && !history_redo)
		history_set_var(action_background_desaturate_night_amount, background_desaturate_night_amount, background_desaturate_night_amount * add + val / 100, true)
	else
		val *= 100
	
	background_desaturate_night_amount = background_desaturate_night_amount * add + val / 100
}
