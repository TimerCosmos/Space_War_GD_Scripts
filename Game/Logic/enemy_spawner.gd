extends Node3D

@export var enemy_scene: PackedScene

# Spawn timing
@export var base_spawn_interval := 2.0
@export var min_spawn_interval := 0.4

# Layout
@export var row_count := 15

# Battlefield layout
const TOTAL_WIDTH := 14.0
const LEFT_ZONE_WIDTH := TOTAL_WIDTH * 0.3
const RIGHT_MIN_X := -TOTAL_WIDTH / 2.0 + LEFT_ZONE_WIDTH
const RIGHT_MAX_X := TOTAL_WIDTH / 2.0

var spawn_interval := 2.0
var timer := 0.0

# Survival tracking
var time_alive := 0.0

# Runtime difficulty multipliers
var current_health_mult := 1.0
var current_damage_mult := 1.0

func _ready():
	spawn_interval = base_spawn_interval

func _process(delta):
	time_alive += delta
	
	timer -= delta
	if timer <= 0:
		spawn_wave()
		timer = spawn_interval
	
	update_difficulty()


# ---------------------------------------
# Spawn Wave
# ---------------------------------------

func spawn_wave():
	var spawn_width = RIGHT_MAX_X - RIGHT_MIN_X
	var spacing = spawn_width / float(row_count)
	var start_x = RIGHT_MIN_X

	for i in row_count:

		# 1️⃣ Pick enemy DTO based on spawn percentage
		var dto = _get_random_enemy_dto()
		if dto == null:
			return

		# 2️⃣ Load scene from backend scene_path
		var scene: PackedScene = load(dto.scene_path)
		if scene == null:
			push_error("Enemy scene not found: " + str(dto.scene_path))
			continue

		var enemy = scene.instantiate()
		get_tree().current_scene.add_child(enemy)

		# 3️⃣ Position enemy
		enemy.global_position = Vector3(
			start_x + spacing * i,
			0,
			-33
		)

		# 4️⃣ Inject backend base stats
		if enemy.has_method("apply_backend_data"):
			enemy.apply_backend_data(dto)

		# 5️⃣ Apply survival scaling
		if enemy.has_method("apply_scaling"):
			enemy.apply_scaling(current_health_mult, current_damage_mult)

		# 6️⃣ Score connection
		if enemy.has_signal("enemy_destroyed"):
			enemy.enemy_destroyed.connect(_on_enemy_destroyed)

func _get_random_enemy_dto():
	var total_weight := 0.0

	for e in GameState.all_enemies:
		if e.is_active and e.spawn_percentage != null:
			total_weight += e.spawn_percentage

	if total_weight == 0:
		return null

	var roll = randf() * total_weight
	var cumulative := 0.0

	for e in GameState.all_enemies:
		if not e.is_active:
			continue
			
		cumulative += e.spawn_percentage
		if roll <= cumulative:
			return e

	return GameState.all_enemies[0]
# ---------------------------------------
# Smooth Difficulty Scaling
# ---------------------------------------

func update_difficulty():
	var t = time_alive
	
	# Smooth survival growth
	current_health_mult = 1.0 + (t * 0.015)
	current_damage_mult = 1.0 + (t * 0.005)
	var spawn_mult = 1.0 + (t * 0.01)

	# Reduce spawn interval gradually
	spawn_interval = max(
		min_spawn_interval,
		base_spawn_interval / spawn_mult
	)


# ---------------------------------------
# Score Handling
# ---------------------------------------

func _on_enemy_destroyed():
	var game = get_tree().current_scene
	if game.has_method("add_score"):
		game.add_score(100)
