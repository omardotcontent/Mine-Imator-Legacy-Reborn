/// shader_high_tonemap_set()

function shader_high_tonemap_set()
{
	render_set_uniform_vec2("uScreenSize", render_width, render_height)
	
	var tm = app.project_render_tonemapper;
	var expv = app.project_render_exposure;
	var gamv = app.project_render_gamma;
	
	if (render_camera != null && render_effects && render_camera.value[e_value.CAM_LIGHT_MANAGEMENT])
	{
		tm = render_camera.value[e_value.CAM_TONEMAPPER]
		expv = render_camera.value[e_value.CAM_EXPOSURE]
		gamv = render_camera.value[e_value.CAM_GAMMA]
	}
	
	var temp = app.project_render_temperature;
	var tint = app.project_render_tint;
	var liftS = app.project_render_lift_shadows;
	var liftM = app.project_render_lift_midtones;
	var liftH = app.project_render_lift_highlights;
	var sharp = app.project_render_sharpen;
	
	if (render_camera != null && render_effects && render_camera.value[e_value.CAM_COLOR_CORRECTION])
	{
		temp += render_camera.value[e_value.CAM_TEMPERATURE]
		tint += render_camera.value[e_value.CAM_TINT]
		liftS += render_camera.value[e_value.CAM_LIFT_SHADOWS]
		liftM += render_camera.value[e_value.CAM_LIFT_MIDTONES]
		liftH += render_camera.value[e_value.CAM_LIFT_HIGHLIGHTS]
		sharp = max(sharp, render_camera.value[e_value.CAM_SHARPEN])
	}
	
	render_set_uniform_int("uTonemapper", tm)
	render_set_uniform("uExposure", expv)
	render_set_uniform("uGamma", gamv)
	render_set_uniform("uContrast", app.project_render_contrast)
	render_set_uniform("uSaturation", app.project_render_saturation)
	render_set_uniform("uVibrance", app.project_render_vibrance)
	render_set_uniform("uSharpen", sharp)
	
	render_set_uniform("uTemperature", temp)
	render_set_uniform("uTint", tint)
	render_set_uniform("uLiftShadows", liftS)
	render_set_uniform("uLiftMidtones", liftM)
	render_set_uniform("uLiftHighlights", liftH)
	render_set_uniform("uGlobalCA", app.project_render_global_ca)
	render_set_uniform("uGlobalGrain", app.project_render_global_grain)
	render_set_uniform("uTime", app.background_time / 60 + (current_time / 1000))
	render_set_uniform("uGlobalVignette", app.project_render_global_vignette)
	render_set_uniform("uGlobalVignetteRadius", app.project_render_global_vignette_radius)
	render_set_uniform_color("uGlobalVignetteColor", app.project_render_global_vignette_color, 1)
}
