extends Area3D

@export var speed := 60.0
@export var life_time := 3.0
@export var damage := 50


func _ready():
	add_to_group("player_bullet")
	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(life_time).timeout
	queue_free()


func _physics_process(delta):
	global_position += -transform.basis.z * speed * delta


func _on_body_entered(body):
	if body.is_in_group("enemy") or body.is_in_group("upgrade"):
		if body.has_method("take_damage"):
			body.take_damage(damage)

	queue_free()
