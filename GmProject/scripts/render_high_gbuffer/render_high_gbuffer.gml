/// render_high_gbuffer()
/// @desc Renders the shared 3-MRT G-buffer (depth, view-space normal, material/SSAO/water mask) once per frame

function render_high_gbuffer()
{
	var gw, gh;
	if (render_ssr || render_contact_shadows || render_outline || render_volumetric_lights || render_motion_fx)
	{
		gw = render_width
		gh = render_height
	}
	else
	{
		gw = max(1, round(render_width * project_render_ssao_ratio))
		gh = max(1, round(render_height * project_render_ssao_ratio))
	}
	
	render_surface_gbuf_depth = surface_require(render_surface_gbuf_depth, gw, gh)
	render_surface_gbuf_normal = surface_require(render_surface_gbuf_normal, gw, gh)
	render_surface_gbuf_mat = surface_require(render_surface_gbuf_mat, gw, gh)
	
	surface_set_target_ext(0, render_surface_gbuf_depth)
	surface_set_target_ext(1, render_surface_gbuf_normal)
	surface_set_target_ext(2, render_surface_gbuf_mat)
	{
		gpu_set_blendmode_ext(bm_one, bm_zero)
		draw_clear_alpha(c_white, 0)
		render_world_start(depth_far)
		render_gbuf_proj_matrix = proj_matrix
		render_gbuf_view_matrix = view_matrix
		render_gbuf_near = cam_near
		render_gbuf_far = cam_far
		render_world(e_render_mode.HIGH_SSAO_DEPTH_NORMAL)
		render_world_done()
		gpu_set_blendmode(bm_normal)
	}
	surface_reset_target()
}
