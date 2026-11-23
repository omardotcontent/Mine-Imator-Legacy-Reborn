/// render_high_shadows()
/// @desc Classic 1.2.9 shadow and lighting pass

function render_high_shadows()
{
	var resultsurf;
	var sunout = (background_sunlight_color_final != c_black);
	var use_cache = (project_render_shadows_cache && window_state != "export_movie" && window_state != "export_image");
	var scene_hash = 0;
	
	if (use_cache)
	{
		scene_hash = round(timeline_marker * 1000) * 1.13 +
					 (setting_wind_enable ? round(background_time * 0.5) : 0) * 2.17 +
					 history_pos * 3.31 + history_amount * 4.47 +
					 ds_list_size(render_list) * 5.59 +
					 (window_busy = "rendercontrol" ? current_time : 0)
		for (var i = 0; i < ds_list_size(render_list); i++)
		{
			var rtl = render_list[|i];
			if (rtl.render_visible && rtl.shadows)
				scene_hash += (rtl.matrix_render[12] * 0.71 + rtl.matrix_render[13] * 1.19 + rtl.matrix_render[14] * 1.63 + rtl.matrix_render[0] * 2.03 + rtl.matrix_render[5] * 2.41 + rtl.value_inherit[e_value.ALPHA] * 3.11) * (i + 1)
		}
	}
	
	// Sun
	if (sunout)
	{
		// Update camera (position) if not previously initialized
		render_world_start()
		render_world_done()
		
		var sun_follow_x = cam_from[X] * background_sunlight_follow;
		var sun_follow_y = cam_from[Y] * background_sunlight_follow;
		if (use_cache)
		{
			sun_follow_x = round(sun_follow_x / 32) * 32
			sun_follow_y = round(sun_follow_y / 32) * 32
		}
		
		var sun_hash = scene_hash +
					   project_render_shadows_sun_buffer_size * 7.1 +
					   project_render_colored_shadows * 11.3 +
					   background_light_data[0] * 0.37 + background_light_data[1] * 0.53 + background_light_data[2] * 0.79 +
					   background_light_data[3] * 0.19 + background_light_data[7] * 0.23 +
					   sun_follow_x * 0.41 + sun_follow_y * 0.67;
		var colsize = min(2048, project_render_shadows_sun_buffer_size);
		var need_sun_depth = (!use_cache ||
							  !surface_exists(render_surface_sun_buffer) ||
							  surface_get_width(render_surface_sun_buffer) != project_render_shadows_sun_buffer_size ||
							  (project_render_colored_shadows && (!surface_exists(render_surface_sun_color) || surface_get_width(render_surface_sun_color) != colsize)) ||
							  abs(sun_hash - render_sun_shadow_cache_hash) > 0.0001);
		
		if (need_sun_depth)
		{
			render_sun_shadow_cache_hash = sun_hash
			
			// Depth
			render_surface_sun_buffer = surface_require(render_surface_sun_buffer, project_render_shadows_sun_buffer_size, project_render_shadows_sun_buffer_size)
			surface_set_target(render_surface_sun_buffer)
			{
				gpu_set_blendmode_ext(bm_one, bm_zero)
				draw_clear(c_white)
				render_world_start_light(
					point3D(background_light_data[0], background_light_data[1], background_light_data[2]),
					point3D(sun_follow_x, sun_follow_y, 0),
					background_light_data[3], background_light_data[7],
					45, background_sunlight_color_final
				)
				render_world(e_render_mode.HIGH_LIGHT_SUN_DEPTH)
				render_world_done()
				gpu_set_blendmode(bm_normal)
			}
			surface_reset_target()
			
			// Stained Glass / Colored Transparent Sunlight Filter Pass
			if (project_render_colored_shadows)
			{
				render_surface_sun_color = surface_require(render_surface_sun_color, colsize, colsize)
				surface_set_target(render_surface_sun_color)
				{
					draw_clear_alpha(c_white, 1)
					gpu_set_blendmode_ext(bm_zero, bm_src_color)
					render_world_start_light(
						point3D(background_light_data[0], background_light_data[1], background_light_data[2]),
						point3D(sun_follow_x, sun_follow_y, 0),
						background_light_data[3], background_light_data[7],
						45, background_sunlight_color_final
					)
					gpu_set_zwriteenable(false)
					render_world(e_render_mode.HIGH_SUN_COLOR)
					gpu_set_zwriteenable(true)
					render_world_done()
					gpu_set_blendmode(bm_normal)
				}
				surface_reset_target()
			}
		}
		else
		{
			render_world_start_light(
				point3D(background_light_data[0], background_light_data[1], background_light_data[2]),
				point3D(sun_follow_x, sun_follow_y, 0),
				background_light_data[3], background_light_data[7],
				45, background_sunlight_color_final
			)
			render_world_done()
		}
	}
	
	// Create initial shadow surface from sun (or night pass)
	render_surface[1] = surface_require(render_surface[1], render_width, render_height)
	resultsurf = render_surface[1]
	surface_set_target(resultsurf)
	{
		draw_clear(c_white)
		render_world_start()
		render_world(sunout ? e_render_mode.HIGH_LIGHT_SUN : e_render_mode.HIGH_LIGHT_NIGHT)
		render_world_done()
	}
	surface_reset_target()
	
	// Get number of lights (to divide brightness by)
	render_light_amount = 0
	var shadow_point_count = 0;
	var shadow_spot_count = 0;
	with (obj_timeline)
	{
		if (render_visible && (type = e_tl_type.POINT_LIGHT || type = e_tl_type.SPOT_LIGHT))
		{
			render_light_amount++
			if (type = e_tl_type.POINT_LIGHT && shadows)
				shadow_point_count++
			else if (type = e_tl_type.SPOT_LIGHT && shadows)
				shadow_spot_count++
		}
	}
	
	// User placed lights
	with (obj_timeline)
	{
		var resultsurftemp;
		
		if (!render_visible)
			continue
		
		if (type = e_tl_type.POINT_LIGHT)
		{
			// If shadowless, add to shadowless point light list and continue
			if (!shadows)
			{
				ds_list_add(render_shadowless_point_list, id)
				continue
			}
			
			var pt_hash = scene_hash + id * 13.7 + world_pos[X] * 0.43 + world_pos[Y] * 0.61 + world_pos[Z] * 0.89 + value[e_value.LIGHT_RANGE] * 1.37 + app.project_render_shadows_point_buffer_size * 5.1;
			var pt_valid = (use_cache && shadow_point_count = 1 && abs(pt_hash - render_point_shadow_cache_hash) <= 0.0001);
			if (pt_valid)
			{
				for (var d = e_dir.EAST; d < e_dir.amount; d++)
				{
					if (!surface_exists(render_surface_point_buffer[d]) || surface_get_width(render_surface_point_buffer[d]) != app.project_render_shadows_point_buffer_size)
					{
						pt_valid = false
						break
					}
				}
			}
			
			if (!pt_valid)
			{
				render_point_shadow_cache_hash = pt_hash
				// Depth (6 cubemap faces)
				for (var d = e_dir.EAST; d < e_dir.amount; d++)
				{
					var look = dir_get_vec3(d);
					if (d = e_dir.DOWN || d = e_dir.UP)
						look[Y] -= 0.0001
					
					render_surface_point_buffer[d] = surface_require(render_surface_point_buffer[d], app.project_render_shadows_point_buffer_size, app.project_render_shadows_point_buffer_size)
					surface_set_target(render_surface_point_buffer[d])
					{
						gpu_set_blendmode_ext(bm_one, bm_zero)
						draw_clear(c_white)
						render_world_start_light(world_pos, point3D_add(world_pos, look), 1, value[e_value.LIGHT_RANGE], 90, value[e_value.LIGHT_COLOR], value[e_value.LIGHT_FADE_SIZE], 0, value[e_value.LIGHT_STRENGTH])
						render_world(e_render_mode.HIGH_LIGHT_POINT_DEPTH)
						render_world_done()
						gpu_set_blendmode(bm_normal)
					}
					surface_reset_target()
				}
			}
			else
			{
				var look = dir_get_vec3(e_dir.DOWN);
				look[Y] -= 0.0001
				render_world_start_light(world_pos, point3D_add(world_pos, look), 1, value[e_value.LIGHT_RANGE], 90, value[e_value.LIGHT_COLOR], value[e_value.LIGHT_FADE_SIZE], 0, value[e_value.LIGHT_STRENGTH])
				render_world_done()
			}
			
			// Shadows
			with (app)
			{
				render_surface[2] = surface_require(render_surface[2], render_width, render_height)
				resultsurftemp = render_surface[2]
				surface_set_target(resultsurftemp)
				{
					draw_clear(c_white)
					render_world_start()
					render_world(e_render_mode.HIGH_LIGHT_POINT)
					render_world_done()
				}
				surface_reset_target()
			}
		}
		else if (type = e_tl_type.SPOT_LIGHT)
		{
			var lookat = point3D_mul_matrix(point3D(0.0001, 1, 0), matrix);
			var sp_hash = scene_hash + id * 17.3 + world_pos[X] * 0.43 + world_pos[Y] * 0.61 + world_pos[Z] * 0.89 + lookat[X] * 0.53 + lookat[Y] * 0.71 + lookat[Z] * 0.97 + value[e_value.LIGHT_RANGE] * 1.37 + value[e_value.LIGHT_SPOT_RADIUS] * 1.91 + app.project_render_shadows_spot_buffer_size * 5.1;
			var sp_valid = (use_cache && shadow_spot_count = 1 && surface_exists(render_surface_spot_buffer) && surface_get_width(render_surface_spot_buffer) = app.project_render_shadows_spot_buffer_size && abs(sp_hash - render_spot_shadow_cache_hash) <= 0.0001);
			
			if (!sp_valid)
			{
				render_spot_shadow_cache_hash = sp_hash
				// Depth
				render_surface_spot_buffer = surface_require(render_surface_spot_buffer, app.project_render_shadows_spot_buffer_size, app.project_render_shadows_spot_buffer_size)
				surface_set_target(render_surface_spot_buffer)
				{
					gpu_set_blendmode_ext(bm_one, bm_zero)
					draw_clear(c_white)
					
					render_world_start_light(world_pos, lookat, 1, value[e_value.LIGHT_RANGE], value[e_value.LIGHT_SPOT_RADIUS], value[e_value.LIGHT_COLOR], value[e_value.LIGHT_FADE_SIZE], value[e_value.LIGHT_SPOT_SHARPNESS], value[e_value.LIGHT_STRENGTH])
					
					// Only render depth for shadows if the light source isn't shadowless
					if (shadows)
						render_world(e_render_mode.HIGH_LIGHT_SPOT_DEPTH)
					
					render_world_done()
					gpu_set_blendmode(bm_normal)
				}
				surface_reset_target()
			}
			else
			{
				render_world_start_light(world_pos, lookat, 1, value[e_value.LIGHT_RANGE], value[e_value.LIGHT_SPOT_RADIUS], value[e_value.LIGHT_COLOR], value[e_value.LIGHT_FADE_SIZE], value[e_value.LIGHT_SPOT_SHARPNESS], value[e_value.LIGHT_STRENGTH])
				render_world_done()
			}
			
			// Shadows
			with (app)
			{
				render_surface[2] = surface_require(render_surface[2], render_width, render_height)
				resultsurftemp = render_surface[2]
				surface_set_target(resultsurftemp)
				{
					draw_clear(c_white)
					render_world_start()
					render_world(e_render_mode.HIGH_LIGHT_SPOT)
					render_world_done()
				}
				surface_reset_target()
			}
		}
		else
			continue
		
		// Add to final shadow surface
		if (surface_exists(resultsurf))
		{
			surface_set_target(resultsurf)
			{
				gpu_set_blendmode(bm_add)
				draw_surface_exists(resultsurftemp, 0, 0)
				gpu_set_blendmode(bm_normal)
			}
			surface_reset_target()
		}
	}
	
	// Shadowless point lights
	if (ds_list_size(render_shadowless_point_list) > 0)
	{
		var resultsurftemp, remaininglights, groupsdone;
		remaininglights = ds_list_size(render_shadowless_point_list)
		groupsdone = 0
		render_shadowless_point_amount = 0
		
		while (remaininglights > 0)
		{
			for (var l = 0; l < 63; l++)
			{
				if (remaininglights = 0)
					break
				
				var light = render_shadowless_point_list[| l + (groupsdone * 63)];
				var strength = light.value[e_value.LIGHT_STRENGTH];
				
				render_shadowless_point_data[render_shadowless_point_amount * 8 + 0] = light.world_pos[X]
				render_shadowless_point_data[render_shadowless_point_amount * 8 + 1] = light.world_pos[Y]
				render_shadowless_point_data[render_shadowless_point_amount * 8 + 2] = light.world_pos[Z]
				render_shadowless_point_data[render_shadowless_point_amount * 8 + 3] = light.value[e_value.LIGHT_RANGE]
				render_shadowless_point_data[render_shadowless_point_amount * 8 + 4] = (color_get_red(light.value[e_value.LIGHT_COLOR]) / 255) * strength
				render_shadowless_point_data[render_shadowless_point_amount * 8 + 5] = (color_get_green(light.value[e_value.LIGHT_COLOR]) / 255) * strength
				render_shadowless_point_data[render_shadowless_point_amount * 8 + 6] = (color_get_blue(light.value[e_value.LIGHT_COLOR]) / 255) * strength
				render_shadowless_point_data[render_shadowless_point_amount * 8 + 7] = light.value[e_value.LIGHT_FADE_SIZE]
				render_shadowless_point_amount++
				remaininglights--
			}
			
			// Render lights
			render_surface[2] = surface_require(render_surface[2], render_width, render_height)
			resultsurftemp = render_surface[2]
			surface_set_target(resultsurftemp)
			{
				draw_clear(c_white)
				render_world_start()
				render_world(e_render_mode.HIGH_LIGHT_POINT_SHADOWLESS)
				render_world_done()
			}
			surface_reset_target()
			
			// Add to final shadow surface
			if (surface_exists(resultsurf))
			{
				surface_set_target(resultsurf)
				{
					gpu_set_blendmode(bm_add)
					draw_surface_exists(resultsurftemp, 0, 0)
					gpu_set_blendmode(bm_normal)
				}
				surface_reset_target()
			}
			groupsdone++
			render_shadowless_point_amount = 0
		}
		
		ds_list_clear(render_shadowless_point_list)
	}
	
	gpu_set_texfilter(false)
	
	if (render_pass = e_render_pass.SHADOWS)
		render_pass_surf = surface_duplicate(resultsurf)
	
	return resultsurf
}
