class_name UserProfile
extends RefCounted

var id: String
var email: String
var name: String
var default_spaceship_id: String
var default_drone_id: String
var level: int
var exp: int
var coins: int
var diamonds: int
var exp_tokens: int
var is_active: bool
var created_at: String


static func from_dict(data: Dictionary) -> UserProfile:
	var user = UserProfile.new()

	user.id = data.get("id", "")
	user.email = data.get("email", "")
	user.name = data.get("name", "")
	user.default_spaceship_id = data.get("default_spaceship_id", "")
	user.default_drone_id = data.get("default_drone_id","")
	user.level = data.get("level", 1)
	user.exp = data.get("exp", 0)
	user.coins = data.get("coins", 0)
	user.diamonds = data.get("diamonds", 0)
	user.exp_tokens = data.get("exp_tokens", 0)
	user.is_active = data.get("is_active", false)
	user.created_at = data.get("created_at", "")

	return user
