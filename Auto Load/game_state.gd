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
var all_enemies : Array[Enemy] = []
var owned_ship_ids: Array[String] = []
var owned_drone_ids: Array[String] = []
var drop_groups = []
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

func get_ship_by_id(id: String):
	for ship in all_ships:
		if ship.id == id:
			return ship
	return null
	
func return_owned_or_not(mode:String, id:String):
	if mode == "Ships":
		for ship_id in owned_ship_ids:
			if ship_id == id:
				return true
	else:
		for drone_id in owned_drone_ids:
			if drone_id == id:
				return true
	return false

func update_resources(coins: int, exp: int, diamonds: int, level: int):
	user.coins = coins
	user.exp = exp
	user.diamonds = diamonds
	user.level = level

func get_drop_group(name: String):
	for g in drop_groups:
		if g.name == name:
			return g
	return null


func get_random_drop_item(group_name: String):

	var group = get_drop_group(group_name)

	if group == null:
		return null

	var total_weight := 0.0

	for item in group.items:
		if item.is_active:
			total_weight += item.drop_chance_percent

	if total_weight == 0:
		return null

	var roll = randf() * total_weight
	var cumulative := 0.0

	for item in group.items:
		if not item.is_active:
			continue

		cumulative += item.drop_chance_percent

		if roll <= cumulative:
			return item

	return group.items[0]
