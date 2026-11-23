/// action_tl_frame_cam_volumetric_lights(enable)
/// @arg enable

function action_tl_frame_cam_volumetric_lights(enable)
{
	tl_value_set_start(action_tl_frame_cam_volumetric_lights, false)
	tl_value_set(e_value.CAM_VOLUMETRIC_LIGHTS, enable, false)
	tl_value_set_done()
}
