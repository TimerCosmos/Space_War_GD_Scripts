extends Node

var bootstrap_service = preload("res://Scripts/Services/bootstrap_service.gd").new()
var _on_complete: Callable


func initialize(callback: Callable):
	_on_complete = callback
	bootstrap_service.load_bootstrap(_on_bootstrap_loaded)


func _on_bootstrap_loaded(code, response_text):

	# ---------------------------
	# TOKEN INVALID
	# ---------------------------
	if code == 401:
		GameState.logout()
		get_tree().change_scene_to_file("res://Scenes/StartUp/auth_check.tscn")
		return

	# ---------------------------
	# OTHER ERROR
	# ---------------------------
	if code != 200:
		push_error("Bootstrap failed: " + str(response_text))
		return

	var json = JSON.parse_string(response_text)
	if json == null:
		push_error("Invalid bootstrap response")
		return

	_parse_bootstrap(json)
	_finish()


func _parse_bootstrap(data: Dictionary):

	# ---------------------------
	# USER
	# ---------------------------
	GameState.user = UserProfile.from_dict(data.get("user", {}))
	# ---------------------------
	# SHIPS
	# ---------------------------
	GameState.all_ships.clear()
	for ship_dict in data.get("ships", []):
		GameState.all_ships.append(
			Spaceship.from_dict(ship_dict)
		)
	
	# ---------------------------
	# DRONES
	# ---------------------------
	GameState.all_drones.clear()
	for drone_dict in data.get("drones", []):
		GameState.all_drones.append(
			Drone.from_dict(drone_dict)
		)
	
	GameState.all_enemies.clear()
	for enemy_dict in data.get("enemies", []):
		GameState.all_enemies.append(
			Enemy.from_dict(enemy_dict)
		)
	# ---------------------------
	# ENEMIES (optional for now)
	# ---------------------------
	# You can create Enemy model later and parse here

	# ---------------------------
	# OWNED ITEMS
	# ---------------------------
	GameState.owned_ship_ids = []
	for id in data.get("owned_ship_ids", []):
		GameState.owned_ship_ids.append(str(id))

	GameState.owned_drone_ids = []
	for id in data.get("owned_drone_ids", []):
		GameState.owned_drone_ids.append(str(id))

	GameState.ad_limits.clear()

	for ad_dict in data.get("ads", []):
		var ad = Ad.from_dict(ad_dict)
		GameState.ad_limits[ad.type] = ad

	GameState.high_score = int(data.get("high_score"))
# ---------------------------
# UNCLAIMED LEVEL REWARDS
# ---------------------------

	GameState.unclaimed_level_rewards.clear()

	var rewards_block = data.get("unclaimed_rewards", {})

	var notices = rewards_block.get("notices", [])

	for notice in notices:
		if notice.get("category") == "unclaimed_level_rewards":
			var payload = notice.get("payload",{})
			var details = payload.get("details", [])
			for reward in details:
				GameState.unclaimed_level_rewards.append(reward)

# ---------------------------
# OFFERS
# ---------------------------

	GameState.offers.clear()

	for offer in data.get("offers", []):
		GameState.offers.append(offer)

	# ---------------------------
	# USER OFFERS
	# ---------------------------

	GameState.user_offers.clear()

	for offer in data.get("user_offers", []):
		GameState.user_offers.append(offer)
	_initialize_equipment()

func _initialize_equipment():

	ShipManager.selected_ship_id = GameState.user.default_spaceship_id
	DroneManager.selected_drone_id = GameState.user.default_drone_id

func _finish():
	if _on_complete:
		_on_complete.call()
