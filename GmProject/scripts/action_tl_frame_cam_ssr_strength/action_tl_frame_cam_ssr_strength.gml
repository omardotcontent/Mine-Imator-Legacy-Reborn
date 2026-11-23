/// action_tl_frame_cam_ssr_strength(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_ssr_strength(val, add)
{
	tl_value_set_start(action_tl_frame_cam_ssr_strength, true)
	tl_value_set(e_value.CAM_SSR_STRENGTH, val / 100, add)
	tl_value_set_done()
}
