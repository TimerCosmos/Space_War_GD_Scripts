extends CharacterBody3D

# ----------------------------
# Runtime Data (Injected)
# ----------------------------
var drone_data: DroneData		# DroneData resource (from DB or .tres)
var follow_target            # SpaceShip reference

var current_health := 0
var fire_timer := 0.0

# Orbit parameters (can be overridden by data if needed later)
var orbit_radius := 3.0
var orbit_speed := 1.5
var follow_smooth := 5.0

var angle := 0.0
var random_offset := Vector3.ZERO

var _base_damage: int = 0
var _base_hit_rate: float = 0.0
# ----------------------------
# Apply DB / Base Data
# ----------------------------
var runtime_damage: int
var runtime_fire_rate: float

func apply_data(resource_data: DroneData, backend_data):
	drone_data = resource_data.duplicate(true)

	current_health = backend_data.base_health
	runtime_damage = backend_data.base_damage
	runtime_fire_rate = backend_data.base_hit_rate



# ----------------------------
# Ready
# ----------------------------
func _ready():
	add_to_group("drone")

	# Random initial orbit angle
	angle = randf_range(0, TAU)

	# Small random offset so drones don't stack perfectly
	random_offset = Vector3(
		randf_range(-1.0, 1.0),
		0,
		randf_range(-1.0, 1.0)
	)


# ----------------------------
# Process Loop
# ----------------------------
func _process(delta):
	if follow_target == null or drone_data == null:
		return

	# ---- ORBIT MOTION ----
	angle += orbit_speed * delta

	var orbit_x = cos(angle) * orbit_radius
	var orbit_z = sin(angle) * orbit_radius

	var desired_position = follow_target.global_position \
		+ Vector3(orbit_x, 0, orbit_z) \
		+ random_offset

	global_position = global_position.lerp(
		desired_position,
		follow_smooth * delta
	)

	# ---- AUTO ROTATE TOWARD ENEMY ----
	var enemies = get_tree().get_nodes_in_group("enemy")
	if not enemies.is_empty():
		var target = enemies[0]
		look_at(target.global_position, Vector3.UP)

	# ---- SHOOTING ----
	fire_timer -= delta
	if fire_timer <= 0:
		shoot()
		fire_timer = runtime_fire_rate


# ----------------------------
# Shooting
# ----------------------------
func shoot():
	if drone_data == null:
		return

	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.is_empty():
		return

	var target = enemies[randi() % enemies.size()]

	var bullet_scene = preload("res://Scenes/Attacks/plasma.tscn")
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)

	bullet.global_position = global_position
	bullet.look_at(target.global_position, Vector3.UP)

	# Pass damage dynamically
	bullet.damage = runtime_damage



# ----------------------------
# Damage Handling
# ----------------------------
func take_damage(amount: int):
	current_health -= amount
	if current_health <= 0:
		queue_free()
