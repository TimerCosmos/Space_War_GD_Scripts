extends CharacterBody3D

@export var max_health := 100
@export var speed := 1.0
@export var damage := 20
signal enemy_destroyed

var health := 100


func _ready():
	add_to_group("enemy")
	health = max_health


func _physics_process(delta):
	global_position.z += speed * delta


func take_damage(amount: int):
	health -= amount
	if health <= 0:
		die()


func die():
	emit_signal("enemy_destroyed")
	queue_free()


func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(damage)
	queue_free()
