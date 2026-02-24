# No api call is needed

extends Node3D

@onready var ship_pivot: Node3D = $ShipPivot
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var current_ship: SpaceShip = null


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	spawn_menu_ship()


func spawn_menu_ship():
	if current_ship:
		current_ship.queue_free()

	var ship_data: ShipData = ShipManager.get_selected_ship_data()

	if ship_data == null:
		push_error("No ShipData available for Main Menu")
		return

	if ship_data.ship_scene == null:
		push_error("ShipData missing ship_scene")
		return

	current_ship = ship_data.ship_scene.instantiate()
	ship_pivot.add_child(current_ship)

	current_ship.global_transform = ship_pivot.global_transform

	# Inject data (IMPORTANT)
	current_ship.apply_data(ship_data, null)
