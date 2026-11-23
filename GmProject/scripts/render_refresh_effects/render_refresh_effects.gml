/// render_refresh_effects(sceneeffects, posteffects)
/// @arg sceneeffects
/// @arg posteffects

function render_refresh_effects(sceneeffects = true, posteffects = true)
{
	ds_list_clear(render_effects_list)
	ds_list_add(render_effects_list,
		render_contact_shadows && sceneeffects,
		render_ssr && sceneeffects,
		render_volumetric_lights && sceneeffects,
		render_outline && sceneeffects,
		render_godrays && sceneeffects,
		render_lensflare && sceneeffects,
		render_camera_dof && sceneeffects,
		render_camera_bloom && posteffects,
		render_global_bloom && posteffects,
		render_glow && sceneeffects,
		render_glow_falloff && sceneeffects,
		render_aa && posteffects,
		render_camera_ca && posteffects,
		render_camera_distort && posteffects,
		render_camera_lens_dirt && (sceneeffects || posteffects),
		render_camera_color_correction && posteffects,
		render_camera_grain && posteffects,
		render_camera_vignette && posteffects,
		render_tonemap_pass && posteffects,
		render_retro && posteffects,
		render_motion_fx && posteffects,
		render_weather_fx && posteffects,
		render_overlay && posteffects
	)
	
	render_effects_progress = -1
	render_post_index = 0
	render_effects_done = false
}
