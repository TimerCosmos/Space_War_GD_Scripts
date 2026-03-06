extends Node
class_name BattlefieldLayout

static func get_world_width(camera: Camera3D, z_depth: float) -> float:
	var fov = deg_to_rad(camera.fov)
	var height = 2.0 * abs(z_depth - camera.global_position.z) * tan(fov / 2.0)
	var aspect = camera.get_viewport().get_visible_rect().size.x / camera.get_viewport().get_visible_rect().size.y
	return height * aspect * 0.7
