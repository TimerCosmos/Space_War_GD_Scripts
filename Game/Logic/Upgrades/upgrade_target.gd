extends Area3D

@export var max_health := 100
@export var fall_speed := 1.0

var health := 100
var upgrade_type := ""
var upgrade_value := 1

@onready var health_bar: Sprite3D = $HealthBar
@onready var label: Label3D = $Label3D
@onready var energy_field: MeshInstance3D = $EnergyField

# Frame parts
@onready var left_wall: MeshInstance3D = $LeftWall
@onready var right_wall: MeshInstance3D = $RightWall
@onready var bottom_wall: MeshInstance3D = $BottomWall

func _ready():
	add_to_group("upgrade")
	health = max_health

	area_entered.connect(_on_area_entered)

	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED

	update_health_bar()


func _physics_process(delta):

	# Conveyor downward movement
	global_position.z += fall_speed * delta



# ---------------------------------
# Configure upgrade dynamically
# ---------------------------------

func configure_from_backend(item: Dictionary):

	upgrade_type = item["item_type"]
	upgrade_value = int(item["value"])

	max_health = int(item["health"])
	health = max_health

	label.text = "+" + str(upgrade_value) + " " + upgrade_type.capitalize()
	label.scale = Vector3(2.5, 2.5, 2.5)
	label.modulate = Color.WHITE

	apply_visual_style()



# ---------------------------------
# Change color based on upgrade
# ---------------------------------

func apply_visual_style():

	var mat := StandardMaterial3D.new()

	match upgrade_type:

		"Drones":
			mat.albedo_color = Color(0.3, 0.8, 1.0)

		"Damage":
			mat.albedo_color = Color(1.0, 0.3, 0.3)

		"Health":
			mat.albedo_color = Color(0.3, 1.0, 0.3)

		_:
			mat.albedo_color = Color.WHITE


	mat.emission_enabled = true
	mat.emission = mat.albedo_color * 0.6

	# Apply to frame pieces only
	left_wall.material_override = mat
	right_wall.material_override = mat
	bottom_wall.material_override = mat
	
	# Flash effect
	mat.emission_energy = 5
	await get_tree().create_timer(0.1).timeout
	mat.emission_energy = 1



# ---------------------------------
# Damage
# ---------------------------------

func take_damage(amount: int):

	health -= amount
	update_health_bar()
	# Save original scale
	var original_scale := energy_field.scale
	
	# Flash energy field
	energy_field.scale = Vector3.ZERO

	await get_tree().create_timer(0.07).timeout
		# Restore visuals
	energy_field.scale = original_scale



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

		"Drones":
			ship.add_drone(upgrade_value)

		"Damage":
			ship.increase_damage(upgrade_value)

		"Health":
			ship.increase_health(upgrade_value)



# ---------------------------------
# Bullet collision
# ---------------------------------

func _on_area_entered(area):

	if area.is_in_group("player_bullet"):
		if(area.can_hit_upgrades):			
			take_damage(area.damage)
			area.queue_free()



# ---------------------------------
# Health bar
# ---------------------------------

func update_health_bar():

	var ratio = float(health) / float(max_health)

	health_bar.scale.x = ratio * 8.0
	
