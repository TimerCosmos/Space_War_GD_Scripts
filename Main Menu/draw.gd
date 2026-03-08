extends Button


# Called when the node enters the scene tree for the first time.
func _on_draw_pressed():
	SceneManager.goto_scene("res://Scenes/Rewards/draw.tscn")
