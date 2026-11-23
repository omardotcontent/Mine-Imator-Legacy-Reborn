/// action_tl_frame_cam_outline_opacity(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_outline_opacity(val, add)
{
	tl_value_set_start(action_tl_frame_cam_outline_opacity, true)
	tl_value_set(e_value.CAM_OUTLINE_OPACITY, val / 100, add)
	tl_value_set_done()
}
