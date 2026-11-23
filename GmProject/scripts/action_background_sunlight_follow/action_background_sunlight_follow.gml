/// action_background_sunlight_follow(follow)
/// @arg follow

function action_background_sunlight_follow(follow)
{
	if (!history_undo && !history_redo)
		history_set_var(action_background_sunlight_follow, background_sunlight_follow, follow, false)
	
	background_sunlight_follow = follow
}
