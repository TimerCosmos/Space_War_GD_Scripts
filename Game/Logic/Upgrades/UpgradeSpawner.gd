extends Node3D

@export var upgrade_scene: PackedScene
@export var spawn_interval := 3.0

var timer := 0.0

const TOTAL_WIDTH := 14.0
const LEFT_ZONE_WIDTH := TOTAL_WIDTH * 0.3
const LEFT_MIN_X := -TOTAL_WIDTH / 2.0
const LEFT_MAX_X := LEFT_MIN_X + LEFT_ZONE_WIDTH


func _process(delta):
	timer -= delta
	if timer <= 0:
		spawn_upgrade()
		timer = spawn_interval


func spawn_upgrade():
	var upgrade = upgrade_scene.instantiate()
	get_tree().current_scene.add_child(upgrade)

	var x_pos = randf_range(LEFT_MIN_X, LEFT_MAX_X)

	upgrade.global_position = Vector3(
		x_pos,
		0,
		-40
	)

	var roll = randf()

	if roll < 0.5:
		upgrade.configure("drone", 1)
	elif roll < 0.9:
		upgrade.configure("damage", 1)
	else:
		upgrade.configure("health", 2)
