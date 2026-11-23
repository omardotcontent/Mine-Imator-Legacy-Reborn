/// action_tl_frame_cam_contact_shadows_length(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_contact_shadows_length(val, add)
{
	tl_value_set_start(action_tl_frame_cam_contact_shadows_length, true)
	tl_value_set(e_value.CAM_CONTACT_SHADOWS_LENGTH, val, add)
	tl_value_set_done()
}
