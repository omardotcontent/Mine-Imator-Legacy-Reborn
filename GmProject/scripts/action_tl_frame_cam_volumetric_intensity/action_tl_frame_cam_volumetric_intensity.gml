/// action_tl_frame_cam_volumetric_intensity(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_volumetric_intensity(val, add)
{
	tl_value_set_start(action_tl_frame_cam_volumetric_intensity, true)
	tl_value_set(e_value.CAM_VOLUMETRIC_INTENSITY, val / 100, add)
	tl_value_set_done()
}
