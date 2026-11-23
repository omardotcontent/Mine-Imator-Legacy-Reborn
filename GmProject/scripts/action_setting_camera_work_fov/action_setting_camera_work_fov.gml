/// action_setting_camera_work_fov(value, add)
/// @arg value
/// @arg add

function action_setting_camera_work_fov(val, add)
{
	setting_camera_work_fov = setting_camera_work_fov * add + val
	setting_camera_work_fov = clamp(setting_camera_work_fov, 20, 120)
}
