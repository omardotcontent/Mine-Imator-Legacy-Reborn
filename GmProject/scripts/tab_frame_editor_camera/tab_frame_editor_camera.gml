/// tab_frame_editor_camera()

function tab_frame_editor_camera()
{
	var capwid, text;
	
	context_menu_group_temp = e_context_group.CAMERA
	
	// Camera size (Advanced mode only)
	if (setting_advanced_mode)
	{
		if (tl_edit.value[e_value.CAM_SIZE_USE_PROJECT]) // Use project settings
		{
			tab.camera.video_template = null
			text = text_get("frameeditorcameravideosizeuseproject")
		}
		else
		{
			if (tab.camera.video_template = null)
				tab.camera.video_template = find_videotemplate(tl_edit.value[e_value.CAM_WIDTH], tl_edit.value[e_value.CAM_HEIGHT])
			
			if (tab.camera.video_template > 0) // Use template
				text = text_get("projectvideosizetemplate" + tab.camera.video_template.name) + " (" + string(tab.camera.video_template.width) + "x" + string(tab.camera.video_template.height) + ")"
			else // Use custom
				text = text_get("projectvideosizecustom")
		}
		
		tab_control_menu()
		draw_button_menu("frameeditorcameravideosize", e_menu.LIST, dx, dy, dw, 24, tl_edit.value[e_value.CAM_SIZE_USE_PROJECT] ? null : tab.camera.video_template, text, action_tl_frame_cam_video_template)
		tab_next()
		
		// Custom
		if (tab.camera.video_template = 0)
		{
			textfield_group_add("frameeditorcameravideosizecustomwidth", tl_edit.value[e_value.CAM_WIDTH], 1280, action_tl_frame_cam_width, X, tab.camera.tbx_video_size_custom_width, null, 1)
			textfield_group_add("frameeditorcameravideosizecustomheight", tl_edit.value[e_value.CAM_HEIGHT], 720, action_tl_frame_cam_height, X, tab.camera.tbx_video_size_custom_height, null, 1)
			
			tab_control_textfield_group()
			draw_textfield_group("frameeditorcameravideosizecustom", dx, dy, dw, 1, 1, no_limit, 1)
			tab_next()
			
			tab_control_switch()
			draw_switch("frameeditorcameravideosizecustomkeepaspectratio", dx, dy, tl_edit.value[e_value.CAM_SIZE_KEEP_ASPECT_RATIO], action_tl_frame_cam_size_keep_aspect_ratio)
			tab_next()
			
			dy += 8
		}
	}
	
	// FOV
	tab_control_dragger()
	draw_dragger("frameeditorcamerafov", dx, dy, dragger_width, tl_edit.value[e_value.CAM_FOV], 1, 1, 170, 45, 0, tab.camera.tbx_fov, action_tl_frame_cam_fov)
	tab_next()
	
	// Advanced mode only
	if (setting_advanced_mode)
	{
		// Aperture
		tab_control_switch()
		draw_button_collapse("aperture", collapse_map[?"aperture"], null, true, "frameeditorcameraaperture", "frameeditorcameraaperturetip")
		tab_next()
		
		if (collapse_map[?"aperture"])
		{
			tab_collapse_start()
			
			// Blade amount
			tab_control_meter()
			draw_meter("frameeditorcamerabladeamount", dx, dy, dw, tl_edit.value[e_value.CAM_BLADE_AMOUNT], 0, 16, 0, 1, tab.camera.tbx_blade_amount, action_tl_frame_cam_blade_amount)
			tab_next()
			
			// Blade angle
			tab_control_dragger()
			draw_dragger("frameeditorcamerabladeangle", dx, dy, dragger_width, tl_edit.value[e_value.CAM_BLADE_ANGLE], 1, -no_limit, no_limit, 0, 0.1, tab.camera.tbx_blade_angle, action_tl_frame_cam_blade_angle)
			tab_next()
			
			tab_collapse_end()
		}
	}
	
	// Light management
	tab_control_switch()
	draw_button_collapse("light_management_cam", collapse_map[?"light_management_cam"], action_tl_frame_cam_light_management, tl_edit.value[e_value.CAM_LIGHT_MANAGEMENT], "frameeditorcameralightmanagement")
	tab_next()
	
	if (tl_edit.value[e_value.CAM_LIGHT_MANAGEMENT] && collapse_map[?"light_management_cam"])
	{
		tab_collapse_start()
		
		// Tonemapper
		switch (tl_edit.value[e_value.CAM_TONEMAPPER])
		{
			case e_tonemapper.REINHARD:
				text = text_get("rendertonemapperreinhard")
				break;
			case e_tonemapper.ACES:
				text = text_get("rendertonemapperaces")
				break;
			case e_tonemapper.AGX:
				text = text_get("rendertonemapperagx")
				break;
			default:
				text = text_get("rendertonemappernone")
				break;
		}
		
		tab_control_menu()
		draw_button_menu("frameeditorcameratonemapper", e_menu.LIST, dx, dy, dw, 24, tl_edit.value[e_value.CAM_TONEMAPPER], text, action_tl_frame_cam_tonemapper)
		tab_next()
		
		// Exposure
		tab_control_dragger()
		draw_dragger("frameeditorcameraexposure", dx, dy, dragger_width, tl_edit.value[e_value.CAM_EXPOSURE], 0.01, 0, no_limit, 1, 0.01, tab.camera.tbx_exposure, action_tl_frame_cam_exposure)
		tab_next()
		
		// Gamma
		tab_control_dragger()
		draw_dragger("frameeditorcameragamma", dx, dy, dragger_width, tl_edit.value[e_value.CAM_GAMMA], 0.01, 0, no_limit, 1, 0.01, tab.camera.tbx_gamma, action_tl_frame_cam_gamma)
		tab_next()
		
		tab_collapse_end()
	}
	
	// Rotate around point
	tab_control_switch()
	draw_button_collapse("rotatepoint", collapse_map[?"rotatepoint"], action_tl_frame_cam_rotate, tl_edit.value[e_value.CAM_ROTATE], "frameeditorcamerarotate")
	tab_next()

	if (tl_edit.value[e_value.CAM_ROTATE] && collapse_map[?"rotatepoint"])
	{
		tab_collapse_start()
		
		// XY / Z angle wheels
		var snapval = (dragger_snap ? setting_snap_size_rotation : 0.1);
		
		tab_control_wheel()
		draw_wheel("frameeditorcamerarotateanglexywheel", dx + floor(dw * 0.25), dy + 24, c_aqua, tl_edit.value[e_value.CAM_ROTATE_ANGLE_XY], -no_limit, no_limit, 0, snapval, tab.camera.tbx_rotate_angle_xy, action_tl_frame_cam_rotate_angle_xy)
		draw_wheel("frameeditorcamerarotateanglezwheel", dx + floor(dw * 0.75), dy + 24, c_aqua, tl_edit.value[e_value.CAM_ROTATE_ANGLE_Z], -no_limit, no_limit, 0, snapval, tab.camera.tbx_rotate_angle_z, action_tl_frame_cam_rotate_angle_z)
		tab_next()
		
		// Textboxes
		textfield_group_add("frameeditorcamerarotateanglexy", tl_edit.value[e_value.CAM_ROTATE_ANGLE_XY], 0, action_tl_frame_cam_rotate_angle_xy, axis_edit, tab.camera.tbx_rotate_angle_xy, null, .1, -no_limit, no_limit)
		textfield_group_add("frameeditorcamerarotateanglez", tl_edit.value[e_value.CAM_ROTATE_ANGLE_Z], 0, action_tl_frame_cam_rotate_angle_z, axis_edit, tab.camera.tbx_rotate_angle_z, null, .1, -no_limit, no_limit)
		
		tab_control_textfield_group()
		draw_textfield_group("frameeditorcamerarotateangle", dx, dy, dw, 0.1, 0, 0, snapval)
		tab_next()
		
		// Distance
		tab_control_dragger()
		draw_dragger("frameeditorcamerarotatedistance", dx, dy, dragger_width, tl_edit.value[e_value.CAM_ROTATE_DISTANCE], 1, 1, no_limit, 100, 0, tab.camera.tbx_rotate_distance, action_tl_frame_cam_rotate_distance)
		tab_next()
		
		// Look at
		tab_control_switch()
		draw_switch("frameeditorcamerarotatelookatpoint", dx, dy, tab.camera.look_at_rotate, action_tl_frame_look_at_rotate)
		tab_next()
		
		tab_collapse_end()
	}
	
	// Camera shake (Advanced mode only)
	if (setting_advanced_mode)
	{
		tab_control_switch()
		draw_button_collapse("camshake", collapse_map[?"camshake"], action_tl_frame_cam_shake, tl_edit.value[e_value.CAM_SHAKE], "frameeditorcameracamerashake")
		tab_next()
		
		if (tl_edit.value[e_value.CAM_SHAKE] && collapse_map[?"camshake"])
		{
			tab_collapse_start()
			
			// Mode
			tab_control_togglebutton()
			togglebutton_add("frameeditorcameracamerashakerotational", null, 0, tl_edit.value[e_value.CAM_SHAKE_MODE] = 0, action_tl_frame_cam_shake_mode)
			togglebutton_add("frameeditorcameracamerashakepositional", null, 1, tl_edit.value[e_value.CAM_SHAKE_MODE] = 1, action_tl_frame_cam_shake_mode)
			draw_togglebutton("frameeditorcameracamerashakemode", dx, dy)
			tab_next()
			
			// Strength
			axis_edit = X
			textfield_group_add("frameeditorcameracamerashakestrengthx", round(tl_edit.value[e_value.CAM_SHAKE_STRENGTH_X] * 100), 100, action_tl_frame_cam_shake_strength, axis_edit, tab.camera.tbx_shake_strength_x, null, 1, 0, no_limit)
			axis_edit = (setting_z_is_up ? Y : Z)
			textfield_group_add("frameeditorcameracamerashakestrengthy", round(tl_edit.value[e_value.CAM_SHAKE_STRENGTH_X + axis_edit] * 100), 100, action_tl_frame_cam_shake_strength, axis_edit, tab.camera.tbx_shake_strength_y, null, 1, 0, no_limit)
			axis_edit = (setting_z_is_up ? Z : Y)
			textfield_group_add("frameeditorcameracamerashakestrengthz", round(tl_edit.value[e_value.CAM_SHAKE_STRENGTH_X + axis_edit] * 100), 100, action_tl_frame_cam_shake_strength, axis_edit, tab.camera.tbx_shake_strength_z, null, 1, 0, no_limit)
			
			tab_control_textfield_group(true)
			draw_textfield_group("frameeditorcameracamerashakestrength", dx, dy, dw, null, null, null, .01, true, true, 1)
			tab_next()
			
			// Speed
			axis_edit = X
			textfield_group_add("frameeditorcameracamerashakespeedx", round(tl_edit.value[e_value.CAM_SHAKE_SPEED_X] * 100), 100, action_tl_frame_cam_shake_speed, axis_edit, tab.camera.tbx_shake_speed_x, null, 1, 0, no_limit)
			axis_edit = (setting_z_is_up ? Y : Z)
			textfield_group_add("frameeditorcameracamerashakespeedy", round(tl_edit.value[e_value.CAM_SHAKE_SPEED_X + axis_edit] * 100), 100, action_tl_frame_cam_shake_speed, axis_edit, tab.camera.tbx_shake_speed_y, null, 1, 0, no_limit)
			axis_edit = (setting_z_is_up ? Z : Y)
			textfield_group_add("frameeditorcameracamerashakespeedz", round(tl_edit.value[e_value.CAM_SHAKE_SPEED_X + axis_edit] * 100), 100, action_tl_frame_cam_shake_speed, axis_edit, tab.camera.tbx_shake_speed_z, null, 1, 0, no_limit)
			
			tab_control_textfield_group(true)
			draw_textfield_group("frameeditorcameracamerashakespeed", dx, dy, dw, null, null, null, .01, true, true, 1)
			tab_next()
			
			tab_collapse_end()
		}
	}
	
	// Depth of Field
	tab_control_switch()
	draw_button_collapse("dof", collapse_map[?"dof"], action_tl_frame_cam_dof, tl_edit.value[e_value.CAM_DOF], "frameeditorcameradof")
	tab_next()
	
	if (tl_edit.value[e_value.CAM_DOF] && collapse_map[?"dof"])
	{
		tab_collapse_start()
		
		tab_control_dragger()
		draw_dragger("frameeditorcameradofdepth", dx, dy, dragger_width, tl_edit.value[e_value.CAM_DOF_DEPTH], max(0.5, tl_edit.value[e_value.CAM_DOF_DEPTH] / 50), 0, project_render_distance, 0, 0, tab.camera.tbx_dof_depth, action_tl_frame_cam_dof_depth)
		tab_next()
		
		tab_control_dragger()
		draw_dragger("frameeditorcameradofrange", dx, dy, dragger_width, tl_edit.value[e_value.CAM_DOF_RANGE], max(0.5, tl_edit.value[e_value.CAM_DOF_RANGE] / 50), 0, no_limit, 200, 0, tab.camera.tbx_dof_range, action_tl_frame_cam_dof_range)
		tab_next()
		
		tab_control_dragger()
		draw_dragger("frameeditorcameradoffadesize", dx, dy, dragger_width, tl_edit.value[e_value.CAM_DOF_FADE_SIZE], 2, 0, no_limit, 100, 0, tab.camera.tbx_dof_fade_size, action_tl_frame_cam_dof_fade_size)
		tab_next()
		
		tab_control_meter()
		draw_meter("frameeditorcameradofblursize", dx, dy, dw, tl_edit.value[e_value.CAM_DOF_BLUR_SIZE] * 100, 0, 10, 1, .01, tab.camera.tbx_dof_blur_size, action_tl_frame_cam_dof_blur_size)
		tab_next()
		
		if (setting_advanced_mode)
		{
			tab_control_meter()
			draw_meter("frameeditorcameradofblurratio", dx, dy, dw, round(tl_edit.value[e_value.CAM_DOF_BLUR_RATIO] * 100), 0, 100, 0, 1, tab.camera.tbx_dof_blur_ratio, action_tl_frame_cam_dof_blur_ratio)
			tab_next()
			
			tab_control_meter()
			draw_meter("frameeditorcameradofbias", dx, dy, dw, round(tl_edit.value[e_value.CAM_DOF_BIAS] * 10), 0, 100, 0, 1, tab.camera.tbx_dof_bias, action_tl_frame_cam_dof_bias)
			tab_next()
			
			tab_control_meter()
			draw_meter("frameeditorcameradofgain", dx, dy, dw, round(tl_edit.value[e_value.CAM_DOF_GAIN] * 100), 0, 200, 0, 1, tab.camera.tbx_dof_gain, action_tl_frame_cam_dof_gain)
			tab_next()
			
			tab_control_meter()
			draw_meter("frameeditorcameradofthreshold", dx, dy, dw, round(tl_edit.value[e_value.CAM_DOF_THRESHOLD] * 100), 0, 100, 0, 1, tab.camera.tbx_dof_threshold, action_tl_frame_cam_dof_threshold)
			tab_next()
			
			tab_control_switch()
			draw_button_collapse("dof_fringe", collapse_map[?"dof_fringe"], action_tl_frame_cam_dof_fringe, tl_edit.value[e_value.CAM_DOF_FRINGE], "frameeditorcameradoffringe")
			tab_next()
			
			if (tl_edit.value[e_value.CAM_DOF_FRINGE] && collapse_map[?"dof_fringe"])
			{
				tab_collapse_start()
				
				var snapval, capwid;
				snapval = (dragger_snap ? setting_snap_size_rotation : 0.1)
				
				// Wheels
				if (!app.panel_compact)
				{
					tab_control_wheel()
					axis_edit = X
					draw_wheel("frameeditorcameradoffringeangleredwheel", floor(dx + dw/6), dy + 24, c_axisred, tl_edit.value[e_value.CAM_DOF_FRINGE_ANGLE_RED], -no_limit, no_limit, tl_edit.value_default[e_value.CAM_DOF_FRINGE_ANGLE_RED], snapval, tab.camera.tbx_dof_fringe_angle_red, action_tl_frame_cam_dof_fringe_angle)
					axis_edit = Y
					draw_wheel("frameeditorcameradoffringeanglegreenwheel", floor(dx + dw/2), dy + 24, c_axisgreen, tl_edit.value[e_value.CAM_DOF_FRINGE_ANGLE_GREEN], -no_limit, no_limit, tl_edit.value_default[e_value.CAM_DOF_FRINGE_ANGLE_GREEN], snapval, tab.camera.tbx_dof_fringe_angle_green, action_tl_frame_cam_dof_fringe_angle)
					axis_edit = Z
					draw_wheel("frameeditorcameradoffringeanglebluewheel", floor(dx + dw - dw/6), dy + 24, c_axisblue, tl_edit.value[e_value.CAM_DOF_FRINGE_ANGLE_BLUE], -no_limit, no_limit, tl_edit.value_default[e_value.CAM_DOF_FRINGE_ANGLE_BLUE], snapval, tab.camera.tbx_dof_fringe_angle_blue, action_tl_frame_cam_dof_fringe_angle)
					tab_next()
				}
				
				// Textboxes
				axis_edit = X
				textfield_group_add("frameeditorcameradoffringeanglered", tl_edit.value[e_value.CAM_DOF_FRINGE_ANGLE_RED], tl_edit.value_default[e_value.CAM_DOF_FRINGE_ANGLE_RED], action_tl_frame_cam_dof_fringe_angle, axis_edit, tab.camera.tbx_dof_fringe_angle_red)
				axis_edit = Y
				textfield_group_add("frameeditorcameradoffringeanglegreen", tl_edit.value[e_value.CAM_DOF_FRINGE_ANGLE_GREEN], tl_edit.value_default[e_value.CAM_DOF_FRINGE_ANGLE_GREEN], action_tl_frame_cam_dof_fringe_angle, axis_edit, tab.camera.tbx_dof_fringe_angle_green)
				axis_edit = Z
				textfield_group_add("frameeditorcameradoffringeangleblue", tl_edit.value[e_value.CAM_DOF_FRINGE_ANGLE_BLUE], tl_edit.value_default[e_value.CAM_DOF_FRINGE_ANGLE_BLUE], action_tl_frame_cam_dof_fringe_angle, axis_edit, tab.camera.tbx_dof_fringe_angle_blue)
				
				tab_control_textfield_group()
				draw_textfield_group("frameeditorcameradoffringeangle", dx, dy, dw, 0.1, -no_limit, no_limit, snapval, false, true, 3)
				tab_next()
				
				// Offset
				axis_edit = X
				textfield_group_add("frameeditorcameradoffringered", round(tl_edit.value[e_value.CAM_DOF_FRINGE_RED] * 100), 100, action_tl_frame_cam_dof_fringe_red, axis_edit, tab.camera.tbx_dof_fringe_red)
				axis_edit = Y
				textfield_group_add("frameeditorcameradoffringegreen", round(tl_edit.value[e_value.CAM_DOF_FRINGE_GREEN] * 100), 100, action_tl_frame_cam_dof_fringe_green, axis_edit, tab.camera.tbx_dof_fringe_green)
				axis_edit = Z
				textfield_group_add("frameeditorcameradoffringeblue", round(tl_edit.value[e_value.CAM_DOF_FRINGE_BLUE] * 100), 100, action_tl_frame_cam_dof_fringe_blue, axis_edit, tab.camera.tbx_dof_fringe_blue)
				
				tab_control_textfield_group(true)
				draw_textfield_group("frameeditorcameradoffringeoffset", dx, dy, dw, 1, 0, no_limit, 1, true, true, 3)
				tab_next()
				
				tab_collapse_end(false)
			}
		}
		
		tab_collapse_end()
	}
	
	// Bloom
	tab_control_switch()
	draw_button_collapse("bloom", collapse_map[?"bloom"], action_tl_frame_cam_bloom, tl_edit.value[e_value.CAM_BLOOM], "frameeditorcamerabloom")
	tab_next()
	
	if (tl_edit.value[e_value.CAM_BLOOM] && collapse_map[?"bloom"])
	{
		tab_collapse_start()
		
		tab_control_dragger()
		draw_dragger("frameeditorcamerabloomradius", dx, dy, dragger_width, round(tl_edit.value[e_value.CAM_BLOOM_RADIUS] * 100), .1, 0, no_limit, 100, 1, tab.camera.tbx_bloom_radius, action_tl_frame_cam_bloom_radius)
		tab_next()
		
		tab_control_dragger()
		draw_dragger("frameeditorcamerabloomintensity", dx, dy, dragger_width, round(tl_edit.value[e_value.CAM_BLOOM_INTENSITY] * 100), .1, 0, no_limit, 40, 1, tab.camera.tbx_bloom_intensity, action_tl_frame_cam_bloom_intensity)
		tab_next()
		
		tab_control_meter()
		draw_meter("frameeditorcamerabloomthreshold", dx, dy, dw, round(tl_edit.value[e_value.CAM_BLOOM_THRESHOLD] * 100), 0, 100, 85, 1, tab.camera.tbx_bloom_threshold, action_tl_frame_cam_bloom_threshold)
		tab_next()
		
		// Advanced mode only
		if (setting_advanced_mode)
		{
			tab_control_meter()
			draw_meter("frameeditorcamerabloomratio", dx, dy, dw, round(tl_edit.value[e_value.CAM_BLOOM_RATIO] * 100), 0, 100, 0, 1, tab.camera.tbx_bloom_ratio, action_tl_frame_cam_bloom_ratio)
			tab_next()
			
			tab_control_color()
			draw_button_color("frameeditorcamerabloomblend", dx, dy, dw, tl_edit.value[e_value.CAM_BLOOM_BLEND], c_white, false, action_tl_frame_cam_bloom_blend)
			tab_next()
		}
		
		tab_collapse_end()
	}
	
	// Lens dirt (Advanced mode only)
	if (setting_advanced_mode)
	{
		tab_control_switch()
		draw_button_collapse("lensdirt", collapse_map[?"lensdirt"], action_tl_frame_cam_lens_dirt, tl_edit.value[e_value.CAM_LENS_DIRT], "frameeditorcameralensdirt")
		tab_next()
		
		if (tl_edit.value[e_value.CAM_LENS_DIRT] && collapse_map[?"lensdirt"])
		{
			tab_collapse_start()
			
			// Lens dirt texture(TEXTURE_OBJ)
			var texobj, tex;
			texobj = tl_edit.value[e_value.TEXTURE_OBJ]
			tex = null
			
			var text;
			
			if (texobj != null)
				text = texobj.display_name
			else
				text = text_get("listnone")
			
			if (texobj = null)
				text = text_get("listdefault", text)
			
			if (texobj != null && texobj.type != e_tl_type.CAMERA) // Don't preview cameras
				tex = texobj.texture
			
			tab_control_menu(ui_large_height)
			draw_button_menu("frameeditorcameralensdirttexture", e_menu.LIST, dx, dy, dw, ui_large_height, tl_edit.value[e_value.TEXTURE_OBJ], text, action_tl_frame_texture_obj, false, tex)
			tab_next()
			
			// Affected by bloom
			tab_control_switch()
			draw_switch("frameeditorcameralensdirtbloom", dx, dy, tl_edit.value[e_value.CAM_LENS_DIRT_BLOOM], action_tl_frame_cam_lens_dirt_bloom)
			tab_next()
			
			// Affected by glow
			tab_control_switch()
			draw_switch("frameeditorcameralensdirtglow", dx, dy, tl_edit.value[e_value.CAM_LENS_DIRT_GLOW], action_tl_frame_cam_lens_dirt_glow)
			tab_next()
			
			// Radius
			tab_control_meter()
			draw_meter("frameeditorcameralensdirtradius", dx, dy, dw, round(tl_edit.value[e_value.CAM_LENS_DIRT_RADIUS] * 100), 0, 300, 50, 1, tab.camera.tbx_lens_dirt_radius, action_tl_frame_cam_lens_dirt_radius)
			tab_next()
			
			// Intensity
			tab_control_meter()
			draw_meter("frameeditorcameralensdirtintensity", dx, dy, dw, round(tl_edit.value[e_value.CAM_LENS_DIRT_INTENSITY] * 100), 0, 200, 80, 1, tab.camera.tbx_lens_dirt_intensity, action_tl_frame_cam_lens_dirt_intensity)
			tab_next()
			
			// Power
			tab_control_meter()
			draw_meter("frameeditorcameralensdirtpower", dx, dy, dw, round(tl_edit.value[e_value.CAM_LENS_DIRT_POWER] * 100), 100, 500, 150, 1, tab.camera.tbx_lens_dirt_power, action_tl_frame_cam_lens_dirt_power)
			tab_next()
			
			tab_collapse_end()
		}
	}
	
	// Color correction
	tab_control_switch()
	draw_button_collapse("clrcor", collapse_map[?"clrcor"], action_tl_frame_cam_clrcor, tl_edit.value[e_value.CAM_COLOR_CORRECTION], "frameeditorcameracolorcorrection")
	tab_next()
	
	if (tl_edit.value[e_value.CAM_COLOR_CORRECTION] && collapse_map[?"clrcor"])
	{
		tab_collapse_start()
		
		tab_control_dragger()
		draw_dragger("frameeditorcameracolorcorrectioncontrast", dx, dy, dragger_width, round(tl_edit.value[e_value.CAM_CONTRAST] * 100), .1, 0, no_limit * 100, 0, 1, tab.camera.tbx_contrast, action_tl_frame_cam_clrcor_contrast)
		tab_next()
		
		tab_control_dragger()
		draw_dragger("frameeditorcameracolorcorrectionbrightness", dx, dy, dragger_width, round(tl_edit.value[e_value.CAM_BRIGHTNESS] * 100), .1, -no_limit * 100, no_limit * 100, 0, 1, tab.camera.tbx_brightness, action_tl_frame_cam_clrcor_brightness)
		tab_next()
		
		tab_control_dragger()
		draw_dragger("frameeditorcameracolorcorrectionsaturation", dx, dy, dragger_width, round(tl_edit.value[e_value.CAM_SATURATION] * 100), .1, 0, no_limit * 100, 100, 1, tab.camera.tbx_saturation, action_tl_frame_cam_clrcor_saturation)
		tab_next()
		
		tab_control_dragger()
		draw_dragger("frameeditorcameracolorcorrectionvibrance", dx, dy, dragger_width, round(tl_edit.value[e_value.CAM_VIBRANCE] * 100), .1, 0, no_limit * 100, 0, 1, tab.camera.tbx_vibrance, action_tl_frame_cam_clrcor_vibrance)
		tab_next()
		
		tab_control_color()
		draw_button_color("frameeditorcameracolorcorrectioncolorburn", dx, dy, dw, tl_edit.value[e_value.CAM_COLOR_BURN], c_white, false, action_tl_frame_cam_clrcor_color_burn)
		tab_next()
		
		tab_control_meter()
		draw_meter("rendertemperature", dx, dy, dw, round(tl_edit.value[e_value.CAM_TEMPERATURE] * 100), -100, 100, 0, 1, tab.camera.tbx_temperature, action_tl_frame_cam_clrcor_temperature)
		tab_next()
		
		tab_control_meter()
		draw_meter("rendertint", dx, dy, dw, round(tl_edit.value[e_value.CAM_TINT] * 100), -100, 100, 0, 1, tab.camera.tbx_tint, action_tl_frame_cam_clrcor_tint)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderliftshadows", dx, dy, dw, round(tl_edit.value[e_value.CAM_LIFT_SHADOWS] * 100), -100, 100, 0, 1, tab.camera.tbx_lift_shadows, action_tl_frame_cam_clrcor_lift_shadows)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderliftmidtones", dx, dy, dw, round(tl_edit.value[e_value.CAM_LIFT_MIDTONES] * 100), -100, 100, 0, 1, tab.camera.tbx_lift_midtones, action_tl_frame_cam_clrcor_lift_midtones)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderlifthighlights", dx, dy, dw, round(tl_edit.value[e_value.CAM_LIFT_HIGHLIGHTS] * 100), -100, 100, 0, 1, tab.camera.tbx_lift_highlights, action_tl_frame_cam_clrcor_lift_highlights)
		tab_next()
		
		tab_control_meter()
		draw_meter("rendersharpen", dx, dy, dw, round(tl_edit.value[e_value.CAM_SHARPEN] * 100), 0, 200, 0, 1, tab.camera.tbx_sharpen, action_tl_frame_cam_clrcor_sharpen, "rendersharpentip")
		tab_next()
		
		tab_collapse_end()
	}
	
	// Film grain (Advanced mode only)
	if (setting_advanced_mode)
	{
		tab_control_switch()
		draw_button_collapse("grain", collapse_map[?"grain"], action_tl_frame_cam_grain, tl_edit.value[e_value.CAM_GRAIN], "frameeditorcameragrain")
		tab_next()
		
		if (tl_edit.value[e_value.CAM_GRAIN] && collapse_map[?"grain"])
		{
			tab_collapse_start()
			
			tab_control_meter()
			draw_meter("frameeditorcameragrainstrength", dx, dy, dw, round(tl_edit.value[e_value.CAM_GRAIN_STRENGTH] * 100), -100, 100, 10, 1, tab.camera.tbx_grain_strength, action_tl_frame_cam_grain_strength)
			tab_next()
			
			tab_control_meter()
			draw_meter("frameeditorcameragrainsaturation", dx, dy, dw, round(tl_edit.value[e_value.CAM_GRAIN_SATURATION] * 100), 0, 100, 10, 1, tab.camera.tbx_grain_saturation, action_tl_frame_cam_grain_saturation)
			tab_next()
			
			tab_control_meter()
			draw_meter("frameeditorcameragrainsize", dx, dy, dw, tl_edit.value[e_value.CAM_GRAIN_SIZE], 1, 10, 1, 1, tab.camera.tbx_grain_size, action_tl_frame_cam_grain_size)
			tab_next()
			
			tab_collapse_end()
		}
	}
	
	// Vignette
	tab_control_switch()
	draw_button_collapse("vignette", collapse_map[?"vignette"], action_tl_frame_cam_vignette, tl_edit.value[e_value.CAM_VIGNETTE], "frameeditorcameravignette")
	tab_next()
	
	if (tl_edit.value[e_value.CAM_VIGNETTE] && collapse_map[?"vignette"])
	{
		tab_collapse_start()
		
		tab_control_meter()
		draw_meter("frameeditorcameravignetteradius", dx, dy, dw, round(tl_edit.value[e_value.CAM_VIGNETTE_RADIUS] * 100), 0, 100, 100, 1, tab.camera.tbx_vignette_radius, action_tl_frame_cam_vignette_radius)
		tab_next()
		
		tab_control_meter()
		draw_meter("frameeditorcameravignettesoftness", dx, dy, dw, round(tl_edit.value[e_value.CAM_VIGNETTE_SOFTNESS] * 100), 0, 100, 50, 1, tab.camera.tbx_vignette_softness, action_tl_frame_cam_vignette_softness)
		tab_next()
		
		tab_control_meter()
		draw_meter("frameeditorcameravignettestrength", dx, dy, dw, round(tl_edit.value[e_value.CAM_VIGNETTE_STRENGTH] * 100), 0, 100, 100, 1, tab.camera.tbx_vignette_strength, action_tl_frame_cam_vignette_strength)
		tab_next()
		
		tab_control_color()
		draw_button_color("frameeditorcameravignettecolor", dx, dy, dw, tl_edit.value[e_value.CAM_VIGNETTE_COLOR], c_black, false, action_tl_frame_cam_vignette_color)
		tab_next()
		
		tab_collapse_end()
	}
	
	// Advanced mode only
	if (setting_advanced_mode)
	{
		// Chromatic aberration
		tab_control_switch()
		draw_button_collapse("ca", collapse_map[?"ca"], action_tl_frame_cam_ca, tl_edit.value[e_value.CAM_CA], "frameeditorcameraca")
		tab_next()
		
		if (tl_edit.value[e_value.CAM_CA] && collapse_map[?"ca"])
		{
			tab_collapse_start()
			
			tab_control_meter()
			draw_meter("frameeditorcameracabluramount", dx, dy, dw, round(tl_edit.value[e_value.CAM_CA_BLUR_AMOUNT] * 100), 0, 100, 5, 1, tab.camera.tbx_ca_blur_amount, action_tl_frame_cam_ca_blur_amount)
			tab_next()
			
			tab_control_switch()
			draw_switch("frameeditorcameracadistortchannels", dx, dy, tl_edit.value[e_value.CAM_CA_DISTORT_CHANNELS], action_tl_frame_cam_ca_distort_channels)
			tab_next()
			
			textfield_group_add("frameeditorcameracaredoffset", round(tl_edit.value[e_value.CAM_CA_RED_OFFSET] * 100), 12, action_tl_frame_cam_ca_red_offset, X, tab.camera.tbx_ca_red_offset)
			textfield_group_add("frameeditorcameracagreenoffset", round(tl_edit.value[e_value.CAM_CA_GREEN_OFFSET] * 100), 8, action_tl_frame_cam_ca_green_offset, X, tab.camera.tbx_ca_green_offset)
			textfield_group_add("frameeditorcameracablueoffset", round(tl_edit.value[e_value.CAM_CA_BLUE_OFFSET] * 100), 4, action_tl_frame_cam_ca_blue_offset, X, tab.camera.tbx_ca_blue_offset)
			
			tab_control_textfield_group(true)
			draw_textfield_group("frameeditorcameracaoffset", dx, dy, dw, 1, 0, no_limit, 1, true, true, 3)
			tab_next()
			
			tab_collapse_end()
		}
		
		// Distort
		tab_control_switch()
		draw_button_collapse("distort", collapse_map[?"distort"], action_tl_frame_cam_distort, tl_edit.value[e_value.CAM_DISTORT], "frameeditorcameradistort")
		tab_next()
		
		if (tl_edit.value[e_value.CAM_DISTORT] && collapse_map[?"distort"])
		{
			tab_collapse_start()
			
			tab_control_switch()
			draw_switch("frameeditorcameradistortrepeat", dx, dy, tl_edit.value[e_value.CAM_DISTORT_REPEAT], action_tl_frame_cam_distort_repeat)
			tab_next()
			
			tab_control_dragger()
			draw_dragger("frameeditorcameradistortzoom", dx, dy, dragger_width, tl_edit.value[e_value.CAM_DISTORT_ZOOM_AMOUNT] * 100, 1, snap_min, no_limit, 100, .01, tab.camera.tbx_distort_zoom_amount, action_tl_frame_cam_distort_zoom_amount)
			tab_next()
			
			tab_control_dragger()
			draw_dragger("frameeditorcameradistortamount", dx, dy, dragger_width, tl_edit.value[e_value.CAM_DISTORT_AMOUNT] * 100, .1, -no_limit * 100, no_limit * 100, 5, 0.01, tab.camera.tbx_distort_amount, action_tl_frame_cam_distort_amount)
			tab_next()
			
			tab_collapse_end(false)
		}
	}
	
	// Sun God-Rays (per-camera keyframeable)
	tab_control_switch()
	draw_button_collapse("cam_godrays", collapse_map[?"cam_godrays"], action_tl_frame_cam_godrays, tl_edit.value[e_value.CAM_GODRAYS], "rendergodrays", "rendergodraystip")
	tab_next()
	
	if (tl_edit.value[e_value.CAM_GODRAYS] && collapse_map[?"cam_godrays"])
	{
		tab_collapse_start()
		
		tab_control_meter()
		draw_meter("rendergodrayssamples", dx, dy, dw, tl_edit.value[e_value.CAM_GODRAYS_SAMPLES], 16, 96, 50, 1, tab.camera.tbx_godrays_samples, action_tl_frame_cam_godrays_samples)
		tab_next()
		
		tab_control_meter()
		draw_meter("rendergodraysdensity", dx, dy, dw, round(tl_edit.value[e_value.CAM_GODRAYS_DENSITY] * 100), 10, 200, 85, 1, tab.camera.tbx_godrays_density, action_tl_frame_cam_godrays_density)
		tab_next()
		
		tab_control_meter()
		draw_meter("rendergodraysdecay", dx, dy, dw, round(tl_edit.value[e_value.CAM_GODRAYS_DECAY] * 100), 70, 100, 90, 1, tab.camera.tbx_godrays_decay, action_tl_frame_cam_godrays_decay)
		tab_next()
		
		tab_control_meter()
		draw_meter("rendergodraysweight", dx, dy, dw, round(tl_edit.value[e_value.CAM_GODRAYS_WEIGHT] * 100), 0, 100, 35, 1, tab.camera.tbx_godrays_weight, action_tl_frame_cam_godrays_weight)
		tab_next()
		
		tab_control_meter()
		draw_meter("rendergodraysexposure", dx, dy, dw, round(tl_edit.value[e_value.CAM_GODRAYS_EXPOSURE] * 100), 0, 200, 10, 1, tab.camera.tbx_godrays_exposure, action_tl_frame_cam_godrays_exposure)
		tab_next()
		
		tab_control_color()
		draw_button_color("rendergodrayscolor", dx, dy, dw, tl_edit.value[e_value.CAM_GODRAYS_COLOR], make_color_rgb(255, 240, 200), false, action_tl_frame_cam_godrays_color)
		tab_next()
		
		tab_collapse_end()
	}
	
	// Sun Lens Flare (per-camera keyframeable)
	tab_control_switch()
	draw_button_collapse("cam_lensflare", collapse_map[?"cam_lensflare"], action_tl_frame_cam_lensflare, tl_edit.value[e_value.CAM_LENSFLARE], "renderlensflare", "renderlensflaretip")
	tab_next()
	
	if (tl_edit.value[e_value.CAM_LENSFLARE] && collapse_map[?"cam_lensflare"])
	{
		tab_collapse_start()
		
		tab_control_meter()
		draw_meter("renderlensflareintensity", dx, dy, dw, round(tl_edit.value[e_value.CAM_LENSFLARE_INTENSITY] * 100), 0, 200, 65, 1, tab.camera.tbx_lensflare_intensity, action_tl_frame_cam_lensflare_intensity)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderlensflareghosts", dx, dy, dw, round(tl_edit.value[e_value.CAM_LENSFLARE_GHOSTS] * 100), 0, 200, 80, 1, tab.camera.tbx_lensflare_ghosts, action_tl_frame_cam_lensflare_ghosts)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderlensflarehalo", dx, dy, dw, round(tl_edit.value[e_value.CAM_LENSFLARE_HALO] * 100), 0, 200, 60, 1, tab.camera.tbx_lensflare_halo, action_tl_frame_cam_lensflare_halo)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderlensflarestarburst", dx, dy, dw, round(tl_edit.value[e_value.CAM_LENSFLARE_STARBURST] * 100), 0, 200, 75, 1, tab.camera.tbx_lensflare_starburst, action_tl_frame_cam_lensflare_starburst)
		tab_next()
		
		tab_control_color()
		draw_button_color("renderlensflarecolor", dx, dy, dw, tl_edit.value[e_value.CAM_LENSFLARE_COLOR], make_color_rgb(255, 235, 200), false, action_tl_frame_cam_lensflare_color)
		tab_next()
		
		tab_collapse_end()
	}
	
	// Toon / Edge Outlines (per-camera keyframeable)
	tab_control_switch()
	draw_button_collapse("cam_outline", collapse_map[?"cam_outline"], action_tl_frame_cam_outline, tl_edit.value[e_value.CAM_OUTLINE], "renderoutline", "renderoutlinetip")
	tab_next()
	
	if (tl_edit.value[e_value.CAM_OUTLINE] && collapse_map[?"cam_outline"])
	{
		tab_collapse_start()
		
		tab_control_meter()
		draw_meter("renderoutlinethickness", dx, dy, dw, tl_edit.value[e_value.CAM_OUTLINE_THICKNESS], 0.5, 5, 1.5, 0.1, tab.camera.tbx_outline_thickness, action_tl_frame_cam_outline_thickness)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderoutlinedepthsens", dx, dy, dw, round(tl_edit.value[e_value.CAM_OUTLINE_DEPTH_SENS] * 100), 10, 500, 100, 1, tab.camera.tbx_outline_depth_sens, action_tl_frame_cam_outline_depth_sens)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderoutlinenormalsens", dx, dy, dw, round(tl_edit.value[e_value.CAM_OUTLINE_NORMAL_SENS] * 100), 10, 500, 100, 1, tab.camera.tbx_outline_normal_sens, action_tl_frame_cam_outline_normal_sens)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderoutlineopacity", dx, dy, dw, round(tl_edit.value[e_value.CAM_OUTLINE_OPACITY] * 100), 0, 100, 85, 1, tab.camera.tbx_outline_opacity, action_tl_frame_cam_outline_opacity)
		tab_next()
		
		tab_control_switch()
		draw_switch("renderoutlinedistfadeenable", dx, dy, tl_edit.value[e_value.CAM_OUTLINE_DIST_FADE_ENABLE], action_tl_frame_cam_outline_dist_fade_enable, "renderoutlinedistfadeenabletip")
		tab_next()
		
		if (tl_edit.value[e_value.CAM_OUTLINE_DIST_FADE_ENABLE])
		{
			tab_control_meter()
			draw_meter("renderoutlinedistfade", dx, dy, dw, round(tl_edit.value[e_value.CAM_OUTLINE_DIST_FADE] * 100), 0, 100, 50, 1, tab.camera.tbx_outline_dist_fade, action_tl_frame_cam_outline_dist_fade)
			tab_next()
		}
		
		tab_control_color()
		draw_button_color("renderoutlinecolor", dx, dy, dw, tl_edit.value[e_value.CAM_OUTLINE_COLOR], c_black, false, action_tl_frame_cam_outline_color)
		tab_next()
		
		tab_collapse_end()
	}
	
	// Screen-Space Reflections (SSR) (per-camera keyframeable)
	tab_control_switch()
	draw_button_collapse("cam_ssr", collapse_map[?"cam_ssr"], action_tl_frame_cam_ssr, tl_edit.value[e_value.CAM_SSR], "renderssr", "renderssrtip")
	tab_next()
	
	if (tl_edit.value[e_value.CAM_SSR] && collapse_map[?"cam_ssr"])
	{
		tab_collapse_start()
		
		tab_control_meter()
		draw_meter("renderssrsteps", dx, dy, dw, tl_edit.value[e_value.CAM_SSR_STEPS], 16, 96, 48, 1, tab.camera.tbx_ssr_steps, action_tl_frame_cam_ssr_steps)
		tab_next()
		
		tab_control_dragger()
		draw_dragger("renderssrmaxdist", dx, dy, dragger_width, tl_edit.value[e_value.CAM_SSR_MAX_DIST], 10, 100, 5000, 1200, 1, tab.camera.tbx_ssr_max_dist, action_tl_frame_cam_ssr_max_dist)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderssrthickness", dx, dy, dw, tl_edit.value[e_value.CAM_SSR_THICKNESS], 1, 100, 18, 0.5, tab.camera.tbx_ssr_thickness, action_tl_frame_cam_ssr_thickness)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderssrstrength", dx, dy, dw, round(tl_edit.value[e_value.CAM_SSR_STRENGTH] * 100), 0, 200, 85, 1, tab.camera.tbx_ssr_strength, action_tl_frame_cam_ssr_strength)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderssrfresnel", dx, dy, dw, round(tl_edit.value[e_value.CAM_SSR_FRESNEL] * 100), 0, 200, 100, 1, tab.camera.tbx_ssr_fresnel, action_tl_frame_cam_ssr_fresnel)
		tab_next()
		
		tab_control_switch()
		draw_switch("renderssrwateronly", dx, dy, tl_edit.value[e_value.CAM_SSR_WATER_ONLY], action_tl_frame_cam_ssr_water_only, "renderssrwateronlytip")
		tab_next()
		
		tab_collapse_end()
	}
	
	// Contact Shadows (per-camera keyframeable)
	tab_control_switch()
	draw_button_collapse("cam_contact_shadows", collapse_map[?"cam_contact_shadows"], action_tl_frame_cam_contact_shadows, tl_edit.value[e_value.CAM_CONTACT_SHADOWS], "rendercontactshadows", "rendercontactshadowstip")
	tab_next()
	
	if (tl_edit.value[e_value.CAM_CONTACT_SHADOWS] && collapse_map[?"cam_contact_shadows"])
	{
		tab_collapse_start()
		
		tab_control_meter()
		draw_meter("rendercontactshadowssteps", dx, dy, dw, tl_edit.value[e_value.CAM_CONTACT_SHADOWS_STEPS], 8, 48, 20, 1, tab.camera.tbx_contact_shadows_steps, action_tl_frame_cam_contact_shadows_steps)
		tab_next()
		
		tab_control_meter()
		draw_meter("rendercontactshadowslength", dx, dy, dw, tl_edit.value[e_value.CAM_CONTACT_SHADOWS_LENGTH], 1, 40, 12, 0.5, tab.camera.tbx_contact_shadows_length, action_tl_frame_cam_contact_shadows_length)
		tab_next()
		
		tab_control_meter()
		draw_meter("rendercontactshadowsthickness", dx, dy, dw, tl_edit.value[e_value.CAM_CONTACT_SHADOWS_THICKNESS], 0.5, 20, 3, 0.5, tab.camera.tbx_contact_shadows_thickness, action_tl_frame_cam_contact_shadows_thickness)
		tab_next()
		
		tab_control_meter()
		draw_meter("rendercontactshadowsstrength", dx, dy, dw, round(tl_edit.value[e_value.CAM_CONTACT_SHADOWS_STRENGTH] * 100), 0, 100, 65, 1, tab.camera.tbx_contact_shadows_strength, action_tl_frame_cam_contact_shadows_strength)
		tab_next()
		
		tab_collapse_end()
	}
	
	// Water Ripples & Rain Puddles Override (per-camera keyframeable)
	tab_control_switch()
	draw_button_collapse("cam_wetness", collapse_map[?"cam_wetness"], action_tl_frame_cam_wetness_override, tl_edit.value[e_value.CAM_WETNESS_OVERRIDE], "renderwaterwetness", "renderwaterwetnesstip")
	tab_next()
	
	if (tl_edit.value[e_value.CAM_WETNESS_OVERRIDE] && collapse_map[?"cam_wetness"])
	{
		tab_collapse_start()
		
		tab_control_switch()
		draw_switch("renderwaterripples", dx, dy, tl_edit.value[e_value.CAM_WATER_RIPPLES], action_tl_frame_cam_water_ripples, "renderwaterripplestip")
		tab_next()
		
		if (tl_edit.value[e_value.CAM_WATER_RIPPLES])
		{
			tab_control_meter()
			draw_meter("renderwaterripplestrength", dx, dy, dw, round(tl_edit.value[e_value.CAM_WATER_RIPPLE_STRENGTH] * 100), 0, 300, 100, 1, tab.camera.tbx_water_ripple_strength, action_tl_frame_cam_water_ripple_strength)
			tab_next()
			
			tab_control_meter()
			draw_meter("renderwaterripplespeed", dx, dy, dw, round(tl_edit.value[e_value.CAM_WATER_RIPPLE_SPEED] * 100), 0, 400, 100, 1, tab.camera.tbx_water_ripple_speed, action_tl_frame_cam_water_ripple_speed)
			tab_next()
		}
		
		tab_control_meter()
		draw_meter("renderwetness", dx, dy, dw, round(tl_edit.value[e_value.CAM_WETNESS] * 100), 0, 100, 0, 1, tab.camera.tbx_wetness, action_tl_frame_cam_wetness, "renderwetnesstip")
		tab_next()
		
		if (tl_edit.value[e_value.CAM_WETNESS] > 0)
		{
			tab_control_switch()
			draw_switch("renderwetnessripples", dx, dy, tl_edit.value[e_value.CAM_WETNESS_RIPPLES], action_tl_frame_cam_wetness_ripples, "renderwetnessripplestip")
			tab_next()
		}
		
		tab_collapse_end()
	}
	
	// Cel-Shading (per-camera keyframeable)
	tab_control_switch()
	draw_button_collapse("cam_cel", collapse_map[?"cam_cel"], action_tl_frame_cam_cel_shading, tl_edit.value[e_value.CAM_CEL_SHADING], "rendercelshading", "rendercelshadingtip")
	tab_next()
	
	if (tl_edit.value[e_value.CAM_CEL_SHADING] && collapse_map[?"cam_cel"])
	{
		tab_collapse_start()
		
		tab_control_meter()
		draw_meter("rendercelsteps", dx, dy, dw, tl_edit.value[e_value.CAM_CEL_STEPS], 2, 8, 4, 1, tab.camera.tbx_cel_steps, action_tl_frame_cam_cel_steps)
		tab_next()
		
		tab_control_meter()
		draw_meter("rendercelsmoothness", dx, dy, dw, round(tl_edit.value[e_value.CAM_CEL_SMOOTHNESS] * 100), 0, 100, 15, 1, tab.camera.tbx_cel_smoothness, action_tl_frame_cam_cel_smoothness)
		tab_next()
		
		tab_collapse_end()
	}
	
	// Volumetric Spotlights & Point Light Halos (per-camera keyframeable)
	tab_control_switch()
	draw_button_collapse("cam_volumetric", collapse_map[?"cam_volumetric"], action_tl_frame_cam_volumetric_lights, tl_edit.value[e_value.CAM_VOLUMETRIC_LIGHTS], "rendervolumetriclights", "rendervolumetriclightstip")
	tab_next()
	
	if (tl_edit.value[e_value.CAM_VOLUMETRIC_LIGHTS] && collapse_map[?"cam_volumetric"])
	{
		tab_collapse_start()
		
		tab_control_meter()
		draw_meter("rendervolumetricintensity", dx, dy, dw, round(tl_edit.value[e_value.CAM_VOLUMETRIC_INTENSITY] * 100), 0, 200, 75, 1, tab.camera.tbx_volumetric_intensity, action_tl_frame_cam_volumetric_intensity)
		tab_next()
		
		tab_control_meter()
		draw_meter("rendervolumetricspotdensity", dx, dy, dw, round(tl_edit.value[e_value.CAM_VOLUMETRIC_SPOT_DENSITY] * 100), 0, 200, 85, 1, tab.camera.tbx_volumetric_spot_density, action_tl_frame_cam_volumetric_spot_density)
		tab_next()
		
		tab_control_meter()
		draw_meter("rendervolumetricpointradius", dx, dy, dw, round(tl_edit.value[e_value.CAM_VOLUMETRIC_POINT_RADIUS] * 100), 0, 300, 100, 1, tab.camera.tbx_volumetric_point_radius, action_tl_frame_cam_volumetric_point_radius)
		tab_next()
		
		tab_control_meter()
		draw_meter("rendervolumetricsteps", dx, dy, dw, tl_edit.value[e_value.CAM_VOLUMETRIC_STEPS], 8, 64, 24, 1, tab.camera.tbx_volumetric_steps, action_tl_frame_cam_volumetric_steps)
		tab_next()
		
		tab_collapse_end()
	}
	
	// Motion Blur / Radial Zoom Blur / Anime Speed Lines (per-camera keyframeable)
	tab_control_switch()
	draw_button_collapse("cam_motion_fx", collapse_map[?"cam_motion_fx"], action_tl_frame_cam_motion_fx, tl_edit.value[e_value.CAM_MOTION_FX], "rendermotionfx", "rendermotionfxtip")
	tab_next()
	
	if (tl_edit.value[e_value.CAM_MOTION_FX] && collapse_map[?"cam_motion_fx"])
	{
		tab_collapse_start()
		
		tab_control_meter()
		draw_meter("rendermotionblur", dx, dy, dw, round(tl_edit.value[e_value.CAM_MOTION_BLUR] * 100), 0, 200, 0, 1, tab.camera.tbx_motion_blur, action_tl_frame_cam_motion_blur)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderradialblur", dx, dy, dw, round(tl_edit.value[e_value.CAM_RADIAL_BLUR] * 100), 0, 100, 0, 1, tab.camera.tbx_radial_blur, action_tl_frame_cam_radial_blur)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderspeedlines", dx, dy, dw, round(tl_edit.value[e_value.CAM_SPEED_LINES] * 100), 0, 100, 0, 1, tab.camera.tbx_speed_lines, action_tl_frame_cam_speed_lines)
		tab_next()
		
		if (tl_edit.value[e_value.CAM_SPEED_LINES] > 0)
		{
			tab_control_meter()
			draw_meter("renderspeedlinesradius", dx, dy, dw, round(tl_edit.value[e_value.CAM_SPEED_LINES_RADIUS] * 100), 10, 95, 55, 1, tab.camera.tbx_speed_lines_radius, action_tl_frame_cam_speed_lines_radius)
			tab_next()
			
			tab_control_color()
			draw_button_color("renderspeedlinescolor", dx, dy, dw, tl_edit.value[e_value.CAM_SPEED_LINES_COLOR], c_white, false, action_tl_frame_cam_speed_lines_color)
			tab_next()
		}
		
		tab_collapse_end()
	}
	
	// Screen-Space Weather & Camera Lens Drops (per-camera keyframeable)
	tab_control_switch()
	draw_button_collapse("cam_weather_fx", collapse_map[?"cam_weather_fx"], action_tl_frame_cam_weather_fx, tl_edit.value[e_value.CAM_WEATHER_FX], "renderweatherfx", "renderweatherfxtip")
	tab_next()
	
	if (tl_edit.value[e_value.CAM_WEATHER_FX] && collapse_map[?"cam_weather_fx"])
	{
		tab_collapse_start()
		
		tab_control_meter()
		draw_meter("renderweatherrain", dx, dy, dw, round(tl_edit.value[e_value.CAM_WEATHER_RAIN] * 100), 0, 100, 0, 1, tab.camera.tbx_weather_rain, action_tl_frame_cam_weather_rain)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderweathersnow", dx, dy, dw, round(tl_edit.value[e_value.CAM_WEATHER_SNOW] * 100), 0, 100, 0, 1, tab.camera.tbx_weather_snow, action_tl_frame_cam_weather_snow)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderweatherwind", dx, dy, dw, round(tl_edit.value[e_value.CAM_WEATHER_WIND] * 100), -100, 100, 15, 1, tab.camera.tbx_weather_wind, action_tl_frame_cam_weather_wind)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderweatherlensdrops", dx, dy, dw, round(tl_edit.value[e_value.CAM_WEATHER_LENS_DROPS] * 100), 0, 100, 0, 1, tab.camera.tbx_weather_lens_drops, action_tl_frame_cam_weather_lens_drops)
		tab_next()
		
		tab_collapse_end()
	}
	
	// Retro / Stylized Post-FX (per-camera keyframeable)
	tab_control_switch()
	draw_button_collapse("cam_retro", collapse_map[?"cam_retro"], action_tl_frame_cam_retro, tl_edit.value[e_value.CAM_RETRO], "renderretro", "renderretrotip")
	tab_next()
	
	if (tl_edit.value[e_value.CAM_RETRO] && collapse_map[?"cam_retro"])
	{
		tab_collapse_start()
		
		tab_control_meter()
		draw_meter("renderretropixelate", dx, dy, dw, tl_edit.value[e_value.CAM_RETRO_PIXELATE], 1, 16, 1, 1, tab.camera.tbx_retro_pixelate, action_tl_frame_cam_retro_pixelate)
		tab_next()
		
		tab_control_switch()
		draw_switch("renderretrodither", dx, dy, tl_edit.value[e_value.CAM_RETRO_DITHER], action_tl_frame_cam_retro_dither, "renderretrodithertip")
		tab_next()
		
		if (tl_edit.value[e_value.CAM_RETRO_DITHER])
		{
			tab_control_meter()
			draw_meter("renderretrocolors", dx, dy, dw, tl_edit.value[e_value.CAM_RETRO_COLORS], 2, 64, 16, 1, tab.camera.tbx_retro_colors, action_tl_frame_cam_retro_colors)
			tab_next()
		}
		
		tab_control_meter()
		draw_meter("renderretroscanlines", dx, dy, dw, round(tl_edit.value[e_value.CAM_RETRO_SCANLINES] * 100), 0, 100, 0, 1, tab.camera.tbx_retro_scanlines, action_tl_frame_cam_retro_scanlines)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderretrocurvature", dx, dy, dw, round(tl_edit.value[e_value.CAM_RETRO_CURVATURE] * 100), 0, 100, 0, 1, tab.camera.tbx_retro_curvature, action_tl_frame_cam_retro_curvature)
		tab_next()
		
		tab_control_meter()
		draw_meter("renderretrovhs", dx, dy, dw, round(tl_edit.value[e_value.CAM_RETRO_VHS] * 100), 0, 100, 0, 1, tab.camera.tbx_retro_vhs, action_tl_frame_cam_retro_vhs)
		tab_next()
		
		tab_collapse_end(false)
	}
	
	context_menu_group_temp = null
}
