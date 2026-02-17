# No api call is needed

extends Control

@onready var settings_pop_up: PopupPanel = $SettingsPopUp
@onready var settings: Button = $MarginContainer/Settings/Settings
@onready var destroyer: CharacterBody3D = $"../../destroyer"
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)



func _on_settings_button_pressed():
	settings_pop_up.visible = true
	settings_pop_up.popup_centered()


func close_settings():
	settings_pop_up.visible = false

func _on_dimmer_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		close_settings()
