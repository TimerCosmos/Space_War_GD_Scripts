extends Node

func _ready():
	GameInitializer.initialize(_on_bootstrap_ready)


func _on_bootstrap_ready():
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
