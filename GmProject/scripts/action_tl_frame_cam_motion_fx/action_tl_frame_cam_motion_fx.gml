/// action_tl_frame_cam_motion_fx(enable)
/// @arg enable

function action_tl_frame_cam_motion_fx(enable)
{
	tl_value_set_start(action_tl_frame_cam_motion_fx, false)
	tl_value_set(e_value.CAM_MOTION_FX, enable, false)
	tl_value_set_done()
}
