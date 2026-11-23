/// action_tl_frame_cam_ssr_water_only(enable)
/// @arg enable

function action_tl_frame_cam_ssr_water_only(enable)
{
	tl_value_set_start(action_tl_frame_cam_ssr_water_only, false)
	tl_value_set(e_value.CAM_SSR_WATER_ONLY, enable, false)
	tl_value_set_done()
}
