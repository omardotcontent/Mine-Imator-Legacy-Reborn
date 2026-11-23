/// action_tl_frame_cam_ssr_fresnel(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_ssr_fresnel(val, add)
{
	tl_value_set_start(action_tl_frame_cam_ssr_fresnel, true)
	tl_value_set(e_value.CAM_SSR_FRESNEL, val / 100, add)
	tl_value_set_done()
}
