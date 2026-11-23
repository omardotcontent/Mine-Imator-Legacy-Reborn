/// action_tl_frame_cam_volumetric_spot_density(value, add)
/// @arg value
/// @arg add

function action_tl_frame_cam_volumetric_spot_density(val, add)
{
	tl_value_set_start(action_tl_frame_cam_volumetric_spot_density, true)
	tl_value_set(e_value.CAM_VOLUMETRIC_SPOT_DENSITY, val / 100, add)
	tl_value_set_done()
}
