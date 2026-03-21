extends CharacterBody3D
class_name SpaceShip

signal ship_destroyed
signal health_changed(current, max)
signal damage_changed(current)
signal drone_added(value)

var ship_data: ShipData
var current_health: int

@export var default_drone_data: DroneData

@onready var muzzles: Array = []

var drones: Array = []

var controls_enabled := false
var is_holding := false
var fire_timer := 0.0
var target_tilt := 0.0

var runtime_max_health: int
var runtime_damage: int
var runtime_fire_rate: float
var runtime_speed: float

var bonus_damage: int = 0
var bonus_health: int = 0

var bullet_sfx = preload("res://Assets/Sound Tracks/SFX/GunShot.mp3")

# --------------------------------
# Battlefield movement limits
# --------------------------------

const UPGRADE_PERCENT := 0.15
const ENEMY_PERCENT := 0.70
const MARGIN_PERCENT := 0.15

# If you want to shrink movement area
@export var movement_width_percent := 0.9

var min_x := -5.0
var max_x := 5.0


# -------------------------------------------------
# Apply backend data
# -------------------------------------------------

func apply_data(resource_data: ShipData, backend_data: Spaceship, player_data: Dictionary = {}):

	ship_data = resource_data.duplicate(true)

	if backend_data == null:
		current_health = 1
		return

	runtime_max_health = backend_data.base_health
	runtime_damage = backend_data.base_damage
	runtime_fire_rate = backend_data.base_hit_rate
	runtime_speed = backend_data.base_speed

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

	setup_movement_bounds()

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
# Calculate battlefield movement area
# -------------------------------------------------

func setup_movement_bounds():

	var camera = get_viewport().get_camera_3d()

	if camera == null:
		return

	var battlefield_front_z = -20.0

	var world_width = BattlefieldLayout.get_world_width(camera, battlefield_front_z)

	var upgrade_zone = world_width * UPGRADE_PERCENT
	var enemy_zone = world_width * ENEMY_PERCENT

	var left_edge = -world_width / 2.0

	# ship should cover upgrades + enemies
	min_x = left_edge
	max_x = left_edge + upgrade_zone + enemy_zone

# -------------------------------------------------
# Camera width calculation
# -------------------------------------------------

func get_world_width(camera: Camera3D, z_depth: float) -> float:

	var fov = deg_to_rad(camera.fov)

	var distance = abs(z_depth - camera.global_position.z)

	var height = 2.0 * distance * tan(fov / 2.0)

	var viewport = camera.get_viewport().get_visible_rect().size

	var aspect = viewport.x / viewport.y

	return height * aspect


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

		var sens = lerp(0.3, 2.0, UserSettingsManager.sensitivity)
		var new_x = global_position.x + event.relative.x * runtime_speed * 0.01 * sens

		new_x = clamp(new_x, min_x, max_x)

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
# Shooting
# -------------------------------------------------

func shoot():

	if ship_data == null or ship_data.bullet_scene == null:
		return

	for muzzle in muzzles:

		var bullet = ship_data.bullet_scene.instantiate()
		bullet.can_hit_upgrades = true
		get_tree().current_scene.add_child(bullet)

		bullet.global_transform = muzzle.global_transform

		bullet.damage = runtime_damage
	AudioManager.play_sfx(bullet_sfx, 0.2)

# -------------------------------------------------
# Drone System
# -------------------------------------------------

func add_drone(count: int):

	var drone_id = DroneManager.selected_drone_id

	if drone_id == "":
		if ship_data.default_drone_data != null:
			drone_id = ship_data.default_drone_data.drone_id

	if drone_id == "":
		return

	var backend_drone = GameState.get_drone_by_id(drone_id)

	if backend_drone == null:
		return

	var resource_data: DroneData = load(backend_drone.tres_file_path)

	if resource_data == null or resource_data.scene_path == null:
		return

	for i in count:

		var drone = resource_data.scene_path.instantiate()

		get_tree().current_scene.add_child(drone)

		drone.follow_target = self

		drone.apply_data(resource_data, backend_drone)

		drones.append(drone)

	emit_signal("drone_added", count)


# -------------------------------------------------
# Upgrades
# -------------------------------------------------

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
