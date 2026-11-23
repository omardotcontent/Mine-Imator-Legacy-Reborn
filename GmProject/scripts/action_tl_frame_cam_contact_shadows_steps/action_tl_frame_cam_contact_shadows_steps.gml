/// action_tl_frame_cam_contact_shadows_steps(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_contact_shadows_steps(val, add)
{
	tl_value_set_start(action_tl_frame_cam_contact_shadows_steps, true)
	tl_value_set(e_value.CAM_CONTACT_SHADOWS_STEPS, val, add)
	tl_value_set_done()
}
