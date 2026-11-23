/// render_post(surface, [sceneeffects, posteffects])
/// @arg surface
/// @arg sceneeffects
/// @arg posteffects

function render_post(finalsurf, sceneeffects = true, posteffects = true)
{
	// Start post processing
	finalsurf = render_high_post_start(finalsurf)
	
	// Screen-Space Contact Shadows
	if (render_contact_shadows && sceneeffects)
		finalsurf = render_high_contact_shadows(finalsurf)
	render_update_effects()
	
	// Screen-Space Reflections (SSR)
	if (render_ssr && sceneeffects)
		finalsurf = render_high_ssr(finalsurf)
	render_update_effects()
	
	// Volumetric Spotlights & Point Light Halos
	if (render_volumetric_lights && sceneeffects)
		finalsurf = render_high_volumetric_lights(finalsurf)
	render_update_effects()
	
	// Depth / Normal Edge Outlines (Anime / Toon)
	if (render_outline && sceneeffects)
		finalsurf = render_high_outline(finalsurf)
	render_update_effects()
	
	// Sun God-Rays / Volumetric Light Shafts
	if (render_godrays && sceneeffects)
		finalsurf = render_high_godrays(finalsurf)
	render_update_effects()
	
	// Procedural Sun Lens Flare
	if (render_lensflare && sceneeffects)
		finalsurf = render_high_lensflare(finalsurf)
	render_update_effects()
	
	// DOF
	if (render_camera_dof && sceneeffects)
		finalsurf = render_high_dof(finalsurf)
	render_update_effects()
	
	// Camera Bloom
	if (render_camera_bloom && posteffects)
		finalsurf = render_high_bloom(finalsurf)
	render_update_effects()
	
	// Global HDR Bloom
	if (render_global_bloom && posteffects)
		finalsurf = render_high_global_bloom(finalsurf)
	render_update_effects()
	
	// Glow
	if (render_glow && sceneeffects)
		finalsurf = render_high_glow(finalsurf)
	render_update_effects()
	
	// Glow (Falloff)
	if (render_glow_falloff && sceneeffects)
		finalsurf = render_high_glow(finalsurf, true)
	render_update_effects()
	
	// Anti-Aliasing (FXAA)
	if (render_aa && posteffects)
		finalsurf = render_high_aa(finalsurf)
	render_update_effects()
	
	// Chromatic aberration
	if (render_camera_ca && posteffects)
		finalsurf = render_high_ca(finalsurf)
	render_update_effects()
	
	// Distort
	if (render_camera_distort && posteffects)
		finalsurf = render_high_distort(finalsurf)
	render_update_effects()
	
	// Lens dirt overlay
	if (render_camera_lens_dirt && (sceneeffects || posteffects))
		finalsurf = render_high_lens_dirt(finalsurf)
	render_update_effects()
	
	// Color correction (camera)
	if (render_camera_color_correction && posteffects)
		finalsurf = render_high_cc(finalsurf)
	render_update_effects()
	
	// Film grain
	if (render_camera_grain && posteffects)
		finalsurf = render_high_grain(finalsurf)
	render_update_effects()
	
	// Vignette
	if (render_camera_vignette && posteffects)
		finalsurf = render_high_vignette(finalsurf)
	render_update_effects()
	
	// Global Tone Mapping, Cinema Grading & CAS Sharpening
	if (render_tonemap_pass && posteffects)
		finalsurf = render_high_tonemap(finalsurf)
	render_update_effects()
	
	// Stylized / Retro Post-FX (Pixelate, PS1 Dither, CRT, VHS)
	if (render_retro && posteffects)
		finalsurf = render_high_retro(finalsurf)
	render_update_effects()
	
	// Motion Blur / Radial Zoom Blur / Anime Speed Lines
	if (render_motion_fx && posteffects)
		finalsurf = render_high_fx_motion(finalsurf)
	render_update_effects()
	
	// Screen-Space Weather & Camera Lens Drops
	if (render_weather_fx && posteffects)
		finalsurf = render_high_weather(finalsurf)
	render_update_effects()
	
	// 2D overlay (camera colors/watermark)
	if (render_overlay && posteffects)
		finalsurf = render_high_overlay(finalsurf)
	render_update_effects()
	
	return finalsurf
}
