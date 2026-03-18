extends Node3D

class SwarmEnemy:
	var position: Vector3
	var velocity: Vector3
	var hp: int
	var damage: int
	var alive := true
	var chaos_offset: float

# 🔥 Reduced for mobile safety
@export var max_enemies := 1000
@export var enemy_texture: Texture2D
const ENEMY_TILT := deg_to_rad(-40.0)
var player: Node3D

var enemies := []
var multimesh := MultiMesh.new()

var spawn_timer := 0.0
var spawn_rate := 0.05

const FRONT_LIMIT_Z := -25.0
const BACK_LIMIT_Z := -120.0

@export var battlefield_width := 20.0

# ------------------------------------------------
# READY
# ------------------------------------------------

func _ready():

	add_to_group("enemy_manager")

	# -----------------------------
	# BILLBOARD MESH SETUP
	# -----------------------------
	var quad := QuadMesh.new()
	quad.size = Vector2(4, 3)

	var mat := StandardMaterial3D.new()
	mat.albedo_texture = enemy_texture
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	#mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	quad.material = mat

	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = max_enemies
	multimesh.mesh = quad

	$MultiMeshInstance3D.multimesh = multimesh

	# hide all initially
	for i in range(max_enemies):
		hide_enemy(i)

	prefill_battlefield()


# ------------------------------------------------
# PREFILL
# ------------------------------------------------

func prefill_battlefield():

	var rows := 40
	var columns := 25   # slightly reduced

	var z_step = (BACK_LIMIT_Z - FRONT_LIMIT_Z) / rows
	var x_step = battlefield_width / columns

	for r in range(rows):
		for c in range(columns):

			if enemies.size() >= max_enemies:
				return

			var x = -battlefield_width/2 + c * x_step + randf_range(-0.3,0.3)
			var z = FRONT_LIMIT_Z + r * z_step + randf_range(-0.3,0.3)

			var pos = Vector3(x, 0, z)

			var dto = get_random_enemy()

			if dto != null:
				spawn_enemy(pos, dto)


# ------------------------------------------------
# MAIN LOOP
# ------------------------------------------------

func _process(delta):

	spawn_timer += delta

	if spawn_timer >= spawn_rate:
		spawn_timer = 0
		spawn_random_enemy()

	update_enemies(delta)


# ------------------------------------------------
# SPAWN
# ------------------------------------------------

func spawn_random_enemy():

	if enemies.size() >= max_enemies:
		return

	var dto = get_random_enemy()

	if dto == null:
		return

	var pos = Vector3(
		randf_range(-10,10),
		0,
		randf_range(-80,-120)
	)

	spawn_enemy(pos, dto)


func spawn_enemy(pos: Vector3, dto):

	if enemies.size() >= max_enemies:
		return

	var e = SwarmEnemy.new()

	e.position = pos
	e.velocity = Vector3(0, 0, dto.speed if dto.speed != null else 4)
	e.hp = dto.base_health
	e.damage = dto.collision_damage
	e.chaos_offset = randf() * 10

	enemies.append(e)

	var index = enemies.size() - 1

	var scale = randf_range(1, 1.4)   # 🔥 slightly controlled

	var t := Transform3D()
	t.origin = e.position
	t.basis = Basis().scaled(Vector3.ONE * scale)

	multimesh.set_instance_transform(index, t)


# ------------------------------------------------
# UPDATE
# ------------------------------------------------

func update_enemies(delta):

	for i in range(enemies.size()):

		var e = enemies[i]

		if !e.alive:
			continue

		# forward
		e.position += e.velocity * delta

		# swarm chaos
		var side = sin(Time.get_ticks_msec() * 0.002 + e.chaos_offset)
		e.position.x += side * delta * 2

		# clamp inside battlefield
		e.position.x = clamp(e.position.x, -battlefield_width/2, battlefield_width/2)

		# damage player
		if player and e.position.distance_to(player.global_position) < 1.5:

			player.take_damage(e.damage)

			e.alive = false
			hide_enemy(i)
			continue

		var depth_scale = clamp(2.0 - (abs(e.position.z) / 120.0), 1.0, 2.0)

		var basis = Basis()
		basis = basis.scaled(Vector3.ONE * depth_scale)

		var t := Transform3D()
		t.origin = e.position
		t.basis = basis

		multimesh.set_instance_transform(i, t)


# ------------------------------------------------
# BULLET HIT
# ------------------------------------------------

func check_hit(bullet_pos: Vector3, damage: int) -> bool:

	for i in range(enemies.size()):

		var e = enemies[i]

		if !e.alive:
			continue

		if bullet_pos.distance_to(e.position) < 0.7:

			e.hp -= damage

			if e.hp <= 0:
				e.alive = false
				kill_enemy(i)

			return true

	return false


# ------------------------------------------------
# DEATH
# ------------------------------------------------

func kill_enemy(i):

	hide_enemy(i)

	var game = get_tree().get_first_node_in_group("game")

	if game:
		game.add_score(100)


func hide_enemy(i):

	multimesh.set_instance_transform(
		i,
		Transform3D(Basis(), Vector3(0,-9999,0))
	)


# ------------------------------------------------
# BACKEND
# ------------------------------------------------

func get_random_enemy():

	var total := 0.0

	for e in GameState.all_enemies:
		if e.is_active:
			total += e.spawn_percentage

	if total == 0:
		return null

	var roll = randf() * total
	var cumulative := 0.0

	for e in GameState.all_enemies:

		if !e.is_active:
			continue

		cumulative += e.spawn_percentage

		if roll <= cumulative:
			return e

	return GameState.all_enemies[0]
