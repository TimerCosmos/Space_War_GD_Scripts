# Api call is not needed

extends Node

var selected_ship_data = null
var selected_drone_data: DroneData

enum GarageMode { SHIPS, DRONES	}
var garage_mode : GarageMode 

var pending_card_chances: int = 0
var available_cards: Array = [] 

var access_token: String = ""
var user_data: UserProfile
var user: UserProfile = null
var all_ships: Array[Spaceship] = []
var all_drones: Array[Drone] = []

var owned_ship_ids: Array[String] = []
var owned_drone_ids: Array[String] = []

func set_session(token: String, user: Dictionary):
	access_token = token
	user_data = UserProfile.from_dict(user)

func is_logged_in() -> bool:
	return access_token != ""

func logout():
	access_token = ""
	user_data = null
	
	if FileAccess.file_exists("user://session.save"):
		DirAccess.remove_absolute("user://session.save")
		
		
func restore_session(token: String):
	access_token = token
	
func is_ship_owned(ship_id: String) -> bool:
	return ship_id in owned_ship_ids
	
func get_drone_by_id(id: String):
	for drone in all_drones:
		if drone.id == id:
			return drone
	return null
	
