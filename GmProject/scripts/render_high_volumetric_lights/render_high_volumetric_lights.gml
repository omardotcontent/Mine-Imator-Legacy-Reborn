/// render_high_volumetric_lights(prevsurf)
/// @arg prevsurf

function render_high_volumetric_lights(prevsurf)
{
	if (!surface_exists(render_surface_gbuf_depth))
		return prevsurf
	
	// Gather up to 16 visible Point & Spot lights in view space
	var lcount = 0;
	var ldata;
	for (var k = 0; k < 256; k++)
		ldata[k] = 0
	
	with (obj_timeline)
	{
		if (!render_visible || lcount >= 16)
			continue
		if (type != e_tl_type.POINT_LIGHT && type != e_tl_type.SPOT_LIGHT)
			continue
		
		var vpos = point3D_mul_matrix(world_pos, render_gbuf_view_matrix);
		var col = value[e_value.LIGHT_COLOR];
		var str = value[e_value.LIGHT_STRENGTH];
		var rng = value[e_value.LIGHT_RANGE];
		var fade = value[e_value.LIGHT_FADE_SIZE];
		
		var baseIdx = lcount * 16;
		ldata[baseIdx + 0] = vpos[X]
		ldata[baseIdx + 1] = vpos[Y]
		ldata[baseIdx + 2] = vpos[Z]
		ldata[baseIdx + 3] = rng
		
		ldata[baseIdx + 4] = color_get_red(col) / 255
		ldata[baseIdx + 5] = color_get_green(col) / 255
		ldata[baseIdx + 6] = color_get_blue(col) / 255
		ldata[baseIdx + 7] = str
		
		if (type = e_tl_type.SPOT_LIGHT)
		{
			var lookat = point3D_mul_matrix(point3D(0.0001, 1, 0), matrix);
			var vlook = point3D_mul_matrix(lookat, render_gbuf_view_matrix);
			var vdir = vec3_normalize(point3D_sub(vlook, vpos));
			var cosHalf = dcos(clamp(value[e_value.LIGHT_SPOT_RADIUS] * 0.5, 1, 89));
			ldata[baseIdx + 8] = vdir[X]
			ldata[baseIdx + 9] = vdir[Y]
			ldata[baseIdx + 10] = vdir[Z]
			ldata[baseIdx + 11] = cosHalf
			ldata[baseIdx + 12] = value[e_value.LIGHT_SPOT_SHARPNESS]
			ldata[baseIdx + 13] = fade
		}
		else
		{
			ldata[baseIdx + 8] = 0
			ldata[baseIdx + 9] = 0
			ldata[baseIdx + 10] = 1
			ldata[baseIdx + 11] = -1
			ldata[baseIdx + 12] = 0
			ldata[baseIdx + 13] = fade
		}
		lcount++
	}
	
	if (lcount = 0)
		return prevsurf
	
	var ratio = clamp(project_render_volumetric_lights_ratio, 0.25, 1.0);
	var vw = max(1, round(render_width * ratio));
	var vh = max(1, round(render_height * ratio));
	
	render_surface[0] = surface_require(render_surface[0], vw, vh)
	var vol_surf = render_surface[0];
	surface_set_target(vol_surf)
	{
		draw_clear_alpha(c_black, 1)
		render_set_projection_ortho(0, 0, vw, vh, 0)
		gpu_set_blendmode_ext(bm_one, bm_zero)
		render_shader_obj = shader_map[?shader_high_volumetric_lights]
		with (render_shader_obj)
		{
			shader_set(shader)
			shader_high_volumetric_lights_set(lcount, ldata)
		}
		draw_blank(0, 0, vw, vh)
		with (render_shader_obj)
			shader_clear()
		gpu_set_blendmode(bm_normal)
	}
	surface_reset_target()
	
	var resultsurf = render_high_get_apply_surf();
	surface_set_target(resultsurf)
	{
		draw_clear_alpha(c_black, 0)
		render_set_projection_ortho(0, 0, render_width, render_height, 0)
		gpu_set_blendmode_ext(bm_one, bm_zero)
		draw_surface_exists(prevsurf, 0, 0)
		
		gpu_set_blendmode_ext_sepalpha(bm_one, bm_one, bm_zero, bm_one)
		gpu_set_texfilter(vw != render_width || vh != render_height)
		draw_surface_ext(vol_surf, 0, 0, render_width / max(1, vw), render_height / max(1, vh), 0, c_white, 1)
		gpu_set_texfilter(false)
		gpu_set_blendmode(bm_normal)
	}
	surface_reset_target()
	return resultsurf
}
