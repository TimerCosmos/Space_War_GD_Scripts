# Api call is needed to get default ship details

extends Node

# ---------------------------------
# Global ship state manager
# Stores selected ship and player runtime state
# ---------------------------------

const FALLBACK_SHIP_DATA_PATH := "res://Data/destroyer.tres"

var selected_ship_data: ShipData = null
var player_ship_state: Dictionary = {}  # DB overrides


# Return selected ship or fallback
func get_selected_ship_data() -> ShipData:
	if selected_ship_data != null:
		return selected_ship_data
	
	return load(FALLBACK_SHIP_DATA_PATH)


# Example: later DB will fill this
func set_player_ship_state(data: Dictionary):
	player_ship_state = data


func get_player_ship_state() -> Dictionary:
	return player_ship_state

# Progressive drop system
const DROP_BASE := 7500


var drop_counter := 0


func should_drop_powerup() -> bool:
	drop_counter += 1
	
	if drop_counter >= DROP_BASE:
		drop_counter = 0
		return true
	
	# small chance before guarantee
	if randf() < (drop_counter / float(DROP_BASE)):
		drop_counter = 0
		return true
	
	return false
