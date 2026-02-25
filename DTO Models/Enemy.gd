extends RefCounted
class_name Enemy

var id: String
var name: String
var base_health: int
var collision_damage: int
var speed: float
var spawn_percentage: float
var tres_file_path: String
var scene_path: String
var is_active: bool
static func from_dict(data: Dictionary) -> Enemy:
	var e = Enemy.new()
	e.id = data.get("id", "")
	e.name = data.get("name", "")
	e.base_health = data.get("base_health", 100)
	e.collision_damage = data.get("collision_damage", 10)
	e.speed = data.get("speed", 1.0)
	e.spawn_percentage = data.get("spawn_percentage", 100.0)
	e.tres_file_path = data.get("tres_file_path", "")
	e.scene_path = data.get("scene_path", "")
	e.is_active = data.get("is_active","")
	return e
