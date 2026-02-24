extends Resource
class_name ShipData

@export var ship_id: String
@export var ship_name: String

# Visual / scene references only
@export var ship_scene: PackedScene
@export var preview_scene: PackedScene
@export var bullet_scene: PackedScene
@export var default_drone_data: DroneData

# Optional movement limits (visual tuning)
@export var min_x := -8.0
@export var max_x := 8.0
