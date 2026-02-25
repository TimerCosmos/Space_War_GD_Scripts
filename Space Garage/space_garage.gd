extends Node3D

# -------------------------------------------------
# Generic Garage Viewer (Ships + Drones)
# -------------------------------------------------

enum GarageMode { SHIPS, DRONES }
var mode = GarageMode.SHIPS

# -------------------------------------------------
# Runtime State
# -------------------------------------------------

var items: Array = []                 # Can contain ShipData OR DroneData
var current_index := 0
var current_item = null     # Generic resource
var current_preview: Node3D = null    # Instantiated 3D preview

var rotation_speed := 0.005


# -------------------------------------------------
# Node References
# -------------------------------------------------

@onready var pivot: Node3D = $ShipPivot
@onready var select: Button = $CanvasLayer/Control/MarginContainer/ShipScrolls/Select
@onready var prev: Button = $CanvasLayer/Control/HBoxContainer/PreviewArea/MarginContainer/ShipScrolls/Prev
@onready var next: Button = $CanvasLayer/Control/HBoxContainer/PreviewArea/MarginContainer/ShipScrolls/Next
@onready var hit_points: Label = $"CanvasLayer/Control/StatsPanel/MarginContainer/VBoxContainer/Hit Points"
@onready var damage: Label = $CanvasLayer/Control/StatsPanel/MarginContainer/VBoxContainer/Damage
@onready var hit_rate: Label = $"CanvasLayer/Control/StatsPanel/MarginContainer/VBoxContainer/Hit Rate"
@onready var title: Label = $CanvasLayer/Control/HBoxContainer/PreviewArea/MarginContainer/Back/Title
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# -------------------------------------------------
# Ready
# -------------------------------------------------

func _ready():
	load_data()

	if items.is_empty():
		push_error("No data loaded for garage")
		return
		
	load_item(0)


# -------------------------------------------------
# Load Data (Ships or Drones)
# -------------------------------------------------

func load_data():
	items.clear()

	mode = GameState.garage_mode
	if mode == GarageMode.SHIPS:
		for ship in GameState.all_ships:
			items.append(ship)
	else:
		for drone in GameState.all_drones:
			items.append(drone)
		print(items)

func update_stats_display(data):
	title.text = data.name
	hit_points.text = "Health: " + str(data.base_health)
	damage.text = "Damage: " + str(data.base_damage)
	hit_rate.text = "Hit Rate: " + str(data.base_hit_rate)

# -------------------------------------------------
# Load Preview Item
# -------------------------------------------------

func load_item(index: int):

	if current_preview:
		current_preview.queue_free()

	current_item = items[index]

	if mode == GarageMode.SHIPS:

		var backend_ship = current_item
		var resource_data: ShipData = load(backend_ship.tres_file_path)

		if resource_data == null or resource_data.ship_scene == null:
			push_error("Invalid Ship resource")
			return

		current_preview = resource_data.ship_scene.instantiate()
		current_preview.apply_data(resource_data, backend_ship)

		update_stats_display(backend_ship)

	else:

		var backend_drone = current_item
		var resource_data: DroneData = load(backend_drone.tres_file_path)

		if resource_data == null or resource_data.scene_path == null:
			push_error("Invalid Drone resource")
			return

		current_preview = resource_data.scene_path.instantiate()
		current_preview.apply_data(resource_data, backend_drone)

		update_stats_display(backend_drone)

	pivot.add_child(current_preview)
	current_preview.global_transform = pivot.global_transform
	pivot.rotation = Vector3.ZERO

	update_button_states()


# -------------------------------------------------
# Buttons
# -------------------------------------------------

func _on_next_button_pressed():
	if current_index < items.size() - 1:
		current_index += 1
		load_item(current_index)
		load_animation()

func _on_prev_button_pressed():
	if current_index > 0:
		current_index -= 1
		load_item(current_index)
		load_animation()


func _on_select_button_pressed():

	if mode == GarageMode.SHIPS:
		var backend_ship = current_item   # DTO
		UserService.set_default_spaceship(
			backend_ship.id,
			_on_default_ship_updated
		)
	else:
		var backend_drone = current_item
		UserService.set_default_drone(
			backend_drone.id,
			_on_default_drone_updated
		)

func _on_default_ship_updated(code, response_text):

	if code != 200:
		print("Failed to set default ship")
		return

	var json = JSON.parse_string(response_text)
	if json == null:
		return

	# Update GameState user
	GameState.user = UserProfile.from_dict(json)

	# Update ShipManager
	ShipManager.selected_ship_id = GameState.user.default_spaceship_id

	SceneManager.goto_scene("res://Scenes/game.tscn")

func _on_default_drone_updated(code, response_text):

	if code != 200:
		print("Failed to set default drone")
		return

	var json = JSON.parse_string(response_text)
	if json == null:
		return

	GameState.user = UserProfile.from_dict(json)

	DroneManager.selected_drone_id = GameState.user.default_drone_id
	
func load_animation():
	animation_player.play("shippivot")

# -------------------------------------------------
# UI Helpers
# -------------------------------------------------

func update_button_states():
	fade_button(prev, current_index > 0)
	fade_button(next, current_index < items.size() - 1)


func fade_button(button: Button, enable: bool):
	button.disabled = !enable

	var target_alpha := 1.0 if enable else 0.3
	var tween := create_tween()

	tween.tween_property(button, "modulate:a", target_alpha, 0.25)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)


# -------------------------------------------------
# Rotation
# -------------------------------------------------

func _input(event):
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		pivot.rotate_y(event.relative.x * rotation_speed)
		pivot.rotate_x(-event.relative.y * rotation_speed)
