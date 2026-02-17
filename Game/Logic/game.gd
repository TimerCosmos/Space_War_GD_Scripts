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


func spawn_player_ship():
	var base_data: ShipData = ShipManager.get_selected_ship_data()
	var player_data: Dictionary = ShipManager.get_player_ship_state()

	if base_data == null:
		push_error("No ShipData available!")
		return

	if base_data.ship_scene == null:
		push_error("ShipData missing ship_scene!")
		return

	ship_instance = base_data.ship_scene.instantiate()
	ship_pivot.add_child(ship_instance)

	ship_instance.global_transform = ship_pivot.global_transform

	# Inject stats
	ship_instance.apply_data(base_data, player_data)

	# Connect destruction
	ship_instance.ship_destroyed.connect(_on_ship_destroyed)

	# Tell spawner who to target
	#enemy_spawner.player = ship_instance


func _on_ship_destroyed():
	print("Game detected ship death")
	
	var game_over_ui = get_tree().get_first_node_in_group("game_over")
	
	if game_over_ui:
		game_over_ui.show_game_over(score)
