/// action_background_desaturate_night(desaturate)
/// @arg desaturate

function action_background_desaturate_night(desaturate)
{
	if (!history_undo && !history_redo)
		history_set_var(action_background_desaturate_night, background_desaturate_night, desaturate, false)
	
	background_desaturate_night = desaturate
}
