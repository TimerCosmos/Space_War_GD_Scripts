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

static func upgrade_drone(id: String, stat_type: String, upgrades_count: int, callback: Callable):

	var body = {
		"stat_type": stat_type,
		"upgrades_count": upgrades_count
	}

	ApiClient.post_with_auth(
		"/api/v1/drones/%s/upgrade" % id,
		body,
		callback
	)


# -------------------------------------------------
# BUY (FIXED BODY)
# -------------------------------------------------

static func buy_spaceship(id: String, callback: Callable):
	var body = {
		"buy": true,
		"type": "spaceship"
	}

	ApiClient.post_with_auth(
		"/api/v1/spaceships/%s/buy" % id,
		body,
		callback
	)

static func buy_drone(id: String, callback: Callable):
	var body = {
		"buy": true,
		"type": "drone"
	}

	ApiClient.post_with_auth(
		"/api/v1/drones/%s/buy" % id,
		body,
		callback
	)


# -------------------------------------------------
# Permanent Upgrades
# -------------------------------------------------

static func get_permanent_upgrade_catalog(callback: Callable):
	ApiClient.get_with_auth("/api/v1/permanent-upgrades-v2/catalog", callback)


static func reset_permanent_upgrades(callback: Callable):
	var body = {
		"reset": true
	}

	ApiClient.post_with_auth(
		"/api/v1/permanent-upgrades-v2/reset",
		body,
		callback
	)


static func buy_permanent_upgrade(callback: Callable, permanent_upgrade_id: String):
	var body = {
		"upgrade": true,
		"id": permanent_upgrade_id
	}

	ApiClient.post_with_auth(
		"/api/v1/permanent-upgrades-v2/%s/upgrade" % permanent_upgrade_id,
		body,
		callback
	)


# -------------------------------------------------
# Card Draw
# -------------------------------------------------

static func get_draw_state(callback: Callable):
	ApiClient.get_with_auth("/api/v1/card-draw/state", callback)


static func start_round(callback: Callable):
	var body = {
		"start": true
	}

	ApiClient.post_with_auth(
		"/api/v1/card-draw/rounds/start",
		body,
		callback
	)


static func pick_card(round_id: String, payload, callback: Callable):
	ApiClient.post_with_auth(
		"/api/v1/card-draw/rounds/%s/pick" % round_id,
		payload,
		callback
	)


static func claim_result(id, callback: Callable):
	var body = {
		"claim": true
	}

	ApiClient.post_with_auth(
		"/api/v1/card-draw/pending/%s/claim" % id,
		body,
		callback
	)


# -------------------------------------------------
# Rewards / Shop
# -------------------------------------------------

static func claim_level_rewards(callback: Callable):
	var body = {
		"claim": true,
		"type": "level_rewards"
	}

	ApiClient.post_with_auth(
		"/api/v1/users/rewards/levels/claim",
		body,
		callback
	)


static func get_shop_items(callback: Callable):
	ApiClient.get_with_auth("/api/v1/shop/items", callback)

# -------------------------------------------------
# Leaderboard
# -------------------------------------------------

static func get_leaderboard(callback: Callable):
	ApiClient.get_with_auth(
		"/api/v1/leaderboard",
		callback
	)
	
static func update_name(name: String, callback: Callable):
	var body = {
		"username": name
	}

	ApiClient.patch_with_auth(
		"/api/v1/auth/player/name",
		body,
		callback
	)
