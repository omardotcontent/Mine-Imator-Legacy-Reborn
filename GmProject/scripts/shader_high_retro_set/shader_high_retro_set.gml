/// shader_high_retro_set()

function shader_high_retro_set()
{
	render_set_uniform_vec2("uScreenSize", render_width, render_height)
	render_set_uniform("uTime", app.background_time / 60 + (current_time / 1000))
	
	if (render_camera != null && render_effects && render_camera.value[e_value.CAM_RETRO])
	{
		render_set_uniform("uPixelate", render_camera.value[e_value.CAM_RETRO_PIXELATE])
		render_set_uniform_int("uDither", render_camera.value[e_value.CAM_RETRO_DITHER])
		render_set_uniform("uColors", render_camera.value[e_value.CAM_RETRO_COLORS])
		render_set_uniform("uScanlines", render_camera.value[e_value.CAM_RETRO_SCANLINES])
		render_set_uniform("uCurvature", render_camera.value[e_value.CAM_RETRO_CURVATURE])
		render_set_uniform("uVHS", render_camera.value[e_value.CAM_RETRO_VHS])
	}
	else
	{
		render_set_uniform("uPixelate", app.project_render_retro_pixelate)
		render_set_uniform_int("uDither", app.project_render_retro_dither)
		render_set_uniform("uColors", app.project_render_retro_colors)
		render_set_uniform("uScanlines", app.project_render_retro_scanlines)
		render_set_uniform("uCurvature", app.project_render_retro_curvature)
		render_set_uniform("uVHS", app.project_render_retro_vhs)
	}
}
