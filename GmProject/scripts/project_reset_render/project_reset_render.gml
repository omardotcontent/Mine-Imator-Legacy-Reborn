/// project_reset_render()

function project_reset_render()
{
	project_render_samples = 1
	project_render_ssaa = 1
	project_render_distance = 30000
	
	project_render_ssao = true
	project_render_ssao_samples = 16
	project_render_ssao_ratio = 1
	project_render_ssao_radius = 12
	project_render_ssao_power = 1
	project_render_ssao_bias = 1
	project_render_ssao_blur_passes = 2
	project_render_ssao_color = c_black
	
	project_render_shadows = true
	project_render_shadows_sun_buffer_size = 2048
	project_render_shadows_spot_buffer_size = 512
	project_render_shadows_point_buffer_size = 256
	project_render_shadows_blur_quality = 24
	project_render_shadows_blur_size = 1
	project_render_shadows_bias = 1
	project_render_shadows_darkness = 1
	project_render_shadows_tint = c_black
	project_render_shadows_transparent = false
	project_render_light_bleeding = true
	project_render_light_bleeding_strength = 1
	
	// Enhanced 1.2.9 Lighting & Atmosphere (toggleable)
	project_render_hemi_light = false
	project_render_hemi_strength = 0.25
	project_render_hemi_sky_color = make_color_rgb(120, 175, 255)
	project_render_hemi_ground_color = make_color_rgb(75, 65, 50)
	
	project_render_rim_light = false
	project_render_rim_strength = 0.35
	project_render_rim_power = 3
	project_render_rim_color = make_color_rgb(255, 248, 230)
	
	project_render_specular = false
	project_render_specular_strength = 0.45
	project_render_specular_shininess = 32
	
	project_render_godrays = false
	project_render_godrays_samples = 50
	project_render_godrays_density = 0.85
	project_render_godrays_decay = 0.90
	project_render_godrays_weight = 0.35
	project_render_godrays_exposure = 0.10
	project_render_godrays_color = make_color_rgb(255, 240, 200)
	
	// Screen-Space Reflections (SSR)
	project_render_ssr = false
	project_render_ssr_steps = 48
	project_render_ssr_max_dist = 1200
	project_render_ssr_thickness = 18
	project_render_ssr_strength = 0.85
	project_render_ssr_fresnel = 1.0
	project_render_ssr_water_only = false
	
	// Water Ripples & Global Wetness / Rain Puddles
	project_render_water_ripples = false
	project_render_water_ripple_strength = 1.0
	project_render_water_ripple_speed = 1.0
	project_render_wetness = 0
	project_render_wetness_ripples = true
	
	// Screen-Space Contact Shadows
	project_render_contact_shadows = false
	project_render_contact_shadows_steps = 20
	project_render_contact_shadows_length = 12
	project_render_contact_shadows_thickness = 3
	project_render_contact_shadows_strength = 0.65
	
	// Cloud Shadows & Stained Glass Colored Shadows
	project_render_cloud_shadows = false
	project_render_cloud_shadows_strength = 0.45
	project_render_cloud_shadows_scale = 1.0
	project_render_colored_shadows = false
	project_render_colored_shadows_strength = 1.0
	
	// Atmospheric Fog Scatter & Height Mist
	project_render_fog_scatter = 0
	project_render_fog_scatter_color = make_color_rgb(255, 210, 150)
	project_render_height_fog = false
	project_render_height_fog_height = 0
	project_render_height_fog_density = 0.5
	project_render_height_fog_color = make_color_rgb(180, 205, 235)
	
	// Procedural Sun Lens Flare
	project_render_lensflare = false
	project_render_lensflare_intensity = 0.65
	project_render_lensflare_ghosts = 0.8
	project_render_lensflare_halo = 0.6
	project_render_lensflare_starburst = 0.75
	project_render_lensflare_color = make_color_rgb(255, 235, 200)
	
	// Global HDR Bloom
	project_render_global_bloom = false
	project_render_global_bloom_threshold = 0.8
	project_render_global_bloom_intensity = 0.55
	project_render_global_bloom_radius = 1.2
	project_render_global_bloom_color = c_white
	
	// Anime / Toon Cel-Shading & Edge Outlines
	project_render_cel_shading = false
	project_render_cel_steps = 4
	project_render_cel_smoothness = 0.15
	project_render_outline = false
	project_render_outline_thickness = 1.5
	project_render_outline_depth_sens = 1.0
	project_render_outline_normal_sens = 1.0
	project_render_outline_opacity = 0.85
	project_render_outline_dist_fade_enable = false
	project_render_outline_dist_fade = 0.5
	project_render_outline_color = c_black
	
	// Volumetric Spotlights & Point Light Halos
	project_render_volumetric_lights = false
	project_render_volumetric_intensity = 0.75
	project_render_volumetric_spot_density = 0.85
	project_render_volumetric_point_radius = 1.0
	project_render_volumetric_steps = 24
	
	// Motion Blur / Radial Zoom Blur / Anime Speed Lines
	project_render_motion_fx = false
	project_render_motion_blur = 0
	project_render_radial_blur = 0
	project_render_speed_lines = 0
	project_render_speed_lines_radius = 0.55
	project_render_speed_lines_color = c_white
	
	// Screen-Space Weather & Camera Lens Drops
	project_render_weather_fx = false
	project_render_weather_rain = 0
	project_render_weather_snow = 0
	project_render_weather_wind = 0.15
	project_render_weather_lens_drops = 0
	
	// Cinema Color Grading Suite
	project_render_temperature = 0
	project_render_tint = 0
	project_render_lift_shadows = 0
	project_render_lift_midtones = 0
	project_render_lift_highlights = 0
	project_render_global_ca = 0
	project_render_global_grain = 0
	project_render_global_vignette = 0
	project_render_global_vignette_radius = 0.75
	project_render_global_vignette_color = c_black
	
	// Stylized / Retro Post-FX
	project_render_retro = false
	project_render_retro_pixelate = 1
	project_render_retro_dither = false
	project_render_retro_colors = 16
	project_render_retro_scanlines = 0
	project_render_retro_curvature = 0
	project_render_retro_vhs = 0
	
	// Legacy compatibility fields
	project_render_subsurface_samples = 0
	project_render_subsurface_highlight = .5
	project_render_subsurface_highlight_strength = 1
	project_render_indirect = false
	project_render_indirect_precision = .3
	project_render_indirect_blur_radius = 1
	project_render_indirect_strength = 1
	project_render_reflections = false
	project_render_reflections_precision = .3
	project_render_reflections_thickness = 1
	project_render_reflections_fade_amount = 1
	
	project_render_glow = true
	project_render_glow_radius = 1
	project_render_glow_intensity = 1
	project_render_glow_passes = 3
	project_render_glow_anamorphic = false
	project_render_glow_anamorphic_ratio = 3
	project_render_glow_falloff = false
	project_render_glow_falloff_radius = 2
	project_render_glow_falloff_intensity = 1
	project_render_block_glow = true
	project_render_block_glow_threshold = 0.75
	
	project_render_aa = true
	project_render_aa_power = 1
	project_render_aa_threshold = 0.05
	
	project_render_texture_filtering = true
	project_render_transparent_block_texture_filtering = false
	project_render_texture_filtering_level = 1
	
	project_render_alpha_mode = e_alpha_mode.BLEND
	project_render_tonemapper = e_tonemapper.NONE
	project_render_exposure = 1
	project_render_gamma = 1
	project_render_contrast = 1
	project_render_saturation = 1
	project_render_vibrance = 0
	project_render_sharpen = 0
	project_render_material_maps = true
	
	project_bend_style = "blocky"
	project_render_opaque_leaves = false
	project_render_liquid_animation = true
	project_render_water_reflections = false
	
	project_render_block_emissive = 1
	project_render_block_subsurface = 8
	
	project_render_glint_speed = 1
	project_render_glint_strength = 1
	
	texture_set_mipmap_level(project_render_texture_filtering_level)
	render_generate_dof_samples(0, 0, 0)
	render_samples = -1
	render_samples_clear = true
	
	// Update bend meshes
	with (obj_timeline)
	{
		bend_rot_last = vec3(0)
		tl_update_model_shape_bend()
	}
}
