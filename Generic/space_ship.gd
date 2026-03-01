extends CharacterBody3D
class_name SpaceShip

signal ship_destroyed
signal health_changed(current, max)
signal damage_changed(current)
signal drone_added(value)
# Runtime data
var ship_data: ShipData
var current_health: int
@export var default_drone_data: DroneData

@onready var muzzles: Array = []

# Drone system
var drones: Array = []

# Control state
var controls_enabled := false
var is_holding := false
var fire_timer := 0.0
var target_tilt := 0.0

var runtime_max_health: int
var runtime_damage: int
var runtime_fire_rate: float
var runtime_speed: float

# Temporary bonuses (powerups)
var bonus_damage: int = 0
var bonus_health: int = 0
# -------------------------------------------------
# Apply ShipData safely (duplicate .tres)
# -------------------------------------------------
func apply_data(resource_data: ShipData, backend_data: Spaceship, player_data: Dictionary = {}):

	ship_data = resource_data.duplicate(true)
	if backend_data == null:
		# Preview mode – minimal setup
		current_health = 1
		return
	runtime_max_health = backend_data.base_health
	runtime_damage = backend_data.base_damage
	runtime_fire_rate = backend_data.base_hit_rate
	runtime_speed = backend_data.base_speed
	# Persistent DB bonuses
	if player_data.has("bonus_health"):
		runtime_max_health += player_data["bonus_health"]

	if player_data.has("bonus_damage"):
		runtime_damage += player_data["bonus_damage"]

	if player_data.has("bonus_fire_rate"):
		runtime_fire_rate += player_data["bonus_fire_rate"]

	current_health = runtime_max_health
	emit_signal("health_changed", current_health, runtime_max_health)



# -------------------------------------------------
# Ready
# -------------------------------------------------
func _ready():
	add_to_group("player")
		# Collect all muzzle markers dynamically
	var muzzle_parent = $Muzzles
	for child in muzzle_parent.get_children():
		if child is Marker3D:
			muzzles.append(child)
			
	var scene := get_tree().current_scene
	if scene and scene.scene_file_path.ends_with("game.tscn"):
		enable_controls(true)
	else:
		enable_controls(false)


# -------------------------------------------------
# Input
# -------------------------------------------------
func _unhandled_input(event):
	if not controls_enabled or ship_data == null:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_holding = event.pressed
		if !is_holding:
			target_tilt = 0.0

	if is_holding and event is InputEventMouseMotion:
		var new_x = global_position.x + event.relative.x * runtime_speed * 0.01
		new_x = clamp(new_x, ship_data.min_x, ship_data.max_x)
		global_position.x = new_x

		target_tilt = clamp(-event.relative.x * 0.002, -0.25, 0.25)


# -------------------------------------------------
# Process
# -------------------------------------------------
func _process(delta):
	if not controls_enabled or ship_data == null:
		return

	rotation.z = lerp(rotation.z, target_tilt, 10.0 * delta)

	if not is_holding:
		return

	fire_timer -= delta
	if fire_timer <= 0:
		shoot()
		fire_timer = runtime_fire_rate


# -------------------------------------------------
# Shoot (always 1 bullet)
# -------------------------------------------------
func shoot():
	if ship_data == null or ship_data.bullet_scene == null:
		return

	for muzzle in muzzles:
		var bullet = ship_data.bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		bullet.global_transform = muzzle.global_transform


# -------------------------------------------------
# Drone System
# -------------------------------------------------
func add_drone(count: int):

	# 1️⃣ Get selected drone ID from DroneManager
	var drone_id = DroneManager.selected_drone_id
	
	# 2️⃣ If none selected, fallback to ship default
	if drone_id == "":
		if ship_data.default_drone_data != null:
			drone_id = ship_data.default_drone_data.drone_id

	if drone_id == "":
		print("No drone selected or default available")
		return

	# 3️⃣ Get backend DTO
	var backend_drone = GameState.get_drone_by_id(drone_id)
	if backend_drone == null:
		print("Backend drone not found")
		return

	# 4️⃣ Load resource from DTO
	var resource_data: DroneData = load(backend_drone.tres_file_path)
	if resource_data == null or resource_data.scene_path == null:
		print("Drone resource invalid")
		return

	# 5️⃣ Spawn drones
	for i in count:
		var drone = resource_data.scene_path.instantiate()
		get_tree().current_scene.add_child(drone)

		drone.follow_target = self
		drone.apply_data(resource_data, backend_drone)

		drones.append(drone)
	emit_signal("drone_added", count)




func increase_damage(amount: int):
	bonus_damage += amount
	runtime_damage += amount
	emit_signal("damage_changed", runtime_damage)

func increase_health(amount: int):
	bonus_health += amount
	runtime_max_health += amount
	current_health += amount
	emit_signal("health_changed", current_health, runtime_max_health)


# -------------------------------------------------
# Health
# -------------------------------------------------
func take_damage(amount: int):
	current_health = max(current_health - amount, 0)
	emit_signal("health_changed", current_health, runtime_max_health)


	if current_health <= 0:
		die()

func die():
	emit_signal("ship_destroyed")
	queue_free()


# -------------------------------------------------
# Controls
# -------------------------------------------------
func enable_controls(enable: bool):
	controls_enabled = enable
	Input.set_mouse_mode(
		Input.MOUSE_MODE_CAPTURED if enable else Input.MOUSE_MODE_VISIBLE
	)
