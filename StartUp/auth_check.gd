extends Node

func _ready():
	var token = load_token()

	if token == "":
		get_tree().change_scene_to_file("res://Scenes/Startup/login.tscn")
	else:
		GameState.access_token = token
		get_tree().change_scene_to_file("res://Scenes/Startup/loading.tscn")


func load_token() -> String:
	if not FileAccess.file_exists("user://session.save"):
		return ""

	var file = FileAccess.open("user://session.save", FileAccess.READ)
	var token = file.get_as_text()
	file.close()
	return token
