extends Node3D

class SwarmEnemy:
	var position: Vector3
	var velocity: Vector3
	var hp: int
	var damage: int
	var alive := true
	var chaos_offset: float

@export var max_enemies := 1000
@export var enemy_texture: Texture2D
const ENEMY_TILT := deg_to_rad(-40.0)
var player: Node3D

var enemies := []
var multimesh := MultiMesh.new()

var spawn_timer := 0.0
var spawn_rate := 0.05

# ⏱ GAME TIMER
var game_time := 0.0

const FRONT_LIMIT_Z := -25.0
const BACK_LIMIT_Z := -120.0

# ✅ SAME SCENE for hit + death
var blast_scene = preload("res://Scenes/Enemies/hit_blast.tscn")
var enemy_death_sfx = preload("res://Assets/Sound Tracks/SFX/monsterGrunt.mp3")

@export var battlefield_width := 20.0

# ------------------------------------------------
# READY
# ------------------------------------------------

func _ready():

	add_to_group("enemy_manager")

	var quad := QuadMesh.new()
	quad.size = Vector2(4, 3)

	var mat := StandardMaterial3D.new()
	mat.albedo_texture = enemy_texture
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	quad.material = mat

	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = max_enemies
	multimesh.mesh = quad

	$MultiMeshInstance3D.multimesh = multimesh

	for i in range(max_enemies):
		hide_enemy(i)

	prefill_battlefield()

# ------------------------------------------------
# PREFILL
# ------------------------------------------------

func prefill_battlefield():

	var rows := 40
	var columns := 25

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

	game_time += delta

	spawn_timer += delta

	if spawn_timer >= spawn_rate:
		spawn_timer = 0
		spawn_random_enemy()

	update_enemies(delta)

# ------------------------------------------------
# HP CURVE SYSTEM
# ------------------------------------------------

func get_enemy_hp(base_hp: float) -> int:

	var t = game_time

	# 0 → 45 sec → fixed HP
	if t <= 45.0:
		return 100

	# 45 sec → 2m15s (135 sec) → 50%
	elif t <= 135.0:
		return int(base_hp * 0.5)

	# 2m15s → 6 min → normal
	elif t <= 360.0:
		return int(base_hp)

	# 6 min+ → scaling
	else:
		var extra_time = t - 360.0

		# gradual increase (5% every 30 sec)
		var multiplier = 1.0 + (extra_time / 30.0) * 0.05

		return int(base_hp * multiplier)

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

	# 🔁 Try to reuse dead enemy
	for i in range(enemies.size()):
		if !enemies[i].alive:

			var e = enemies[i]

			e.alive = true
			e.position = pos
			e.velocity = Vector3(0, 0, dto.speed if dto.speed != null else 4)
			e.hp = get_enemy_hp(dto.base_health)
			e.damage = dto.collision_damage
			e.chaos_offset = randf() * 10

			update_multimesh_instance(i, e)
			return

	# 🆕 If no dead slot, create new (only if under limit)
	if enemies.size() >= max_enemies:
		return

	var e = SwarmEnemy.new()

	e.alive = true
	e.position = pos
	e.velocity = Vector3(0, 0, dto.speed if dto.speed != null else 4)
	e.hp = get_enemy_hp(dto.base_health)
	e.damage = dto.collision_damage
	e.chaos_offset = randf() * 10

	enemies.append(e)

	var index = enemies.size() - 1
	update_multimesh_instance(index, e)

func update_multimesh_instance(i, e):

	var scale = randf_range(1, 1.4)

	var t := Transform3D()
	t.origin = e.position
	t.basis = Basis().scaled(Vector3.ONE * scale)

	multimesh.set_instance_transform(i, t)
# ------------------------------------------------
# UPDATE
# ------------------------------------------------

func update_enemies(delta):

	for i in range(enemies.size()):

		var e = enemies[i]

		if !e.alive:
			continue

		e.position += e.velocity * delta

		var side = sin(Time.get_ticks_msec() * 0.002 + e.chaos_offset)
		e.position.x += side * delta * 2

		e.position.x = clamp(e.position.x, -battlefield_width/2, battlefield_width/2)

		if player and e.position.distance_to(player.global_position) < 1.5:

			player.take_damage(e.damage)

			e.alive = false
			hide_enemy(i)
			continue

		var depth_scale = clamp(2.0 - (abs(e.position.z) / 120.0), 1.0, 2.0)

		var basis = Basis().scaled(Vector3.ONE * depth_scale)

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

			# ⚡ hit feedback
			flash_enemy(i)
			spawn_blast(e.position, 0.4)

			# 💀 death
			if e.hp <= 0:
				e.alive = false
				kill_enemy(i)

			return true

	return false

# ------------------------------------------------
# HIT FLASH
# ------------------------------------------------

func flash_enemy(i):

	if i >= enemies.size():
		return

	var e = enemies[i]
	if !e.alive:
		return

	var t = multimesh.get_instance_transform(i)
	var original_basis = t.basis

	t.basis = original_basis.scaled(Vector3.ONE * 1.25)
	multimesh.set_instance_transform(i, t)

	await get_tree().create_timer(0.08).timeout

	if i >= enemies.size():
		return

	if !enemies[i].alive:
		return

	t = multimesh.get_instance_transform(i)
	t.basis = original_basis
	multimesh.set_instance_transform(i, t)

# ------------------------------------------------
# DEATH
# ------------------------------------------------

func kill_enemy(i):

	var pos = enemies[i].position

	spawn_blast(pos, 1.0)

	enemies[i].alive = false
	hide_enemy(i)

	AudioManager.play_sfx(enemy_death_sfx, 1)

	var game = get_tree().get_first_node_in_group("game")
	if game:
		game.add_score(100)

# ------------------------------------------------
# BLAST (shared)
# ------------------------------------------------

func spawn_blast(pos: Vector3, scale: float = 1.0):

	var blast = blast_scene.instantiate()
	get_tree().current_scene.add_child(blast)

	blast.global_position = pos
	blast.scale = Vector3.ONE * scale

# ------------------------------------------------
# HIDE
# ------------------------------------------------

func hide_enemy(i):

	var t := Transform3D()
	t.origin = Vector3(0, -9999, 0)

	multimesh.set_instance_transform(i, t)

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
