/// render_high_lensflare(prevsurf)
/// @arg prevsurf

function render_high_lensflare(prevsurf)
{
	if (background_sunlight_color_final = c_black)
		return prevsurf
	
	var camdir = vec3_normalize(point3D_sub(cam_to, cam_from));
	var sundot = vec3_dot(camdir, background_sun_direction);
	if (sundot <= 0.08)
		return prevsurf
	
	var vis_angle = clamp((sundot - 0.08) / 0.25, 0, 1);
	var vis_height = clamp((background_sun_direction[Z] + 0.05) / 0.22, 0, 1);
	var visibility = vis_angle * vis_height;
	if (visibility <= 0.001)
		return prevsurf
	
	var sunworld = point3D_add(cam_from, vec3_mul(background_sun_direction, 5000));
	var sunproj = point3D_project(sunworld, view_proj_matrix, render_width, render_height);
	if (point3D_project_error)
		return prevsurf
	
	var sunu = sunproj[X] / max(1, render_width);
	var sunv = sunproj[Y] / max(1, render_height);
	if (sunu < -0.35 || sunu > 1.35 || sunv < -0.35 || sunv > 1.35)
		return prevsurf
	
	// Reuse sun occlusion mask if God-Rays already rendered it this frame
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
	
	var resultsurf = render_high_get_apply_surf();
	surface_set_target(resultsurf)
	{
		draw_clear_alpha(c_black, 0)
		render_set_projection_ortho(0, 0, render_width, render_height, 0)
		render_shader_obj = shader_map[?shader_high_lensflare]
		with (render_shader_obj)
		{
			shader_set(shader)
			shader_high_lensflare_set(render_surface_sun_occ, sunu, sunv, visibility)
		}
		draw_surface_exists(prevsurf, 0, 0)
		with (render_shader_obj)
			shader_clear()
	}
	surface_reset_target()
	return resultsurf
}
