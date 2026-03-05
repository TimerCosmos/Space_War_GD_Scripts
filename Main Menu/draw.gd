extends Button


# Called when the node enters the scene tree for the first time.
func _on_draw_pressed():
	GameState.garage_mode = GameState.GarageMode.DRONES
	print("Hello")
	SceneManager.goto_scene("res://Scenes/Rewards/draw.tscn")
