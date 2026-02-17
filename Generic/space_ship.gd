extends CharacterBody3D
class_name SpaceShip

signal ship_destroyed

# Runtime data
var ship_data: ShipData
var current_health: int

@onready var muzzle: Marker3D = $Marker3D

# Drone system
var drones: Array = []

# Control state
var controls_enabled := false
var is_holding := false
var fire_timer := 0.0
var target_tilt := 0.0


# -------------------------------------------------
# Apply ShipData safely (duplicate .tres)
# -------------------------------------------------
func apply_data(base_data: ShipData, player_data: Dictionary = {}):
	ship_data = base_data.duplicate(true)

	var final_health = ship_data.max_health
	var final_fire_rate = ship_data.fire_rate
	var final_damage = ship_data.bullet_damage

	if player_data.has("bonus_health"):
		final_health += player_data["bonus_health"]

	if player_data.has("bonus_fire_rate"):
		final_fire_rate += player_data["bonus_fire_rate"]

	if player_data.has("bonus_damage"):
		final_damage += player_data["bonus_damage"]

	ship_data.max_health = final_health
	ship_data.fire_rate = final_fire_rate
	ship_data.bullet_damage = final_damage

	current_health = final_health
	update_health_ui()


# -------------------------------------------------
# Ready
# -------------------------------------------------
func _ready():
	add_to_group("player")

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
		var new_x = global_position.x + event.relative.x * ship_data.speed * 0.01
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
		fire_timer = ship_data.fire_rate


# -------------------------------------------------
# Shoot (always 1 bullet)
# -------------------------------------------------
func shoot():
	if ship_data == null or ship_data.bullet_scene == null:
		return

	var bullet = ship_data.bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_transform = muzzle.global_transform


# -------------------------------------------------
# Drone System
# -------------------------------------------------
func add_drone(count: int):
	for i in count:
		var drone_scene = preload("res://Scenes/Shooters/shooter.tscn")
		var drone = drone_scene.instantiate()
		get_tree().current_scene.add_child(drone)
		drone.follow_target = self
		drones.append(drone)



func increase_damage(amount: int):
	ship_data.bullet_damage += amount


func increase_health(amount: int):
	ship_data.max_health += amount
	current_health += amount
	update_health_ui()


# -------------------------------------------------
# Health
# -------------------------------------------------
func take_damage(amount: int):
	current_health = max(current_health - amount, 0)
	update_health_ui()

	if current_health <= 0:
		die()


func update_health_ui():
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.update_health(current_health, ship_data.max_health)


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
