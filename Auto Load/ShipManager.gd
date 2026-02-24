extends Node

# ---------------------------------
# Global ship state manager
# Handles ship selection & resolution
# ---------------------------------

const FALLBACK_SHIP_DATA_PATH := "res://Data/destroyer.tres"

# Selected ship ID (from garage)
var selected_ship_id: String = ""

# Persistent player runtime bonuses (if needed)
var player_ship_state: Dictionary = {}

# ---------------------------------
# Get Selected Ship Resource
# ---------------------------------

func get_selected_ship_data() -> ShipData:

	# Determine which ID to use
	var ship_id := selected_ship_id

	# If nothing selected manually, use backend default
	if ship_id == "":
		if GameState.user != null:
			ship_id = GameState.user.default_spaceship_id

	# Resolve DTO
	var backend_ship = _find_ship_by_id(ship_id)

	if backend_ship == null:
		return _load_fallback()

	if backend_ship.tres_file_path == "":
		return _load_fallback()

	var resource: ShipData = load(backend_ship.tres_file_path)
	return resource if resource != null else _load_fallback()


# ---------------------------------
# Get Backend Ship DTO
# ---------------------------------

func get_selected_backend_ship():
	var ship_id := selected_ship_id

	if ship_id == "":
		if GameState.user != null:
			ship_id = GameState.user.default_spaceship_id

	return _find_ship_by_id(ship_id)


# ---------------------------------
# Internal Helpers
# ---------------------------------

func _find_ship_by_id(id: String):
	for ship in GameState.all_ships:
		if ship.id == id:
			return ship
	return null


func _load_fallback() -> ShipData:
	return load(FALLBACK_SHIP_DATA_PATH)


# ---------------------------------
# Player Runtime State (Optional)
# ---------------------------------

func set_player_ship_state(data: Dictionary):
	player_ship_state = data


func get_player_ship_state() -> Dictionary:
	return player_ship_state


# ---------------------------------
# Progressive Drop System
# ---------------------------------

const DROP_BASE := 7500
var drop_counter := 0


func should_drop_powerup() -> bool:
	drop_counter += 1

	if drop_counter >= DROP_BASE:
		drop_counter = 0
		return true

	if randf() < (drop_counter / float(DROP_BASE)):
		drop_counter = 0
		return true

	return false
