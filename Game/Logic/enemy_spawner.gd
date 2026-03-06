extends Node3D

@export var lanes := 18
@export var base_spacing := 1.2
@export var density_growth := 0.015
@export var max_visible_enemies := 15000

@export var enemy_scene: PackedScene
var scene_cache = {}
const FRONT_LIMIT_Z := -40.0
const BACK_LIMIT_Z := -90.0

var ENEMY_MIN_X
var ENEMY_MAX_X
var enemies: Array = []
var time_alive := 0.0

var current_health_mult := 1.0
var current_damage_mult := 1.0
var spacing_z := 1.2
var last_spawn_z := BACK_LIMIT_Z

func _ready():
	await get_tree().process_frame
	last_spawn_z = get_back_enemy_z()
	spacing_z = base_spacing
	setup_battlefield()
	build_matrix()


func setup_battlefield():

	var camera = get_viewport().get_camera_3d()

	var world_width = BattlefieldLayout.get_world_width(camera, FRONT_LIMIT_Z)

	var upgrade_zone = world_width * 0.15
	var enemy_zone = world_width * 0.70

	var left_edge = -world_width / 2.0

	ENEMY_MIN_X = left_edge + upgrade_zone
	ENEMY_MAX_X = ENEMY_MIN_X + enemy_zone


func _process(delta):
	time_alive += delta
	update_difficulty()
	maintain_enemy_density()


func build_matrix():

	var width = ENEMY_MAX_X - ENEMY_MIN_X
	var lane_width = width / lanes

	var depth := BACK_LIMIT_Z

	while depth <= FRONT_LIMIT_Z:
		if get_enemy_count() >= max_visible_enemies:
			break

		for l in lanes:
			if get_enemy_count() >= max_visible_enemies:
				break

			var x = ENEMY_MIN_X + lane_width * l + lane_width / 2
			var pos = Vector3(x, 0, depth)

			spawn_enemy(pos)

		depth += spacing_z


func maintain_enemy_density():

	if get_enemy_count() >= max_visible_enemies:
		return

	while last_spawn_z >= BACK_LIMIT_Z and get_enemy_count() < max_visible_enemies:

		last_spawn_z -= spacing_z
		spawn_row(last_spawn_z)


func spawn_row(depth: float):
	if get_enemy_count() >= max_visible_enemies:
		return

	var width = ENEMY_MAX_X - ENEMY_MIN_X
	var lane_width = width / lanes

	for l in lanes:
		if get_enemy_count() >= max_visible_enemies:
			break

		var x = ENEMY_MIN_X + lane_width * l + lane_width / 2
		var pos = Vector3(x, 0, depth)

		spawn_enemy(pos)

# -------------------------------------
# Spawn enemy
# -------------------------------------

func spawn_enemy(pos:Vector3):
	if get_enemy_count() >= max_visible_enemies:
		return null

	var dto = _get_random_enemy_dto()
	if dto == null:
		return null

	var scene:PackedScene

	if dto.scene_path in scene_cache:
		scene = scene_cache[dto.scene_path]
	else:
		scene = load(dto.scene_path)
		scene_cache[dto.scene_path] = scene
	var enemy: EnemyNode = scene.instantiate()

	get_tree().current_scene.add_child(enemy)
	enemy.global_position = pos
	enemies.append(enemy)
	if enemy.has_method("apply_backend_data"):
		enemy.apply_backend_data(dto)

	if enemy.has_method("apply_scaling"):
		enemy.apply_scaling(current_health_mult,current_damage_mult)

	if enemy.has_signal("enemy_destroyed"):
		enemy.enemy_destroyed.connect(_on_enemy_destroyed.bind(enemy,pos.x))

	return enemy


# -------------------------------------
# Replace enemy when destroyed
# -------------------------------------

func _on_enemy_destroyed(enemy, x_pos):

	enemies.erase(enemy)

	var game = get_tree().current_scene
	if game.has_method("add_score"):
		game.add_score(100)

	_spawn_enemy_replacement.call_deferred(x_pos)


func _spawn_enemy_replacement(x_pos):
	await get_tree().process_frame

	if get_enemy_count() >= max_visible_enemies:
		return

	var spawn_z = last_spawn_z
	last_spawn_z -= spacing_z

	var pos = Vector3(x_pos, 0, spawn_z)

	spawn_enemy(pos)


# -------------------------------------
# Find farthest enemy
# -------------------------------------

func get_back_enemy_z():

	if enemies.is_empty():
		return BACK_LIMIT_Z

	var farthest := BACK_LIMIT_Z

	for e in enemies:

		if !is_instance_valid(e):
			continue

		if e.global_position.z < farthest:
			farthest = e.global_position.z

	return farthest


func get_enemy_count() -> int:
	return enemies.size()


# -------------------------------------
# Difficulty scaling
# -------------------------------------

func update_difficulty():

	var t = time_alive

	current_health_mult = 1.0 + (t * 0.02)
	current_damage_mult = 1.0 + (t * 0.008)
	spacing_z = base_spacing / (1.0 + t * density_growth)


# -------------------------------------
# Enemy selection
# -------------------------------------

func _get_random_enemy_dto():

	var total := 0.0

	for e in GameState.all_enemies:
		if e.is_active:
			total += e.spawn_percentage

	var roll = randf() * total
	var cumulative := 0.0

	for e in GameState.all_enemies:

		if not e.is_active:
			continue

		cumulative += e.spawn_percentage

		if roll <= cumulative:
			return e

	return GameState.all_enemies[0]
