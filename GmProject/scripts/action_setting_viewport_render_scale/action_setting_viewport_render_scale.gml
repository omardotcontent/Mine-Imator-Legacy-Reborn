/// action_setting_viewport_render_scale(value, add)
/// @arg value
/// @arg add

function action_setting_viewport_render_scale(val, add)
{
	setting_viewport_render_scale = setting_viewport_render_scale * add + val / 100
	setting_viewport_render_scale = clamp(setting_viewport_render_scale, 0.25, 2.0)
}
