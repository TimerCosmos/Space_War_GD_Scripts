# No api call is needed

extends Node

# Stores the file paths of visited scenes
var scene_history: Array = []

# Call this instead of change_scene_to_file
func goto_scene(path: String):
	# Save current scene before moving
	scene_history.push_back(get_tree().current_scene.scene_file_path)
	get_tree().change_scene_to_file(path)

# Logic for the "Back" button
func go_back():
	if scene_history.size() > 0:
		var previous_scene = scene_history.pop_back()
		get_tree().change_scene_to_file(previous_scene)
	else:
		print("No history available!")
