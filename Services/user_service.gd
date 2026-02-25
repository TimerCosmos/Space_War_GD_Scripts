extends Node
class_name UserService

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
