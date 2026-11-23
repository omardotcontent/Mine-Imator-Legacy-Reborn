/// action_tl_frame_cam_ssr_thickness(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_ssr_thickness(val, add)
{
	tl_value_set_start(action_tl_frame_cam_ssr_thickness, true)
	tl_value_set(e_value.CAM_SSR_THICKNESS, val, add)
	tl_value_set_done()
}
