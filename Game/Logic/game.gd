# No api call is needed

extends Node3D

# ----------------------------
# Main game controller
# Spawns ship and connects systems
# ----------------------------

@onready var ship_pivot: Node3D = $ShipPivot
@onready var enemy_spawner = $EnemySpawner
@onready var game_over : Control = $CanvasLayer/GameOver

var ship_instance: SpaceShip = null
var score := 0

func _ready():
	spawn_player_ship()

func add_score(amount: int):
	score += amount
	
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.update_score(score)

func _on_health_changed(current, max):
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.update_health(current, max)

func _on_damage_changed(damage):
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.update_damage(damage)
		
func _on_drone_count_change(value):
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.update_drone_count(value)

func spawn_player_ship():
	var resource_data: ShipData = ShipManager.get_selected_ship_data()
	var player_data: Dictionary = ShipManager.get_player_ship_state()

	if resource_data == null:
		push_error("No ShipData available!")
		return

	# Get backend DTO
	var ship_id = GameState.user.default_spaceship_id
	var backend_ship = GameState.get_ship_by_id(ship_id)

	if backend_ship == null:
		push_error("Backend ship not found!")
		return

	ship_instance = resource_data.ship_scene.instantiate()
	ship_pivot.add_child(ship_instance)

	ship_instance.global_transform = ship_pivot.global_transform

	# Inject BOTH
	ship_instance.apply_data(resource_data, backend_ship, player_data)

	ship_instance.health_changed.connect(_on_health_changed)
	ship_instance.ship_destroyed.connect(_on_ship_destroyed)
	ship_instance.damage_changed.connect(_on_damage_changed)
	ship_instance.drone_added.connect(_on_drone_count_change)
	# Tell spawner who to target
	#enemy_spawner.player = ship_instance


func _on_ship_destroyed():
	print("Game detected ship death")
	
	var game_over_ui = get_tree().get_first_node_in_group("game_over")
	
	if game_over_ui:
		game_over_ui.show_game_over(score)
