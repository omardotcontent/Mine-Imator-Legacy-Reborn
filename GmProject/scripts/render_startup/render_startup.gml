/// render_startup()

function render_startup()
{
	globalvar render_view_current, render_width, render_height, render_ratio, render_camera, render_time, render_surface_time,
			  render_prev_color, render_prev_alpha, render_click_box, render_list, render_lights, render_particles, render_hidden,
			  render_background, render_watermark, proj_from, proj_matrix, view_matrix, view_proj_matrix, light_proj_matrix, light_view_matrix,
			  light_view_proj_matrix, spot_proj_matrix, spot_view_matrix, spot_view_proj_matrix, proj_depth_near, proj_depth_far, render_proj_from,
			  render_active, render_repeat, render_world_count, point3D_project_error;
	
	globalvar render_light_amount, render_light_from, render_light_to, render_light_near, render_light_far, render_light_fov,
			  render_light_color, render_light_strength, render_light_fade_size, render_light_spot_sharpness, render_light_matrix,
			  render_shadow_matrix, render_sun_matrix, render_sun_direction, render_sun_near, render_sun_far, render_light_offset, render_shadow_from,
			  render_spot_matrix, render_light_specular_strength, render_light_size;
	
	globalvar render_effects, render_effects_done, render_effects_list, render_effects_progress, render_camera_bloom, render_camera_dof,
			  render_glow, render_glow_falloff, render_camera_ca, render_camera_distort, render_camera_color_correction, render_camera_grain,
			  render_camera_vignette, render_aa, render_godrays, render_tonemap_pass, render_overlay, render_camera_lens_dirt, render_camera_lens_dirt_bloom, render_camera_lens_dirt_glow,
			  render_ssao, render_shadows, render_indirect, render_reflections, render_quality, render_pass,
			  render_tonemapper, render_exposure, render_gamma, render_depth_normals,
			  render_ssr, render_contact_shadows, render_lensflare, render_global_bloom, render_outline, render_retro,
			  render_volumetric_lights, render_motion_fx, render_weather_fx,
			  render_prev_view_proj_matrix, render_has_prev_view_proj;
	
	globalvar render_matrix, render_samples, render_sample_current, render_samples_done, render_target_size;
	
	globalvar render_blend_prev, render_alpha_prev;
	
	// Update shader_reset_uniforms()
	globalvar shader_uniform_color_ext, shader_uniform_rgb_add, shader_uniform_rgb_sub, shader_uniform_hsb_add,
			  shader_uniform_hsb_sub, shader_uniform_hsb_mul, shader_uniform_mix_color, shader_uniform_mix_percent,
			  shader_uniform_emissive, shader_uniform_metallic, shader_uniform_roughness, shader_uniform_wind,
			  shader_uniform_wind_terrain, shader_uniform_fog, shader_uniform_ssao, shader_uniform_sss, shader_uniform_sss_red,
			  shader_uniform_sss_green, shader_uniform_sss_blue, shader_uniform_sss_color, shader_uniform_glow, shader_uniform_glow_texture,
			  shader_uniform_glow_color, shader_uniform_wind_strength;
	
	globalvar render_pass_surf;
	
	log("Render init")
	
	gpu_set_blendenable(true)
	gpu_set_blendmode(bm_normal)
	gpu_set_alphatestenable(true)
	gpu_set_alphatestref(0)
	gpu_set_texfilter(false)
	gpu_set_tex_mip_enable(mip_off)
	gpu_set_tex_mip_filter(tf_linear)
	gpu_set_texrepeat(true)
	gpu_set_ztestenable(false)
	render_set_culling(true)
	gpu_set_tex_max_mip(4)
	shader_reset_uniforms()
	
	render_view_current = null
	render_width = 1
	render_height = 1
	render_ratio = 1
	render_camera = null
	
	render_light_amount = 0
	render_light_strength = 1
	render_light_specular_strength = 0
	render_light_matrix = MAT_IDENTITY
	
	render_effects = false
	render_effects_done = false
	render_effects_list = ds_list_create()
	render_effects_progress = 0
	render_quality = e_view_mode.FLAT
	
	render_camera_bloom = false
	render_camera_dof = false
	render_glow = false
	render_glow_falloff = false
	render_camera_ca = false
	render_camera_distort = false
	render_camera_color_correction = false
	render_camera_grain = false
	render_camera_vignette = false
	render_aa = false
	render_godrays = false
	render_tonemap_pass = false
	render_overlay = false
	render_camera_lens_dirt = true
	render_camera_lens_dirt_bloom = true
	render_camera_lens_dirt_glow = true
	render_ssao = false
	render_shadows = false
	render_indirect = false
	render_reflections = false
	render_depth_normals = false
	render_ssr = false
	render_contact_shadows = false
	render_lensflare = false
	render_global_bloom = false
	render_outline = false
	render_retro = false
	render_volumetric_lights = false
	render_motion_fx = false
	render_weather_fx = false
	render_prev_view_proj_matrix = MAT_IDENTITY
	render_has_prev_view_proj = false
	
	render_click_box = vbuffer_create_cube(view_3d_box_size / 2, point2D(0, 0), point2D(1, 1), 1, 1, false, false)
	render_list = ds_list_create()
	render_lights = true
	render_particles = true
	render_hidden = false
	render_background = true
	render_watermark = false
	
	render_time = 0
	render_surface_time = 0
	render_active = null
	render_repeat = vec3(0)
	
	// Surfaces for rendering
	globalvar render_target, render_surface, render_surface_post, render_surface_ssao, render_surface_shadows, render_surface_fog,
			  render_surface_lens, depth_near, depth_far, render_post_index,
			  render_surface_gbuf_depth, render_surface_gbuf_normal, render_surface_gbuf_mat,
			  render_surface_sun_color, render_surface_sun_occ, render_sun_occ_ready,
			  render_gbuf_proj_matrix, render_gbuf_view_matrix, render_gbuf_near, render_gbuf_far;
			
	render_target = null
	render_surface[0] = null
	render_surface[1] = null
	render_surface[2] = null
	render_surface[3] = null
	render_surface[4] = null
	
	render_surface_post[0] = null
	render_surface_post[1] = null
	
	render_surface_ssao = null
	render_surface_shadows = null
	render_surface_fog = null
	render_surface_lens = null
	render_surface_gbuf_depth = null
	render_surface_gbuf_normal = null
	render_surface_gbuf_mat = null
	render_surface_sun_color = null
	render_surface_sun_occ = null
	render_sun_occ_ready = false
	render_gbuf_proj_matrix = MAT_IDENTITY
	render_gbuf_view_matrix = MAT_IDENTITY
	render_gbuf_near = clip_near
	render_gbuf_far = 5000
	
	depth_near = clip_near
	depth_far = 5000
	render_post_index = 0
	
	render_world_count = 0
	
	// Unused legacy 2.0 globals kept for compatibility with shared helpers
	globalvar taa_matrix, taa_jitter_matrix;
	taa_matrix = MAT_IDENTITY
	taa_jitter_matrix = MAT_IDENTITY
	
	globalvar render_alpha_hash, render_alpha_hash_force;
	render_alpha_hash = false
	render_alpha_hash_force = false
	
	globalvar render_sample_noise_texture, render_sample_noise_size, render_sample_noise_texture_array;
	render_sample_noise_texture = null
	render_sample_noise_size = 128
	render_sample_noise_texture_array = []
	
	// Classic 1.2.9 Shadows
	globalvar render_shadowless_point_list, render_shadowless_point_data, render_shadowless_point_amount,
			  render_surface_sun_buffer, render_surface_spot_buffer, render_surface_point_buffer;
	
	render_shadowless_point_amount = 0
	render_shadowless_point_list = ds_list_create()
	render_surface_sun_buffer = null
	render_surface_spot_buffer = null
	for (var d = 0; d < 6; d++)
		render_surface_point_buffer[d] = null
	
	// Classic 1.2.9 SSAO (16/32/64-sample kernels + 4x4 noise)
	globalvar render_ssao_kernel, render_ssao_kernel_16, render_ssao_kernel_32, render_ssao_kernel_64, render_ssao_noise;
	render_ssao_kernel_16 = render_generate_sample_kernel(16)
	for (var k = 16 * 3; k < 64 * 3; k++)
		render_ssao_kernel_16[k] = 0
	render_ssao_kernel_32 = render_generate_sample_kernel(32)
	for (var k = 32 * 3; k < 64 * 3; k++)
		render_ssao_kernel_32[k] = 0
	render_ssao_kernel_64 = render_generate_sample_kernel(64)
	render_ssao_kernel = render_ssao_kernel_16
	render_ssao_noise = null
	
	// DOF
	globalvar render_dof_samples, render_dof_weight_samples, render_dof_sample_amount;
	
	// Grain
	globalvar render_grain_noise;
	render_grain_noise = null
	
	// Blur kernel (used by Bloom, Glow, Lens Dirt)
	globalvar render_blur_kernel;
	render_blur_kernel = render_generate_gaussian_kernel(19)
	
	globalvar render_samples_clear;
	render_samples_clear = false
	
	// Render samples (single-pass in classic 1.2.9 renderer)
	render_samples = 0
	render_sample_current = 0
	render_samples_done = false
	render_matrix = []
	
	// Render pass surf
	render_pass_surf = null
	
	render_blend_prev = null
	render_alpha_prev = null
	
	// Render modes
	globalvar render_mode, render_mode_shader_map, render_shader_obj;
	render_mode = null
	render_mode_shader_map = ds_map_create()
	render_mode_shader_map[?e_render_mode.CLICK] = shader_replace
	render_mode_shader_map[?e_render_mode.SELECT] = shader_blend
	render_mode_shader_map[?e_render_mode.PLACE] = shader_blend
	render_mode_shader_map[?e_render_mode.PREVIEW] = shader_color_fog
	render_mode_shader_map[?e_render_mode.COLOR] = shader_color_fog
	render_mode_shader_map[?e_render_mode.COLOR_FOG] = shader_color_fog
	render_mode_shader_map[?e_render_mode.COLOR_FOG_LIGHTS] = shader_color_fog_lights
	render_mode_shader_map[?e_render_mode.ALPHA_FIX] = shader_alpha_fix
	render_mode_shader_map[?e_render_mode.ALPHA_TEST] = shader_alpha_test
	render_mode_shader_map[?e_render_mode.DEPTH] = shader_depth
	render_mode_shader_map[?e_render_mode.DEPTH_NO_SKY] = shader_depth
	render_mode_shader_map[?e_render_mode.HIGH_SSAO_DEPTH_NORMAL] = shader_high_ssao_depth_normal
	render_mode_shader_map[?e_render_mode.HIGH_LIGHT_SUN_DEPTH] = shader_depth
	render_mode_shader_map[?e_render_mode.HIGH_SUN_COLOR] = shader_high_sun_color
	render_mode_shader_map[?e_render_mode.HIGH_LIGHT_SPOT_DEPTH] = shader_depth
	render_mode_shader_map[?e_render_mode.HIGH_LIGHT_POINT_DEPTH] = shader_depth_point
	render_mode_shader_map[?e_render_mode.HIGH_LIGHT_SUN] = shader_high_light_sun
	render_mode_shader_map[?e_render_mode.HIGH_LIGHT_SPOT] = shader_high_light_spot
	render_mode_shader_map[?e_render_mode.HIGH_LIGHT_POINT] = shader_high_light_point
	render_mode_shader_map[?e_render_mode.HIGH_LIGHT_POINT_SHADOWLESS] = shader_high_light_point_shadowless
	render_mode_shader_map[?e_render_mode.HIGH_LIGHT_NIGHT] = shader_high_light_night
	render_mode_shader_map[?e_render_mode.HIGH_FOG] = shader_high_fog
	render_mode_shader_map[?e_render_mode.COLOR_GLOW] = shader_color_glow
	render_mode_shader_map[?e_render_mode.SCENE_TEST] = shader_replace_alpha
	render_mode_shader_map[?e_render_mode.AO_MASK] = shader_replace
	render_mode_shader_map[?e_render_mode.GLINT] = shader_high_glint
	
	// Init settings
	project_reset_render()
	
	// Check for default render settings file
	if (!file_exists_lib(render_default_file))
	{
		if (!directory_exists_lib(render_directory))
			directory_create_lib(render_directory)
		
		project_save_start(render_default_file, false)
		project_save_render()
		project_save_done()
	
		log("Saved default render settings", render_default_file)
	}
}
