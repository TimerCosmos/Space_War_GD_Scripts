extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_skilltree_pressed():
	GameState.garage_mode = GameState.GarageMode.DRONES
	#SceneManager.goto_scene("res://Scenes/Rewards/rewards.tscn")
	SceneManager.goto_scene("res://Scenes/Game Upgrades/skill_tree.tscn")
