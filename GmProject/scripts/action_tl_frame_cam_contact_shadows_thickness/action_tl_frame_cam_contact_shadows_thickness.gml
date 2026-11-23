/// action_tl_frame_cam_contact_shadows_thickness(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_contact_shadows_thickness(val, add)
{
	tl_value_set_start(action_tl_frame_cam_contact_shadows_thickness, true)
	tl_value_set(e_value.CAM_CONTACT_SHADOWS_THICKNESS, val, add)
	tl_value_set_done()
}
