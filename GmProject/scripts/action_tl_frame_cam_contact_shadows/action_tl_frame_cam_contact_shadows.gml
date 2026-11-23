/// action_tl_frame_cam_contact_shadows(enable)
/// @arg enable

function action_tl_frame_cam_contact_shadows(enable)
{
	tl_value_set_start(action_tl_frame_cam_contact_shadows, false)
	tl_value_set(e_value.CAM_CONTACT_SHADOWS, enable, false)
	tl_value_set_done()
}
