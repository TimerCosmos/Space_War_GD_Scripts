extends Control
@onready var margin_container: MarginContainer = $"../MenuRoot/MarginContainer"
func show_popup():
	visible = true

func hide_popup():
	visible = false
	margin_container.visible = true

func _on_close_pressed():
	hide_popup()
