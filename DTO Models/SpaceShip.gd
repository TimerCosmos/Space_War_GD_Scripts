class_name Spaceship
extends RefCounted

var id: String
var name: String

var rarity_id: String
var type_id: String

var base_health: int
var base_damage: int
var base_hit_rate: float
var base_speed: float

var max_drones: int

var tres_file_path: String
var scene_path: String

var is_active: bool


static func from_dict(data: Dictionary) -> Spaceship:
	var ship = Spaceship.new()

	ship.id = str(data.get("id", ""))
	ship.name = str(data.get("name", ""))

	var rarity = data.get("rarity_id")
	ship.rarity_id = str(rarity) if rarity != null else ""

	var type_val = data.get("type_id")
	ship.type_id = str(type_val) if type_val != null else ""

	ship.base_health = int(data.get("base_health", 0))
	ship.base_damage = int(data.get("base_damage", 0))

	var hit_rate = data.get("base_hit_rate")
	ship.base_hit_rate = float(hit_rate) if hit_rate != null else 0.0

	var speed = data.get("base_speed")
	ship.base_speed = float(speed) if speed != null else 0.0

	var drones = data.get("max_drones")
	ship.max_drones = int(drones) if drones != null else 0

	var tres = data.get("tres_file_path")
	ship.tres_file_path = str(tres) if tres != null else ""

	var scene = data.get("scene_path")
	ship.scene_path = str(scene) if scene != null else ""

	ship.is_active = bool(data.get("is_active", false))

	return ship
