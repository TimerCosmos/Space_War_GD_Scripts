# Api call is needed to get .tres files data

extends Node3D

# For now hardcoded (later replace with DB values)
const SHIP_DATA_PATHS := [
	"res://Data/destroyer.tres",
	"res://Data/ninja.tres"
]

var ships: Array[ShipData] = []
var current_index := 0
var current_ship: SpaceShip = null
var current_ship_data: ShipData = null
var rotation_speed := 0.005

@onready var pivot: Node3D = $ShipPivot
@onready var prev: Button = $CanvasLayer/Control/MarginContainer/ShipScrolls/Prev
@onready var next: Button = $CanvasLayer/Control/MarginContainer/ShipScrolls/Next
@onready var select: Button = $CanvasLayer/Control/MarginContainer/ShipScrolls/Select


func _ready():
	load_ship_data()
	
	if ships.is_empty():
		push_error("No ShipData loaded")
		return

	load_ship(0)


# ------------------------
# Load ShipData dynamically
# ------------------------
func load_ship_data():
	for path in SHIP_DATA_PATHS:
		var data := load(path)
		if data != null:
			ships.append(data)
		else:
			push_warning("Failed to load ShipData at: " + path)


# ------------------------
# Ship Loading
# ------------------------
func load_ship(index: int):
	if current_ship:
		current_ship.queue_free()

	current_ship_data = ships[index]

	if current_ship_data.ship_scene == null:
		push_error("Ship scene missing in ShipData")
		return

	current_ship = current_ship_data.ship_scene.instantiate()
	pivot.add_child(current_ship)

	current_ship.global_transform = pivot.global_transform
	current_ship.apply_data(current_ship_data)

	pivot.rotation = Vector3.ZERO

	update_button_states()


# ------------------------
# Buttons
# ------------------------
func _on_next_button_pressed():
	if current_index < ships.size() - 1:
		current_index += 1
		load_ship(current_index)


func _on_prev_button_pressed():
	if current_index > 0:
		current_index -= 1
		load_ship(current_index)


func _on_select_button_pressed():
	ShipManager.selected_ship_data = current_ship_data
	SceneManager.goto_scene("res://Scenes/game.tscn")


func update_button_states():
	fade_button(prev, current_index > 0)
	fade_button(next, current_index < ships.size() - 1)


func fade_button(button: Button, enable: bool):
	button.disabled = !enable
	var target_alpha := 1.0 if enable else 0.3

	var tween := create_tween()
	tween.tween_property(button, "modulate:a", target_alpha, 0.25)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)


# ------------------------
# Rotation
# ------------------------
func _input(event):
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		pivot.rotate_y(event.relative.x * rotation_speed)
		pivot.rotate_x(-event.relative.y * rotation_speed)
