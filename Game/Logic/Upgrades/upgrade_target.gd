extends Area3D

@export var max_health := 100
@export var fall_speed := 3.0

var health := 100
var upgrade_type := ""
var upgrade_value := 1

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var label: Label3D = $Label3D


func _ready():
	add_to_group("upgrade")
	health = max_health
	area_entered.connect(_on_area_entered)


func _physics_process(delta):
	# Conveyor downward movement
	global_position.z += fall_speed * delta
	
	# Rotate slowly for visibility
	rotation.y += 2.0 * delta
	label.look_at(
	get_viewport().get_camera_3d().global_position,
	Vector3.UP
)


# ---------------------------------
# Configure upgrade dynamically
# ---------------------------------
func configure(type: String, value: int):
	upgrade_type = type
	upgrade_value = value
	
	label.text = "+" + str(value) + " " + type.capitalize()
	label.scale = Vector3(2.5, 2.5, 2.5)
	label.modulate = Color.WHITE

	apply_visual_style()


# ---------------------------------
# Change color based on upgrade
# ---------------------------------
func apply_visual_style():
	var mat := StandardMaterial3D.new()
	
	match upgrade_type:
		"drone":
			mat.albedo_color = Color(0.3, 0.8, 1.0)   # Cyan
		"damage":
			mat.albedo_color = Color(1.0, 0.3, 0.3)   # Red
		"health":
			mat.albedo_color = Color(0.3, 1.0, 0.3)   # Green
		_:
			mat.albedo_color = Color.WHITE
	
	mat.emission_enabled = true
	mat.emission = mat.albedo_color * 0.6
	
	mesh.material_override = mat


# ---------------------------------
# Damage
# ---------------------------------
func take_damage(amount: int):
	health -= amount
	
	if health <= 0:
		activate_upgrade()
		queue_free()


# ---------------------------------
# Activate upgrade
# ---------------------------------
func activate_upgrade():
	var ship = get_tree().get_first_node_in_group("player")
	
	if ship == null:
		return
	
	match upgrade_type:
		"drone":
			ship.add_drone(upgrade_value)
		"damage":
			ship.increase_damage(upgrade_value)
		"health":
			ship.increase_health(upgrade_value)


func _on_area_entered(area):
	if area.is_in_group("player_bullet"):
		take_damage(area.damage)
		area.queue_free()
