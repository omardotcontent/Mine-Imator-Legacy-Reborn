/// render_world_start_light(from, to, near, far, fov, color, [fadesize, [spotsharpness, [strength]]])
/// @arg from
/// @arg to
/// @arg near
/// @arg far
/// @arg fov
/// @arg color
/// @arg [fadesize
/// @arg [spotsharpness
/// @arg [strength]]]
/// @desc Render the scene from the light's point of view (Classic 1.2.9).

function render_world_start_light(from, to, near, far, fov, color, fadesize = 0.5, spotsharpness = 0.5, strength = 1)
{
	render_light_from = from
	render_light_to = to
	render_light_near = near
	render_light_far = far
	render_light_fov = fov
	render_light_color = color
	render_light_fade_size = fadesize
	render_light_spot_sharpness = spotsharpness
	render_light_strength = strength
	
	gpu_set_ztestenable(true)
	render_set_projection(render_light_from, render_light_to, vec3(0, 0, 1), render_light_fov, 1, 1, render_light_far)
	
	render_proj_from = render_light_from
	proj_matrix = matrix_get(matrix_projection)
	view_matrix = matrix_get(matrix_view)
	view_proj_matrix = matrix_multiply(view_matrix, proj_matrix)
	
	proj_depth_near = render_light_near
	proj_depth_far = render_light_far
	
	render_light_matrix = view_proj_matrix
}
