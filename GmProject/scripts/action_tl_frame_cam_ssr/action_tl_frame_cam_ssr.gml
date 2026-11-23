/// action_tl_frame_cam_ssr(enable)
/// @arg enable

function action_tl_frame_cam_ssr(enable)
{
	tl_value_set_start(action_tl_frame_cam_ssr, false)
	tl_value_set(e_value.CAM_SSR, enable, false)
	tl_value_set_done()
}
