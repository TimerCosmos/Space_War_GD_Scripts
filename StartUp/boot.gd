extends Node

func _ready():
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Scenes/Startup/splash.tscn")
