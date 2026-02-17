## No api call is needed

extends Resource
class_name ShipData

# ----------------------------
# Static ship definition
# This file is used as a base template.
# DO NOT modify this at runtime.
# ----------------------------

@export var ship_id: String
@export var ship_name: String

# Base stats
@export var max_health := 200
@export var speed := 8.0
@export var fire_rate := 0.12
@export var bullet_damage := 50

# Movement limits
@export var min_x := -8.0
@export var max_x := 8.0

# Scene references
@export var ship_scene: PackedScene
@export var preview_scene: PackedScene

# Optional (recommended)
@export var bullet_scene: PackedScene
