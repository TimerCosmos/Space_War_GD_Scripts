# Api call is needed to know the arm delay and damage of hitting enemy

extends Area3D

@export var damage := 20
@export var arm_delay := 0.3

func _ready():
	# Always connect FIRST
	body_entered.connect(_on_body_entered)

	# Disable collision initially
	monitoring = false

	# Arm after delay
	await get_tree().create_timer(arm_delay).timeout
	monitoring = true

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage)

	get_parent().queue_free()
