/// action_tl_frame_cam_lensflare_color(color)
/// @arg color

function action_tl_frame_cam_lensflare_color(color)
{
	tl_value_set_start(action_tl_frame_cam_lensflare_color, true)
	tl_value_set(e_value.CAM_LENSFLARE_COLOR, color, false)
	tl_value_set_done()
}
