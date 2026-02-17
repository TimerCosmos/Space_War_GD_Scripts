extends Node3D

@export var enemy_scene: PackedScene
@export var base_spawn_interval := 2.0
@export var min_spawn_interval := 0.4
@export var difficulty_ramp := 0.05

@export var row_count := 7

var spawn_interval := 2.0
var timer := 0.0
var wave_level := 0

# Battlefield layout
const TOTAL_WIDTH := 14.0
const LEFT_ZONE_WIDTH := TOTAL_WIDTH * 0.3
const RIGHT_MIN_X := -TOTAL_WIDTH / 2.0 + LEFT_ZONE_WIDTH
const RIGHT_MAX_X := TOTAL_WIDTH / 2.0


func _ready():
	spawn_interval = base_spawn_interval


func _process(delta):
	timer -= delta
	if timer <= 0:
		spawn_wave()
		timer = spawn_interval

		increase_difficulty()


func spawn_wave():
	wave_level += 1

	var spawn_width = RIGHT_MAX_X - RIGHT_MIN_X
	var spacing = spawn_width / float(row_count)
	var start_x = RIGHT_MIN_X

	for i in row_count:
		var enemy = enemy_scene.instantiate()
		get_tree().current_scene.add_child(enemy)
		enemy.enemy_destroyed.connect(_on_enemy_destroyed)
		enemy.global_position = Vector3(
			start_x + spacing * i,
			0,
			-33
		)

func _on_enemy_destroyed():
	var game = get_tree().current_scene
	if game.has_method("add_score"):
		game.add_score(100)


func increase_difficulty():
	spawn_interval = max(
		min_spawn_interval,
		spawn_interval - difficulty_ramp
	)
