extends CharacterBody3D
class_name EnemyNode

signal enemy_destroyed

var runtime_health: float
var runtime_damage: float
var runtime_speed: float
@onready var groster: MeshInstance3D = $Groster

func _ready():
	add_to_group("enemy")

func apply_backend_data(dto: Enemy):
	runtime_health = dto.base_health
	runtime_damage = dto.collision_damage
	runtime_speed = dto.speed
	
	if dto.name == "Red Giant":
		_apply_color(Color.RED)

func _apply_color(color: Color):
	var mesh: MeshInstance3D = groster
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.5
	
	mesh.material_override = material
	
func apply_scaling(health_mult: float, damage_mult: float):
	runtime_health *= health_mult
	runtime_damage *= damage_mult

func _physics_process(delta):
	global_position.z += runtime_speed * delta

func take_damage(amount: int):
	runtime_health -= amount
	if runtime_health <= 0:
		die()

func die():
	emit_signal("enemy_destroyed")
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(runtime_damage)
	queue_free()
