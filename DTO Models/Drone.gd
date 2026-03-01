class_name Drone
extends RefCounted

var id: String
var name: String

var rarity: String
var type: String

var base_health: int
var base_damage: int
var base_hit_rate: float

var resource_type : String
var cost : int
var tres_file_path: String
var scene_path: String

var is_active: bool


static func from_dict(data: Dictionary) -> Drone:
	var drone = Drone.new()

	drone.id = str(data.get("id", ""))
	drone.name = str(data.get("name", ""))

	var rarity = data.get("rarity")
	drone.rarity = str(rarity) if rarity != null else ""

	var type_val = data.get("type")
	drone.type = str(type_val) if type_val != null else ""

	drone.base_health = int(data.get("base_health", 0))
	drone.base_damage = int(data.get("base_damage", 0))

	var hit_rate = data.get("base_hit_rate")
	drone.base_hit_rate = float(hit_rate) if hit_rate != null else 0.0

	var tres = data.get("tres_file_path")
	drone.tres_file_path = str(tres) if tres != null else ""
	
	var resource_type = data.get("resource_type")
	drone.resource_type = str(resource_type) if resource_type != null else "Coins"
	
	var cost = data.get("cost")
	drone.cost = int(cost) if cost != null else 0
	var scene = data.get("scene_path")
	drone.scene_path = str(scene) if scene != null else ""

	drone.is_active = bool(data.get("is_active", false))

	return drone
