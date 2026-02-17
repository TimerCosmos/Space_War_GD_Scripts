extends CharacterBody3D

@export var fire_rate := 0.6
@export var orbit_radius := 3.0
@export var orbit_speed := 1.5
@export var follow_smooth := 5.0

var follow_target
var fire_timer := 0.0

var angle := 0.0
var random_offset := Vector3.ZERO


func _ready():
	add_to_group("drone")

	# Each drone gets random orbit angle
	angle = randf_range(0, TAU)

	# Random vertical & depth offset
	random_offset = Vector3(
		randf_range(-1.0, 1.0),
		0,
		randf_range(-1.0, 1.0)
	)


func _process(delta):
	if follow_target == null:
		return

	# Orbit motion
	angle += orbit_speed * delta

	var orbit_x = cos(angle) * orbit_radius
	var orbit_z = sin(angle) * orbit_radius

	var desired_position = follow_target.global_position \
		+ Vector3(orbit_x, 0, orbit_z) \
		+ random_offset

	# Smooth movement
	global_position = global_position.lerp(
		desired_position,
		follow_smooth * delta
	)

	# Shooting
	fire_timer -= delta
	if fire_timer <= 0:
		shoot()
		fire_timer = fire_rate


func shoot():
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.is_empty():
		return

	var target = enemies[randi() % enemies.size()]

	var bullet_scene = preload("res://Scenes/Attacks/plasma.tscn")
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)

	bullet.global_position = global_position
	bullet.look_at(target.global_position, Vector3.UP)
