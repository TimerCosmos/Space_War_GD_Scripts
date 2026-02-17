#No api call is needed

extends Button

#To go to the previous screen
func _on_pressed() -> void:
	SceneManager.go_back()
