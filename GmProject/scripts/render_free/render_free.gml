/// render_free()

function render_free()
{
	// Render targets
	surface_free(render_surface[0])
	surface_free(render_surface[1])
	surface_free(render_surface[2])
	surface_free(render_surface[3])
	surface_free(render_surface[4])
	
	surface_free(render_surface_post[0])
	surface_free(render_surface_post[1])
	
	// Camera effects & shared G-buffer
	surface_free(render_surface_lens)
	surface_free(render_surface_gbuf_depth)
	surface_free(render_surface_gbuf_normal)
	surface_free(render_surface_gbuf_mat)
	surface_free(render_surface_sun_color)
	surface_free(render_surface_sun_occ)
	
	// Light depth buffers
	surface_free(render_surface_sun_buffer)
	surface_free(render_surface_spot_buffer)
	for (var d = 0; d < 6; d++)
		surface_free(render_surface_point_buffer[d])
}
