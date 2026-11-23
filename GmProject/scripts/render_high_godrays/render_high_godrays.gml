/// render_high_godrays(prevsurf)
/// @arg prevsurf
/// @desc Renders screen-space volumetric sun light shafts (God-Rays)

function render_high_godrays(prevsurf)
{
	if (background_sunlight_color_final = c_black)
		return prevsurf
	
	// Check if sun is in front of camera
	var camdir = vec3_normalize(point3D_sub(cam_to, cam_from));
	var sundot = vec3_dot(camdir, background_sun_direction);
	if (sundot <= 0.05)
		return prevsurf
	
	// Smooth fade as sun approaches camera edge or horizon
	var vis_angle = clamp((sundot - 0.05) / 0.30, 0, 1);
	var vis_height = clamp((background_sun_direction[Z] + 0.12) / 0.28, 0, 1);
	var visibility = vis_angle * vis_height;
	if (visibility <= 0.001)
		return prevsurf
	
	// Project sun position to screen UV
	var sunworld = point3D_add(cam_from, vec3_mul(background_sun_direction, 5000));
	var sunproj = point3D_project(sunworld, view_proj_matrix, render_width, render_height);
	if (point3D_project_error)
		return prevsurf
	
	var sunu = sunproj[X] / max(1, render_width);
	var sunv = sunproj[Y] / max(1, render_height);
	
	// Render (or reuse) half-res sky occlusion mask (black = open sky, white = occluding geometry)
	if (!render_sun_occ_ready || !surface_exists(render_surface_sun_occ))
	{
		var occw = max(1, floor(render_width / 2));
		var occh = max(1, floor(render_height / 2));
		render_surface_sun_occ = surface_require(render_surface_sun_occ, occw, occh)
		surface_set_target(render_surface_sun_occ)
		{
			draw_clear_alpha(c_black, 1)
			render_world_start()
			render_world(e_render_mode.SCENE_TEST)
			render_world_done()
		}
		surface_reset_target()
		render_sun_occ_ready = true
	}
	var occsurf = render_surface_sun_occ;
	
	// Apply God-Rays onto scene
	var resultsurf = render_high_get_apply_surf();
	surface_set_target(resultsurf)
	{
		draw_clear_alpha(c_black, 0)
		render_set_projection_ortho(0, 0, render_width, render_height, 0)
		render_shader_obj = shader_map[?shader_high_godrays]
		with (render_shader_obj)
		{
			shader_set(shader)
			shader_high_godrays_set(occsurf, sunu, sunv, visibility)
		}
		draw_surface_exists(prevsurf, 0, 0)
		with (render_shader_obj)
			shader_clear()
	}
	surface_reset_target()
	
	return resultsurf
}
