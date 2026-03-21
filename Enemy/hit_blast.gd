extends Node3D

@onready var particles = $GPUParticles3D

func _ready():

	particles.emitting = true

	# wait for actual lifetime
	await get_tree().create_timer(particles.lifetime).timeout

	# STOP emission (important)
	particles.emitting = false

	# small buffer so last particles disappear
	await get_tree().create_timer(0.1).timeout

	queue_free()
