extends Area3D

@export var speed := 60.0
@export var life_time := 3.0

var can_hit_upgrades: bool
var damage: int = 0

var enemy_manager = null

var previous_position: Vector3


func _ready():
	add_to_group("player_bullet")

	enemy_manager = get_tree().get_first_node_in_group("enemy_manager")

	previous_position = global_position

	await get_tree().create_timer(life_time).timeout
	queue_free()


func _physics_process(delta):

	var direction = -transform.basis.z
	var new_position = global_position + direction * speed * delta

	# -----------------------------
	# RAYCAST CHECK (FIXED)
	# -----------------------------
	var space = get_world_3d().direct_space_state

	var query = PhysicsRayQueryParameters3D.create(
		previous_position,
		new_position
	)

	# Exclude self
	query.exclude = [self]

	# Exclude player (extra safety)
	var player = get_tree().get_first_node_in_group("player")
	if player:
		query.exclude.append(player)

	# 🔥 CRITICAL FIX → respect collision layers
	query.collision_mask = (1 << 1) | (1 << 3)

	var result = space.intersect_ray(query)

	if result:
		var collider = result.collider

		# Ignore player (double safety)
		if collider.is_in_group("player"):
			return

		# -----------------------------
		# UPGRADE HIT
		# -----------------------------
		if can_hit_upgrades and collider.is_in_group("upgrade"):
			if collider.has_method("take_damage"):
				collider.take_damage(damage)
			queue_free()
			return

		# -----------------------------
		# ENEMY HIT
		# -----------------------------
		if collider.has_method("take_damage"):
			collider.take_damage(damage)
			queue_free()
			return

	# -----------------------------
	# MOVE BULLET
	# -----------------------------
	global_position = new_position
	previous_position = global_position

	# -----------------------------
	# SWARM CHECK
	# -----------------------------
	if enemy_manager:
		var hit = enemy_manager.check_hit(global_position, damage)
		if hit:
			queue_free()
