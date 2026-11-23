/// action_tl_frame_cam_outline_dist_fade_enable(enable)
/// @arg enable

function action_tl_frame_cam_outline_dist_fade_enable(enable)
{
	tl_value_set_start(action_tl_frame_cam_outline_dist_fade_enable, false)
	tl_value_set(e_value.CAM_OUTLINE_DIST_FADE_ENABLE, enable, false)
	tl_value_set_done()
}
