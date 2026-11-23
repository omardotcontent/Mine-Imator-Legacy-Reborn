/// action_view_quick_render([camera])
/// @arg [camera]
/// @desc Instantly renders the current camera using the enhanced 1.2.9 engine and saves a PNG into Renders/

function action_view_quick_render(cam = null)
{
	var rendersdir, fn, basefn, surf, dt, mo, da, idx;
	var prev_lights, prev_particles, prev_effects, prev_quality, prev_watermark, prev_bg;
	
	if (project_folder != "")
		rendersdir = project_folder + "/Renders/"
	else
		rendersdir = user_directory_get() + "Renders/"
	
	directory_create_lib(rendersdir)
	
	dt = date_current_datetime()
	mo = date_get_month(dt)
	da = date_get_day(dt)
	
	basefn = rendersdir + "render_" + string(date_get_year(dt)) + "-" + (mo < 10 ? "0" : "") + string(mo) + "-" + (da < 10 ? "0" : "") + string(da) + "_"
	idx = 1
	fn = basefn + "001.png"
	while (file_exists_lib(fn))
	{
		idx++
		fn = basefn + (idx < 10 ? "00" : (idx < 100 ? "0" : "")) + string(idx) + ".png"
	}
	
	prev_lights = render_lights
	prev_particles = render_particles
	prev_effects = render_effects
	prev_quality = render_quality
	prev_watermark = render_watermark
	prev_bg = render_background
	
	render_lights = true
	render_particles = true
	render_effects = true
	render_quality = e_view_mode.RENDER
	render_watermark = setting_export_image_watermark
	render_background = true
	
	surf = null
	render_start(surf, cam)
	render_high()
	surf = render_done()
	
	if (surface_exists(surf))
	{
		surface_save_lib(surf, fn)
		surface_free(surf)
		toast_new(e_toast.POSITIVE, text_get("quickrendersaved", filename_name(fn)))
		toast_add_action("alertexportimageview", popup_open_url, fn)
		toast_add_action("alertexportimagefolder", popup_open_url, rendersdir)
		toast_last.dismiss_time = 10
		log("Quick render saved", fn)
	}
	
	render_lights = prev_lights
	render_particles = prev_particles
	render_effects = prev_effects
	render_quality = prev_quality
	render_watermark = prev_watermark
	render_background = prev_bg
}
