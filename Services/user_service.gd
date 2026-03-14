extends Node
class_name UserService


# -------------------------------------------------
# Default Selection
# -------------------------------------------------

static func set_default_spaceship(ship_id: String, callback: Callable):
	var body = {
		"spaceship_id": ship_id
	}

	ApiClient.patch_with_auth(
		"/api/v1/users/default-spaceship",
		body,
		callback
	)


static func set_default_drone(drone_id: String, callback: Callable):
	var body = {
		"drone_id": drone_id
	}

	ApiClient.patch_with_auth(
		"/api/v1/users/default-drone",
		body,
		callback
	)


# -------------------------------------------------
# Upgrade Preview
# -------------------------------------------------

static func get_spaceship_upgrade_preview(id: String, callback: Callable):
	ApiClient.get_with_auth(
		"/api/v1/spaceships/%s/upgrade-preview" % id,
		callback
	)


static func get_drone_upgrade_preview(id: String, callback: Callable):
	ApiClient.get_with_auth(
		"/api/v1/drones/%s/upgrade-preview" % id,
		callback
	)


# -------------------------------------------------
# Upgrade Action
# -------------------------------------------------

static func upgrade_spaceship(id: String, stat_type: String, upgrades_count: int, callback: Callable):

	var body = {
		"stat_type": stat_type,
		"upgrades_count": upgrades_count
	}

	ApiClient.post_with_auth(
		"/api/v1/spaceships/%s/upgrade" % id,
		body,
		callback
	)

static func upgrade_drone(id: String, stat_type: String,upgrades_count: int, callback: Callable):

	var body = {
		"stat_type": stat_type,
		"upgrades_count" : upgrades_count
	}

	ApiClient.post_with_auth(
		"/api/v1/drones/%s/upgrade" % id,
		body,
		callback
	)

static func buy_spaceship(id: String, callback: Callable):
	ApiClient.post_with_auth(
		"/api/v1/spaceships/%s/buy" % id,
		{},
		callback
	)

static func buy_drone(id: String, callback: Callable):
	ApiClient.post_with_auth(
		"/api/v1/drones/%s/buy" % id,
		{},
		callback
	)
	
static func get_permanent_upgrade_catalog(callback: Callable):
	ApiClient.get_with_auth("/api/v1/permanent-upgrades-v2/catalog", callback) 
	
static func reset_permanent_upgrades(callback : Callable):
	ApiClient.post_with_auth("/api/v1/permanent-upgrades-v2/reset", {},callback)
	
static func buy_permanent_upgrade(Callback : Callable, permanent_upgrade_id : String):
	ApiClient.post_with_auth("/api/v1/permanent-upgrades-v2/%s/upgrade" % permanent_upgrade_id, {}, Callback)
	
static func get_draw_state(Callback:Callable):
	ApiClient.get_with_auth("/api/v1/card-draw/state", Callback)
	
static func start_round(Callback:Callable):
	ApiClient.post_with_auth("/api/v1/card-draw/rounds/start", {},Callback)

static func pick_card(round_id:String, payload, Callback:Callable):
	ApiClient.post_with_auth("/api/v1/card-draw/rounds/%s/pick" % round_id, payload, Callback)
	
static func claim_result(id,Callback:Callable):
	ApiClient.post_with_auth( "/api/v1/card-draw/pending/%s/claim" % id,{},Callback)
	
static func claim_level_rewards(callback: Callable):
	ApiClient.post_with_auth("/api/v1/users/rewards/levels/claim", {}, callback)
	
static func get_shop_items(callback : Callable):
	ApiClient.get_with_auth("/api/v1/shop/items", callback)
