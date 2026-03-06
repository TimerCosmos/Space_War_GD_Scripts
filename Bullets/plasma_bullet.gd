extends Area3D

@export var speed := 60.0
@export var life_time := 3.0

var damage : int = 0

var enemy_manager = null


func _ready():

	add_to_group("player_bullet")

	# upgrades are still CharacterBody3D
	body_entered.connect(_on_body_entered)

	enemy_manager = get_tree().get_first_node_in_group("enemy_manager")

	await get_tree().create_timer(life_time).timeout
	queue_free()


func _process(delta):

	# move bullet
	global_position += -transform.basis.z * speed * delta
	enemy_manager.check_hit(global_position, damage)
	# check swarm enemies
	if enemy_manager:

		var hit = enemy_manager.check_hit(global_position, damage)

		if hit:
			queue_free()


# -----------------------------------
# Upgrade targets (CharacterBody3D)
# -----------------------------------
func _on_body_entered(body):

	if body.is_in_group("upgrade"):

		if body.has_method("take_damage"):
			body.take_damage(damage)

	queue_free()
