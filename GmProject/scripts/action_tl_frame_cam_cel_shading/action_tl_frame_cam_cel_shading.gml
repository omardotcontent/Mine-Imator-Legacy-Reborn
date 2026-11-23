/// action_tl_frame_cam_cel_shading(enable)
/// @arg enable

function action_tl_frame_cam_cel_shading(enable)
{
	tl_value_set_start(action_tl_frame_cam_cel_shading, false)
	tl_value_set(e_value.CAM_CEL_SHADING, enable, false)
	tl_value_set_done()
}
