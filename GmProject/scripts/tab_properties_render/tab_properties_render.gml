/// tab_properties_render()

function tab_properties_render()
{
	var text;
	
	// Render settings preset
	if (project_render_settings = "")
		text = text_get("projectrendersettingscustom")
	else if (text_exists("projectrendersettings" + project_render_settings))
		text = text_get("projectrendersettings" + project_render_settings)
	else
		text = filename_name(project_render_settings)
	
	tab_control_menu()
	draw_button_menu("projectrendersettings", e_menu.LIST, dx, dy, dw, 24, project_render_settings, text, action_project_render_settings)
	tab_next()
	
	if (project_render_settings != "")
		return 0
	
	dy += 8
	
	// Supersampling (SSAA)
	var ssaatext = string(project_render_ssaa) + "x (" + string(round(project_render_ssaa * 100)) + "%)";
	if (project_render_ssaa = 1)
		ssaatext = "1x (Native)"
	tab_control_menu()
	draw_button_menu("renderssaa", e_menu.LIST, dx, dy, dw, 24, project_render_ssaa, ssaatext, action_project_render_ssaa)
	tab_next()
	
	// Render distance
	tab_control_dragger()
	draw_dragger("renderdistance", dx, dy, dragger_width, project_render_distance, 10, 1000, 500000, 30000, 1, tab.render.tbx_render_distance, action_project_render_distance, null, true, false, "renderdistancetip")
	tab_next()
	
	// Object Material & Normal Maps (LabPBR / SEUS)
	tab_control_switch()
	draw_switch("rendermaterialmaps", dx, dy, project_render_material_maps, action_project_render_material_maps, "rendermaterialmapstip")
	tab_next()
	
	// SSAO
	tab_control_switch()
	draw_button_collapse("ssao", collapse_map[?"ssao"], action_project_render_ssao, project_render_ssao, "renderssao", "renderssaotip")
	tab_next()
	
	if (project_render_ssao && collapse_map[?"ssao"])
	{
		tab_collapse_start()
		
		tab_control_menu()
		draw_button_menu("renderssaosamples", e_menu.LIST, dx, dy, dw, 24, project_render_ssao_samples, string(project_render_ssao_samples) + " (" + text_get("renderssaosamples" + string(project_render_ssao_samples)) + ")", action_project_render_ssao_samples)
		tab_next()
		
		var ratiotxt = (project_render_ssao_ratio <= 0.5 ? "50% (" + text_get("renderssaoratiofast") + ")" : (project_render_ssao_ratio < 1 ? "75% (" + text_get("renderssaoratiobalanced") + ")" : "100% (" + text_get("renderssaoratiofull") + ")"));
		tab_control_menu()
		draw_button_menu("renderssaoratio", e_menu.LIST, dx, dy, dw, 24, project_render_ssao_ratio, ratiotxt, action_project_render_ssao_ratio)
		tab_next()
		
		tab_control_dragger()
		draw_dragger("renderssaoradius", dx, dy, dragger_width, project_render_ssao_radius, project_render_ssao_radius / 200, 0, 512, 12, 0, tab.render.tbx_ssao_radius, action_project_render_ssao_radius)
		tab_next()
		
		tab_control_dragger()
		draw_dragger("renderssaopower", dx, dy, dragger_width, round(project_render_ssao_power * 100), .5, 0, no_limit * 100, 100, 1, tab.render.tbx_ssao_power, action_project_render_ssao_power)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderssaobias", dx, dy, dw, round(project_render_ssao_bias * 100), 0, 400, 100, 1, tab.render.tbx_ssao_bias, action_project_render_ssao_bias, "renderssaobiastip")
		tab_next()
		
		tab_control_meter()
		draw_meter("renderssaoblurpasses", dx, dy, dw, project_render_ssao_blur_passes, 0, 16, 2, 1, tab.render.tbx_ssao_blur_passes, action_project_render_ssao_blur_passes, "renderssaoblurpassestip")
		tab_next()
		
		tab_control_color()
		draw_button_color("renderssaocolor", dx, dy, dw, project_render_ssao_color, c_black, false, action_project_render_ssao_color)
		tab_next()
		
		tab_collapse_end()
	}
	
	// Shadows
	tab_control_switch()
	draw_button_collapse("shadows", collapse_map[?"shadows"], action_project_render_shadows, project_render_shadows, "rendershadows")
	tab_next()
	
	if (project_render_shadows && collapse_map[?"shadows"])
	{
		tab_collapse_start()
		
		tab_control_menu()
		draw_button_menu("rendershadowssunbuffersize", e_menu.LIST, dx, dy, dw, 24, project_render_shadows_sun_buffer_size, text_get("rendershadowsbuffersize" + string(project_render_shadows_sun_buffer_size)) + " (" + string(project_render_shadows_sun_buffer_size) + "x" + string(project_render_shadows_sun_buffer_size) + ")", action_project_render_shadows_sun_buffer_size)
		tab_next()
		
		tab_control_menu()
		draw_button_menu("rendershadowsspotbuffersize", e_menu.LIST, dx, dy, dw, 24, project_render_shadows_spot_buffer_size, text_get("rendershadowsbuffersize" + string(project_render_shadows_spot_buffer_size)) + " (" + string(project_render_shadows_spot_buffer_size) + "x" + string(project_render_shadows_spot_buffer_size) + ")", action_project_render_shadows_spot_buffer_size)
		tab_next()
		
		tab_control_menu()
		draw_button_menu("rendershadowspointbuffersize", e_menu.LIST, dx, dy, dw, 24, project_render_shadows_point_buffer_size, text_get("rendershadowsbuffersize" + string(project_render_shadows_point_buffer_size)) + " (" + string(project_render_shadows_point_buffer_size) + "x" + string(project_render_shadows_point_buffer_size) + ")", action_project_render_shadows_point_buffer_size)
		tab_next()
		
		tab_control_meter()
		draw_meter("rendershadowsblurquality", dx, dy, dw, project_render_shadows_blur_quality, 1, 128, 24, 1, tab.render.tbx_shadows_blur_quality, action_project_render_shadows_blur_quality, "rendershadowsblurqualitytip")
		tab_next()
		
		tab_control_meter()
		draw_meter("rendershadowsblursize", dx, dy, dw, round(project_render_shadows_blur_size * 100), 0, 800, 100, 1, tab.render.tbx_shadows_blur_size, action_project_render_shadows_blur_size, "rendershadowsblursizetip")
		tab_next()
		
		tab_control_meter()
		draw_meter("rendershadowsbias", dx, dy, dw, round(project_render_shadows_bias * 100), 0, 500, 100, 1, tab.render.tbx_shadows_bias, action_project_render_shadows_bias, "rendershadowsbiastip")
		tab_next()
		
		tab_control_meter()
		draw_meter("rendershadowsdarkness", dx, dy, dw, round(project_render_shadows_darkness * 100), 0, 200, 100, 1, tab.render.tbx_shadows_darkness, action_project_render_shadows_darkness, "rendershadowsdarknesstip")
		tab_next()
		
		tab_control_color()
		draw_button_color("rendershadowstint", dx, dy, dw, project_render_shadows_tint, c_black, false, action_project_render_shadows_tint)
		tab_next()
		
		tab_control_switch()
		draw_switch("renderlightbleeding", dx, dy, project_render_light_bleeding, action_project_render_light_bleeding, "renderlightbleedingtip")
		tab_next()
		
		tab_control_meter()
		draw_meter("renderlightbleedingstrength", dx, dy, dw, round(project_render_light_bleeding_strength * 100), 0, 200, 100, 1, tab.render.tbx_light_bleeding_strength, action_project_render_light_bleeding_strength, "renderlightbleedingstrengthtip")
		tab_next()
		
		tab_collapse_end()
	}
	
	// Hemisphere Sky/Ground Ambient
	tab_control_switch()
	draw_button_collapse("hemi_light", collapse_map[?"hemi_light"], action_project_render_hemi_light, project_render_hemi_light, "renderhemilight", "renderhemilighttip")
	tab_next()
	
	if (project_render_hemi_light && collapse_map[?"hemi_light"])
	{
		tab_collapse_start()
		
		tab_control_meter()
		draw_meter("renderhemistrength", dx, dy, dw, round(project_render_hemi_strength * 100), 0, 200, 25, 1, tab.render.tbx_hemi_strength, action_project_render_hemi_strength)
		tab_next()
		
		tab_control_color()
		draw_button_color("renderhemiskycolor", dx, dy, dw, project_render_hemi_sky_color, make_color_rgb(120, 175, 255), false, action_project_render_hemi_sky_color)
		tab_next()
		
		tab_control_color()
		draw_button_color("renderhemigroundcolor", dx, dy, dw, project_render_hemi_ground_color, make_color_rgb(75, 65, 50), false, action_project_render_hemi_ground_color)
		tab_next()
		
		tab_collapse_end()
	}
	
	// Rim / Fresnel Backlight
	tab_control_switch()
	draw_button_collapse("rim_light", collapse_map[?"rim_light"], action_project_render_rim_light, project_render_rim_light, "renderrimlight", "renderrimlighttip")
	tab_next()
	
	if (project_render_rim_light && collapse_map[?"rim_light"])
	{
		tab_collapse_start()
		
		tab_control_meter()
		draw_meter("renderrimstrength", dx, dy, dw, round(project_render_rim_strength * 100), 0, 200, 35, 1, tab.render.tbx_rim_strength, action_project_render_rim_strength)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderrimpower", dx, dy, dw, project_render_rim_power, 1, 8, 3, 0.1, tab.render.tbx_rim_power, action_project_render_rim_power)
		tab_next()
		
		tab_control_color()
		draw_button_color("renderrimcolor", dx, dy, dw, project_render_rim_color, make_color_rgb(255, 248, 230), false, action_project_render_rim_color)
		tab_next()
		
		tab_collapse_end()
	}
	
	// Soft Specular Sheen
	tab_control_switch()
	draw_button_collapse("specular", collapse_map[?"specular"], action_project_render_specular, project_render_specular, "renderspecular", "renderspeculartip")
	tab_next()
	
	if (project_render_specular && collapse_map[?"specular"])
	{
		tab_collapse_start()
		
		tab_control_meter()
		draw_meter("renderspecularstrength", dx, dy, dw, round(project_render_specular_strength * 100), 0, 300, 45, 1, tab.render.tbx_specular_strength, action_project_render_specular_strength)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderspecularshininess", dx, dy, dw, project_render_specular_shininess, 4, 256, 32, 1, tab.render.tbx_specular_shininess, action_project_render_specular_shininess)
		tab_next()
		
		tab_collapse_end()
	}
	
	// Sun God-Rays / Volumetric Light Shafts
	tab_control_switch()
	draw_button_collapse("godrays", collapse_map[?"godrays"], action_project_render_godrays, project_render_godrays, "rendergodrays", "rendergodraystip")
	tab_next()
	
	if (project_render_godrays && collapse_map[?"godrays"])
	{
		tab_collapse_start()
		
		tab_control_meter()
		draw_meter("rendergodrayssamples", dx, dy, dw, project_render_godrays_samples, 16, 96, 50, 1, tab.render.tbx_godrays_samples, action_project_render_godrays_samples)
		tab_next()
		
		tab_control_meter()
		draw_meter("rendergodraysdensity", dx, dy, dw, round(project_render_godrays_density * 100), 10, 200, 85, 1, tab.render.tbx_godrays_density, action_project_render_godrays_density)
		tab_next()
		
		tab_control_meter()
		draw_meter("rendergodraysdecay", dx, dy, dw, round(project_render_godrays_decay * 100), 70, 100, 90, 1, tab.render.tbx_godrays_decay, action_project_render_godrays_decay)
		tab_next()
		
		tab_control_meter()
		draw_meter("rendergodraysweight", dx, dy, dw, round(project_render_godrays_weight * 100), 0, 100, 35, 1, tab.render.tbx_godrays_weight, action_project_render_godrays_weight)
		tab_next()
		
		tab_control_meter()
		draw_meter("rendergodraysexposure", dx, dy, dw, round(project_render_godrays_exposure * 100), 0, 200, 10, 1, tab.render.tbx_godrays_exposure, action_project_render_godrays_exposure)
		tab_next()
		
		tab_control_color()
		draw_button_color("rendergodrayscolor", dx, dy, dw, project_render_godrays_color, make_color_rgb(255, 240, 200), false, action_project_render_godrays_color)
		tab_next()
		
		tab_collapse_end()
	}
	
	// Screen-Space Reflections (SSR)
	tab_control_switch()
	draw_button_collapse("ssr", collapse_map[?"ssr"], action_project_render_ssr, project_render_ssr, "renderssr", "renderssrtip")
	tab_next()
	
	if (project_render_ssr && collapse_map[?"ssr"])
	{
		tab_collapse_start()
		
		tab_control_meter()
		draw_meter("renderssrsteps", dx, dy, dw, project_render_ssr_steps, 16, 96, 48, 1, tab.render.tbx_ssr_steps, action_project_render_ssr_steps)
		tab_next()
		
		tab_control_dragger()
		draw_dragger("renderssrmaxdist", dx, dy, dragger_width, project_render_ssr_max_dist, 10, 100, 5000, 1200, 1, tab.render.tbx_ssr_max_dist, action_project_render_ssr_max_dist)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderssrthickness", dx, dy, dw, project_render_ssr_thickness, 1, 100, 18, 0.5, tab.render.tbx_ssr_thickness, action_project_render_ssr_thickness)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderssrstrength", dx, dy, dw, round(project_render_ssr_strength * 100), 0, 200, 85, 1, tab.render.tbx_ssr_strength, action_project_render_ssr_strength)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderssrfresnel", dx, dy, dw, round(project_render_ssr_fresnel * 100), 0, 200, 100, 1, tab.render.tbx_ssr_fresnel, action_project_render_ssr_fresnel)
		tab_next()
		
		tab_control_switch()
		draw_switch("renderssrwateronly", dx, dy, project_render_ssr_water_only, action_project_render_ssr_water_only, "renderssrwateronlytip")
		tab_next()
		
		tab_collapse_end()
	}
	
	// Water Ripples & Global Wetness / Rain Puddles
	tab_control_switch()
	draw_button_collapse("water_wetness", collapse_map[?"water_wetness"], null, true, "renderwaterwetness", "renderwaterwetnesstip")
	tab_next()
	
	if (collapse_map[?"water_wetness"])
	{
		tab_collapse_start()
		
		tab_control_switch()
		draw_switch("renderwaterripples", dx, dy, project_render_water_ripples, action_project_render_water_ripples, "renderwaterripplestip")
		tab_next()
		
		if (project_render_water_ripples)
		{
			tab_control_meter()
			draw_meter("renderwaterripplestrength", dx, dy, dw, round(project_render_water_ripple_strength * 100), 0, 300, 100, 1, tab.render.tbx_water_ripple_strength, action_project_render_water_ripple_strength)
			tab_next()
			
			tab_control_meter()
			draw_meter("renderwaterripplespeed", dx, dy, dw, round(project_render_water_ripple_speed * 100), 0, 400, 100, 1, tab.render.tbx_water_ripple_speed, action_project_render_water_ripple_speed)
			tab_next()
		}
		
		tab_control_meter()
		draw_meter("renderwetness", dx, dy, dw, round(project_render_wetness * 100), 0, 100, 0, 1, tab.render.tbx_wetness, action_project_render_wetness, "renderwetnesstip")
		tab_next()
		
		if (project_render_wetness > 0)
		{
			tab_control_switch()
			draw_switch("renderwetnessripples", dx, dy, project_render_wetness_ripples, action_project_render_wetness_ripples, "renderwetnessripplestip")
			tab_next()
		}
		
		tab_collapse_end()
	}
	
	// Screen-Space Contact Shadows
	tab_control_switch()
	draw_button_collapse("contact_shadows", collapse_map[?"contact_shadows"], action_project_render_contact_shadows, project_render_contact_shadows, "rendercontactshadows", "rendercontactshadowstip")
	tab_next()
	
	if (project_render_contact_shadows && collapse_map[?"contact_shadows"])
	{
		tab_collapse_start()
		
		tab_control_meter()
		draw_meter("rendercontactshadowssteps", dx, dy, dw, project_render_contact_shadows_steps, 8, 48, 20, 1, tab.render.tbx_contact_shadows_steps, action_project_render_contact_shadows_steps)
		tab_next()
		
		tab_control_meter()
		draw_meter("rendercontactshadowslength", dx, dy, dw, project_render_contact_shadows_length, 1, 40, 12, 0.5, tab.render.tbx_contact_shadows_length, action_project_render_contact_shadows_length)
		tab_next()
		
		tab_control_meter()
		draw_meter("rendercontactshadowsthickness", dx, dy, dw, project_render_contact_shadows_thickness, 0.5, 20, 3, 0.5, tab.render.tbx_contact_shadows_thickness, action_project_render_contact_shadows_thickness)
		tab_next()
		
		tab_control_meter()
		draw_meter("rendercontactshadowsstrength", dx, dy, dw, round(project_render_contact_shadows_strength * 100), 0, 100, 65, 1, tab.render.tbx_contact_shadows_strength, action_project_render_contact_shadows_strength)
		tab_next()
		
		tab_collapse_end()
	}
	
	// Cloud Shadows & Stained Glass Colored Shadows
	tab_control_switch()
	draw_button_collapse("cloud_colored_shadows", collapse_map[?"cloud_colored_shadows"], null, true, "rendercloudcoloredshadows", "rendercloudcoloredshadowstip")
	tab_next()
	
	if (collapse_map[?"cloud_colored_shadows"])
	{
		tab_collapse_start()
		
		tab_control_switch()
		draw_switch("rendercloudshadows", dx, dy, project_render_cloud_shadows, action_project_render_cloud_shadows, "rendercloudshadowstip")
		tab_next()
		
		if (project_render_cloud_shadows)
		{
			tab_control_meter()
			draw_meter("rendercloudshadowsstrength", dx, dy, dw, round(project_render_cloud_shadows_strength * 100), 0, 100, 45, 1, tab.render.tbx_cloud_shadows_strength, action_project_render_cloud_shadows_strength)
			tab_next()
			
			tab_control_meter()
			draw_meter("rendercloudshadowsscale", dx, dy, dw, round(project_render_cloud_shadows_scale * 100), 25, 400, 100, 1, tab.render.tbx_cloud_shadows_scale, action_project_render_cloud_shadows_scale)
			tab_next()
		}
		
		tab_control_switch()
		draw_switch("rendercoloredshadows", dx, dy, project_render_colored_shadows, action_project_render_colored_shadows, "rendercoloredshadowstip")
		tab_next()
		
		if (project_render_colored_shadows)
		{
			tab_control_meter()
			draw_meter("rendercoloredshadowsstrength", dx, dy, dw, round(project_render_colored_shadows_strength * 100), 0, 200, 100, 1, tab.render.tbx_colored_shadows_strength, action_project_render_colored_shadows_strength)
			tab_next()
		}
		
		tab_collapse_end()
	}
	
	// Atmospheric Horizon Scatter & Height Mist
	tab_control_switch()
	draw_button_collapse("atm_fog", collapse_map[?"atm_fog"], null, true, "renderatmfog", "renderatmfogtip")
	tab_next()
	
	if (collapse_map[?"atm_fog"])
	{
		tab_collapse_start()
		
		tab_control_meter()
		draw_meter("renderfogscatter", dx, dy, dw, round(project_render_fog_scatter * 100), 0, 200, 0, 1, tab.render.tbx_fog_scatter, action_project_render_fog_scatter, "renderfogscattertip")
		tab_next()
		
		if (project_render_fog_scatter > 0)
		{
			tab_control_color()
			draw_button_color("renderfogscattercolor", dx, dy, dw, project_render_fog_scatter_color, make_color_rgb(255, 210, 150), false, action_project_render_fog_scatter_color)
			tab_next()
		}
		
		tab_control_switch()
		draw_switch("renderheightfog", dx, dy, project_render_height_fog, action_project_render_height_fog, "renderheightfogtip")
		tab_next()
		
		if (project_render_height_fog)
		{
			tab_control_dragger()
			draw_dragger("renderheightfogheight", dx, dy, dragger_width, project_render_height_fog_height, 1, -500, 2000, 0, 1, tab.render.tbx_height_fog_height, action_project_render_height_fog_height)
			tab_next()
			
			tab_control_meter()
			draw_meter("renderheightfogdensity", dx, dy, dw, round(project_render_height_fog_density * 100), 0, 300, 50, 1, tab.render.tbx_height_fog_density, action_project_render_height_fog_density)
			tab_next()
			
			tab_control_color()
			draw_button_color("renderheightfogcolor", dx, dy, dw, project_render_height_fog_color, make_color_rgb(180, 205, 235), false, action_project_render_height_fog_color)
			tab_next()
		}
		
		tab_collapse_end()
	}
	
	// Procedural Sun Lens Flare
	tab_control_switch()
	draw_button_collapse("lensflare", collapse_map[?"lensflare"], action_project_render_lensflare, project_render_lensflare, "renderlensflare", "renderlensflaretip")
	tab_next()
	
	if (project_render_lensflare && collapse_map[?"lensflare"])
	{
		tab_collapse_start()
		
		tab_control_meter()
		draw_meter("renderlensflareintensity", dx, dy, dw, round(project_render_lensflare_intensity * 100), 0, 200, 65, 1, tab.render.tbx_lensflare_intensity, action_project_render_lensflare_intensity)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderlensflareghosts", dx, dy, dw, round(project_render_lensflare_ghosts * 100), 0, 200, 80, 1, tab.render.tbx_lensflare_ghosts, action_project_render_lensflare_ghosts)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderlensflarehalo", dx, dy, dw, round(project_render_lensflare_halo * 100), 0, 200, 60, 1, tab.render.tbx_lensflare_halo, action_project_render_lensflare_halo)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderlensflarestarburst", dx, dy, dw, round(project_render_lensflare_starburst * 100), 0, 200, 75, 1, tab.render.tbx_lensflare_starburst, action_project_render_lensflare_starburst)
		tab_next()
		
		tab_control_color()
		draw_button_color("renderlensflarecolor", dx, dy, dw, project_render_lensflare_color, make_color_rgb(255, 235, 200), false, action_project_render_lensflare_color)
		tab_next()
		
		tab_collapse_end()
	}
	
	// Global HDR Bloom
	tab_control_switch()
	draw_button_collapse("global_bloom", collapse_map[?"global_bloom"], action_project_render_global_bloom, project_render_global_bloom, "renderglobalbloom", "renderglobalbloomtip")
	tab_next()
	
	if (project_render_global_bloom && collapse_map[?"global_bloom"])
	{
		tab_collapse_start()
		
		tab_control_meter()
		draw_meter("renderglobalbloomthreshold", dx, dy, dw, round(project_render_global_bloom_threshold * 100), 0, 100, 80, 1, tab.render.tbx_global_bloom_threshold, action_project_render_global_bloom_threshold)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderglobalbloomintensity", dx, dy, dw, round(project_render_global_bloom_intensity * 100), 0, 300, 55, 1, tab.render.tbx_global_bloom_intensity, action_project_render_global_bloom_intensity)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderglobalbloomradius", dx, dy, dw, round(project_render_global_bloom_radius * 100), 0, 400, 120, 1, tab.render.tbx_global_bloom_radius, action_project_render_global_bloom_radius)
		tab_next()
		
		tab_control_color()
		draw_button_color("renderglobalbloomcolor", dx, dy, dw, project_render_global_bloom_color, c_white, false, action_project_render_global_bloom_color)
		tab_next()
		
		tab_collapse_end()
	}
	
	// Anime / Toon Cel-Shading & Edge Outlines
	tab_control_switch()
	draw_button_collapse("cel_outline", collapse_map[?"cel_outline"], null, true, "renderceloutline", "renderceloutlinetip")
	tab_next()
	
	if (collapse_map[?"cel_outline"])
	{
		tab_collapse_start()
		
		tab_control_switch()
		draw_switch("rendercelshading", dx, dy, project_render_cel_shading, action_project_render_cel_shading, "rendercelshadingtip")
		tab_next()
		
		if (project_render_cel_shading)
		{
			tab_control_meter()
			draw_meter("rendercelsteps", dx, dy, dw, project_render_cel_steps, 2, 8, 4, 1, tab.render.tbx_cel_steps, action_project_render_cel_steps)
			tab_next()
			
			tab_control_meter()
			draw_meter("rendercelsmoothness", dx, dy, dw, round(project_render_cel_smoothness * 100), 0, 100, 15, 1, tab.render.tbx_cel_smoothness, action_project_render_cel_smoothness)
			tab_next()
		}
		
		tab_control_switch()
		draw_switch("renderoutline", dx, dy, project_render_outline, action_project_render_outline, "renderoutlinetip")
		tab_next()
		
		if (project_render_outline)
		{
			tab_control_meter()
			draw_meter("renderoutlinethickness", dx, dy, dw, project_render_outline_thickness, 0.5, 5, 1.5, 0.1, tab.render.tbx_outline_thickness, action_project_render_outline_thickness)
			tab_next()
			
			tab_control_meter()
			draw_meter("renderoutlinedepthsens", dx, dy, dw, round(project_render_outline_depth_sens * 100), 10, 500, 100, 1, tab.render.tbx_outline_depth_sens, action_project_render_outline_depth_sens)
			tab_next()
			
			tab_control_meter()
			draw_meter("renderoutlinenormalsens", dx, dy, dw, round(project_render_outline_normal_sens * 100), 10, 500, 100, 1, tab.render.tbx_outline_normal_sens, action_project_render_outline_normal_sens)
			tab_next()
			
			tab_control_meter()
			draw_meter("renderoutlineopacity", dx, dy, dw, round(project_render_outline_opacity * 100), 0, 100, 85, 1, tab.render.tbx_outline_opacity, action_project_render_outline_opacity)
			tab_next()
			
			tab_control_switch()
			draw_switch("renderoutlinedistfadeenable", dx, dy, project_render_outline_dist_fade_enable, action_project_render_outline_dist_fade_enable, "renderoutlinedistfadeenabletip")
			tab_next()
			
			if (project_render_outline_dist_fade_enable)
			{
				tab_control_meter()
				draw_meter("renderoutlinedistfade", dx, dy, dw, round(project_render_outline_dist_fade * 100), 0, 100, 50, 1, tab.render.tbx_outline_dist_fade, action_project_render_outline_dist_fade)
				tab_next()
			}
			
			tab_control_color()
			draw_button_color("renderoutlinecolor", dx, dy, dw, project_render_outline_color, c_black, false, action_project_render_outline_color)
			tab_next()
		}
		
		tab_collapse_end()
	}
	
	// Volumetric Spotlights & Point Light Halos
	tab_control_switch()
	draw_button_collapse("volumetric_lights", collapse_map[?"volumetric_lights"], action_project_render_volumetric_lights, project_render_volumetric_lights, "rendervolumetriclights", "rendervolumetriclightstip")
	tab_next()
	
	if (project_render_volumetric_lights && collapse_map[?"volumetric_lights"])
	{
		tab_collapse_start()
		
		tab_control_meter()
		draw_meter("rendervolumetricintensity", dx, dy, dw, round(project_render_volumetric_intensity * 100), 0, 200, 75, 1, tab.render.tbx_volumetric_intensity, action_project_render_volumetric_intensity)
		tab_next()
		
		tab_control_meter()
		draw_meter("rendervolumetricspotdensity", dx, dy, dw, round(project_render_volumetric_spot_density * 100), 0, 200, 85, 1, tab.render.tbx_volumetric_spot_density, action_project_render_volumetric_spot_density)
		tab_next()
		
		tab_control_meter()
		draw_meter("rendervolumetricpointradius", dx, dy, dw, round(project_render_volumetric_point_radius * 100), 0, 300, 100, 1, tab.render.tbx_volumetric_point_radius, action_project_render_volumetric_point_radius)
		tab_next()
		
		tab_control_meter()
		draw_meter("rendervolumetricsteps", dx, dy, dw, project_render_volumetric_steps, 8, 64, 24, 1, tab.render.tbx_volumetric_steps, action_project_render_volumetric_steps)
		tab_next()
		
		tab_collapse_end()
	}
	
	// Glow
	tab_control_switch()
	draw_button_collapse("glow", collapse_map[?"glow"], action_project_render_glow, project_render_glow, "renderglow")
	tab_next()
	
	if (project_render_glow && collapse_map[?"glow"])
	{
		tab_collapse_start()
		
		tab_control_dragger()
		draw_dragger("renderglowradius", dx, dy, dragger_width, round(project_render_glow_radius * 100), .5, 0, no_limit * 100, 100, 1, tab.render.tbx_glow_radius, action_project_render_glow_radius)
		tab_next()
		
		tab_control_dragger()
		draw_dragger("renderglowintensity", dx, dy, dragger_width, round(project_render_glow_intensity * 100), .5, 0, no_limit * 100, 100, 1, tab.render.tbx_glow_intensity, action_project_render_glow_intensity)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderglowpasses", dx, dy, dw, project_render_glow_passes, 1, 6, 3, 1, tab.render.tbx_glow_passes, action_project_render_glow_passes, "renderglowpassestip")
		tab_next()
		
		tab_control_switch()
		draw_switch("renderglowanamorphic", dx, dy, project_render_glow_anamorphic, action_project_render_glow_anamorphic, "renderglowanamorphictip")
		tab_next()
		
		if (project_render_glow_anamorphic)
		{
			tab_control_meter()
			draw_meter("renderglowanamorphicratio", dx, dy, dw, round(project_render_glow_anamorphic_ratio * 100), 100, 600, 300, 1, tab.render.tbx_glow_anamorphic_ratio, action_project_render_glow_anamorphic_ratio)
			tab_next()
		}
		
		tab_control_switch()
		draw_switch("renderblockglow", dx, dy, project_render_block_glow, action_project_render_block_glow, "renderblockglowtip")
		tab_next()
		
		if (project_render_block_glow)
		{
			tab_control_meter()
			draw_meter("renderblockglowthreshold", dx, dy, dw, round(project_render_block_glow_threshold * 100), 0, 100, 75, 1, tab.render.tbx_block_glow_threshold, action_project_render_block_glow_threshold, "renderblockglowthresholdtip")
			tab_next()
		}
		
		tab_control_switch()
		draw_button_collapse("glow_falloff", collapse_map[?"glow_falloff"], action_project_render_glow_falloff, project_render_glow_falloff, "renderglowfalloff")
		tab_next()
		
		// Secondary glow
		if (project_render_glow_falloff && collapse_map[?"glow_falloff"])
		{
			tab_collapse_start()
			
			tab_control_dragger()
			draw_dragger("renderglowfalloffradius", dx, dy, dragger_width, round(project_render_glow_falloff_radius * 100), .5, 0, no_limit * 100, 200, 1, tab.render.tbx_glow_falloff_radius, action_project_render_glow_falloff_radius)
			tab_next()
			
			tab_control_dragger()
			draw_dragger("renderglowfalloffintensity", dx, dy, dragger_width, round(project_render_glow_falloff_intensity * 100), .5, 0, no_limit * 100, 100, 1, tab.render.tbx_glow_falloff_intensity, action_project_render_glow_falloff_intensity)
			tab_next()
			
			tab_collapse_end(false)
		}
		
		tab_collapse_end()
	}
	
	// AA (FXAA)
	tab_control_switch()
	draw_button_collapse("aa", collapse_map[?"aa"], action_project_render_aa, project_render_aa, "renderaa", "renderaatip")
	tab_next()
	
	if (project_render_aa && collapse_map[?"aa"])
	{
		tab_collapse_start()
		
		tab_control_meter()
		draw_meter("renderaapower", dx, dy, dw, round(project_render_aa_power * 100), 0, 300, 100, 1, tab.render.tbx_aa_power, action_project_render_aa_power)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderaathreshold", dx, dy, dw, round(project_render_aa_threshold * 100), 0, 50, 5, 1, tab.render.tbx_aa_threshold, action_project_render_aa_threshold, "renderaathresholdtip")
		tab_next()
		
		tab_collapse_end()
	}
	
	// Global Tone Mapping, Color Grading & CAS Sharpening
	tab_control_switch()
	draw_button_collapse("tonemap", collapse_map[?"tonemap"], null, true, "rendertonemapsection")
	tab_next()
	
	if (collapse_map[?"tonemap"])
	{
		tab_collapse_start()
		
		var tmtext = text_get("rendertonemappernone");
		if (project_render_tonemapper = e_tonemapper.REINHARD)
			tmtext = text_get("rendertonemapperreinhard")
		else if (project_render_tonemapper = e_tonemapper.ACES)
			tmtext = text_get("rendertonemapperaces")
		else if (project_render_tonemapper = e_tonemapper.AGX)
			tmtext = text_get("rendertonemapperagx")
		
		tab_control_menu()
		draw_button_menu("rendertonemapper", e_menu.LIST, dx, dy, dw, 24, project_render_tonemapper, tmtext, action_project_render_tonemapper)
		tab_next()
		
		tab_control_dragger()
		draw_dragger("renderexposure", dx, dy, dragger_width, project_render_exposure, 0.01, 0.1, 4, 1, 0.01, tab.render.tbx_exposure, action_project_render_exposure)
		tab_next()
		
		tab_control_dragger()
		draw_dragger("rendergamma", dx, dy, dragger_width, project_render_gamma, 0.01, 0.5, 2.5, 1, 0.01, tab.render.tbx_gamma, action_project_render_gamma)
		tab_next()
		
		tab_control_meter()
		draw_meter("rendercontrast", dx, dy, dw, round(project_render_contrast * 100), 0, 200, 100, 1, tab.render.tbx_contrast, action_project_render_contrast)
		tab_next()
		
		tab_control_meter()
		draw_meter("rendersaturation", dx, dy, dw, round(project_render_saturation * 100), 0, 200, 100, 1, tab.render.tbx_saturation, action_project_render_saturation)
		tab_next()
		
		tab_control_meter()
		draw_meter("rendervibrance", dx, dy, dw, round(project_render_vibrance * 100), -100, 100, 0, 1, tab.render.tbx_vibrance, action_project_render_vibrance)
		tab_next()
		
		tab_control_meter()
		draw_meter("rendersharpen", dx, dy, dw, round(project_render_sharpen * 100), 0, 200, 0, 1, tab.render.tbx_sharpen, action_project_render_sharpen, "rendersharpentip")
		tab_next()
		
		tab_control_meter()
		draw_meter("rendertemperature", dx, dy, dw, round(project_render_temperature * 100), -100, 100, 0, 1, tab.render.tbx_temperature, action_project_render_temperature)
		tab_next()
		
		tab_control_meter()
		draw_meter("rendertint", dx, dy, dw, round(project_render_tint * 100), -100, 100, 0, 1, tab.render.tbx_tint, action_project_render_tint)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderliftshadows", dx, dy, dw, round(project_render_lift_shadows * 100), -100, 100, 0, 1, tab.render.tbx_lift_shadows, action_project_render_lift_shadows)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderliftmidtones", dx, dy, dw, round(project_render_lift_midtones * 100), -100, 100, 0, 1, tab.render.tbx_lift_midtones, action_project_render_lift_midtones)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderlifthighlights", dx, dy, dw, round(project_render_lift_highlights * 100), -100, 100, 0, 1, tab.render.tbx_lift_highlights, action_project_render_lift_highlights)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderglobalca", dx, dy, dw, round(project_render_global_ca * 100), 0, 100, 0, 1, tab.render.tbx_global_ca, action_project_render_global_ca)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderglobalgrain", dx, dy, dw, round(project_render_global_grain * 100), 0, 100, 0, 1, tab.render.tbx_global_grain, action_project_render_global_grain)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderglobalvignette", dx, dy, dw, round(project_render_global_vignette * 100), 0, 100, 0, 1, tab.render.tbx_global_vignette, action_project_render_global_vignette)
		tab_next()
		
		if (project_render_global_vignette > 0)
		{
			tab_control_meter()
			draw_meter("renderglobalvignetteradius", dx, dy, dw, round(project_render_global_vignette_radius * 100), 10, 150, 75, 1, tab.render.tbx_global_vignette_radius, action_project_render_global_vignette_radius)
			tab_next()
			
			tab_control_color()
			draw_button_color("renderglobalvignettecolor", dx, dy, dw, project_render_global_vignette_color, c_black, false, action_project_render_global_vignette_color)
			tab_next()
		}
		
		tab_collapse_end()
	}
	
	// Stylized / Retro Post-FX Pack
	tab_control_switch()
	draw_button_collapse("retro", collapse_map[?"retro"], action_project_render_retro, project_render_retro, "renderretro", "renderretrotip")
	tab_next()
	
	if (project_render_retro && collapse_map[?"retro"])
	{
		tab_collapse_start()
		
		tab_control_meter()
		draw_meter("renderretropixelate", dx, dy, dw, project_render_retro_pixelate, 1, 16, 1, 1, tab.render.tbx_retro_pixelate, action_project_render_retro_pixelate)
		tab_next()
		
		tab_control_switch()
		draw_switch("renderretrodither", dx, dy, project_render_retro_dither, action_project_render_retro_dither, "renderretrodithertip")
		tab_next()
		
		if (project_render_retro_dither)
		{
			tab_control_meter()
			draw_meter("renderretrocolors", dx, dy, dw, project_render_retro_colors, 2, 64, 16, 1, tab.render.tbx_retro_colors, action_project_render_retro_colors)
			tab_next()
		}
		
		tab_control_meter()
		draw_meter("renderretroscanlines", dx, dy, dw, round(project_render_retro_scanlines * 100), 0, 100, 0, 1, tab.render.tbx_retro_scanlines, action_project_render_retro_scanlines)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderretrocurvature", dx, dy, dw, round(project_render_retro_curvature * 100), 0, 100, 0, 1, tab.render.tbx_retro_curvature, action_project_render_retro_curvature)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderretrovhs", dx, dy, dw, round(project_render_retro_vhs * 100), 0, 100, 0, 1, tab.render.tbx_retro_vhs, action_project_render_retro_vhs)
		tab_next()
		
		tab_collapse_end()
	}
	
	// Motion Blur / Radial Zoom Blur / Anime Speed Lines
	tab_control_switch()
	draw_button_collapse("motion_fx", collapse_map[?"motion_fx"], action_project_render_motion_fx, project_render_motion_fx, "rendermotionfx", "rendermotionfxtip")
	tab_next()
	
	if (project_render_motion_fx && collapse_map[?"motion_fx"])
	{
		tab_collapse_start()
		
		tab_control_meter()
		draw_meter("rendermotionblur", dx, dy, dw, round(project_render_motion_blur * 100), 0, 200, 0, 1, tab.render.tbx_motion_blur, action_project_render_motion_blur)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderradialblur", dx, dy, dw, round(project_render_radial_blur * 100), 0, 100, 0, 1, tab.render.tbx_radial_blur, action_project_render_radial_blur)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderspeedlines", dx, dy, dw, round(project_render_speed_lines * 100), 0, 100, 0, 1, tab.render.tbx_speed_lines, action_project_render_speed_lines)
		tab_next()
		
		if (project_render_speed_lines > 0)
		{
			tab_control_meter()
			draw_meter("renderspeedlinesradius", dx, dy, dw, round(project_render_speed_lines_radius * 100), 10, 95, 55, 1, tab.render.tbx_speed_lines_radius, action_project_render_speed_lines_radius)
			tab_next()
			
			tab_control_color()
			draw_button_color("renderspeedlinescolor", dx, dy, dw, project_render_speed_lines_color, c_white, false, action_project_render_speed_lines_color)
			tab_next()
		}
		
		tab_collapse_end()
	}
	
	// Screen-Space Weather & Camera Lens Drops
	tab_control_switch()
	draw_button_collapse("weather_fx", collapse_map[?"weather_fx"], action_project_render_weather_fx, project_render_weather_fx, "renderweatherfx", "renderweatherfxtip")
	tab_next()
	
	if (project_render_weather_fx && collapse_map[?"weather_fx"])
	{
		tab_collapse_start()
		
		tab_control_meter()
		draw_meter("renderweatherrain", dx, dy, dw, round(project_render_weather_rain * 100), 0, 100, 0, 1, tab.render.tbx_weather_rain, action_project_render_weather_rain)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderweathersnow", dx, dy, dw, round(project_render_weather_snow * 100), 0, 100, 0, 1, tab.render.tbx_weather_snow, action_project_render_weather_snow)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderweatherwind", dx, dy, dw, round(project_render_weather_wind * 100), -100, 100, 15, 1, tab.render.tbx_weather_wind, action_project_render_weather_wind)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderweatherlensdrops", dx, dy, dw, round(project_render_weather_lens_drops * 100), 0, 100, 0, 1, tab.render.tbx_weather_lens_drops, action_project_render_weather_lens_drops)
		tab_next()
		
		tab_collapse_end()
	}
	
	// Texture filtering
	tab_control_switch()
	draw_button_collapse("texfilter", collapse_map[?"texfilter"], action_project_render_texture_filtering, project_render_texture_filtering, "rendertexturefiltering", "rendertexturefilteringtip")
	tab_next()
	
	if (project_render_texture_filtering && collapse_map[?"texfilter"])
	{
		tab_collapse_start()
		
		// Transparent block texture filtering
		tab_control_switch()
		draw_switch("rendertexturefilteringtransparentblocks", dx, dy, project_render_transparent_block_texture_filtering, action_project_render_transparent_block_texture_filtering)
		tab_next()
		
		// Texture filtering level
		tab_control_meter()
		draw_meter("rendertexturefilteringlevel", dx, dy, dw, project_render_texture_filtering_level, 0, 8, 1, 1, tab.render.tbx_texture_filtering_level, action_project_render_texture_filtering_level)
		tab_next()
		
		tab_collapse_end()
	}
	
	// Models and scenery
	tab_control_switch()
	draw_button_collapse("models_scenery", collapse_map[?"models_scenery"], null, true, "rendermodelsscenery")
	tab_next()
	
	if (collapse_map[?"models_scenery"])
	{
		tab_collapse_start()
		
		// Bending style
		tab_control_togglebutton()
		togglebutton_add("renderbendstylerealistic", null, "realistic", project_bend_style = "realistic", action_project_bend_style)
		togglebutton_add("renderbendstyleblocky", null, "blocky", project_bend_style = "blocky", action_project_bend_style)
		draw_togglebutton("renderbendstyle", dx, dy)
		tab_next()
		
		// Opaque leaves
		tab_control_switch()
		draw_switch("renderopaqueleaves", dx, dy, project_render_opaque_leaves, action_project_render_opaque_leaves)
		tab_next()
		
		// Liquid waves
		tab_control_switch()
		draw_switch("renderliquidanimation", dx, dy, project_render_liquid_animation, action_project_render_liquid_animation)
		tab_next()
		
		tab_collapse_end()
	}
	
	// Glint settings
	tab_control_switch()
	draw_button_collapse("glint", collapse_map[?"glint"], null, true, "renderglint")
	tab_next()
	
	if (collapse_map[?"glint"])
	{
		tab_collapse_start()
		
		tab_control_dragger()
		draw_dragger("renderglintspeed", dx, dy, dragger_width, round(project_render_glint_speed * 100), 1, 0, no_limit, 100, 1, tab.render.tbx_glint_speed, action_project_render_glint_speed)
		tab_next()
		
		tab_control_dragger()
		draw_dragger("renderglintstrength", dx, dy, dragger_width, round(project_render_glint_strength * 100), 1, 0, no_limit, 100, 1, tab.render.tbx_glint_strength, action_project_render_glint_strength)
		tab_next()
		
		tab_collapse_end()
	}
	
	// Default block brightness / emissive
	tab_control_dragger()
	draw_dragger("renderdefaultemissive", dx, dy, dragger_width, round(project_render_block_emissive * 100), 1, 0, no_limit, 100, 1, tab.render.tbx_block_emissive, action_project_render_block_emissive, null, true, false, "renderdefaultemissivetip")
	tab_next()
	
	tab_control(24)
	
	// Import render settings
	if (draw_button_icon("renderimport", dx, dy, 24, 24, false, icons.SETTINGS_IMPORT, null, false, "tooltipsettingsimport"))
		action_project_render_import()
	
	// Export render settings
	if (draw_button_icon("renderexport", dx + 28, dy, 24, 24, false, icons.SETTINGS_EXPORT, null, false, "tooltipsettingsexport"))
		action_project_render_export()
	
	// Set current render settings as default
	if (draw_button_icon("rendersetdefault", dx + (28 * 2), dy, 24, 24, false, icons.SETTINGS_SETDEFAULT, null, false, "tooltipsettingssetdefault"))
	{
		if (question(text_get("questionsetasdefault")))
			action_project_render_export(render_default_file)
	}
	
	// Reset render settings
	draw_button_icon("renderreset", dx + (28 * 3), dy, 24, 24, false, icons.RESET, action_project_render_reset, false, "tooltipsettingsreset")
	
	tab_next()
}
