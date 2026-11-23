/// shader_high_weather_set()

function shader_high_weather_set()
{
	render_set_uniform_vec2("uScreenSize", render_width, render_height)
	var rtime;
	if (app.window_state = "export_movie" || app.window_state = "export_image")
		rtime = app.background_time / 60
	else
		rtime = app.background_time / 60 + current_time / 1000
	render_set_uniform("uTime", rtime)
	
	if (render_camera != null && render_effects && render_camera.value[e_value.CAM_WEATHER_FX])
	{
		render_set_uniform("uRain", render_camera.value[e_value.CAM_WEATHER_RAIN])
		render_set_uniform("uSnow", render_camera.value[e_value.CAM_WEATHER_SNOW])
		render_set_uniform("uWind", render_camera.value[e_value.CAM_WEATHER_WIND])
		render_set_uniform("uLensDrops", render_camera.value[e_value.CAM_WEATHER_LENS_DROPS])
	}
	else
	{
		render_set_uniform("uRain", app.project_render_weather_rain)
		render_set_uniform("uSnow", app.project_render_weather_snow)
		render_set_uniform("uWind", app.project_render_weather_wind)
		render_set_uniform("uLensDrops", app.project_render_weather_lens_drops)
	}
}
