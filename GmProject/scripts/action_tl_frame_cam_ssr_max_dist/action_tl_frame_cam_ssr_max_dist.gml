/// action_tl_frame_cam_ssr_max_dist(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_ssr_max_dist(val, add)
{
	tl_value_set_start(action_tl_frame_cam_ssr_max_dist, true)
	tl_value_set(e_value.CAM_SSR_MAX_DIST, val, add)
	tl_value_set_done()
}
