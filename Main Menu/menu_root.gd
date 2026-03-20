# No api call is needed

extends Control
@onready var shop: Button = $MarginContainer/MainMenuContainer/ShopsAndOffers/Shop
@onready var settings_pop_up: PopupPanel = $SettingsPopUp
@onready var settings: Button = $MarginContainer/MainMenuContainer/Settings/Settings
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func on_leader_boards_pressed():
	SceneManager.goto_scene("res://Scenes/leader_board.tscn")

func _on_settings_button_pressed():
	settings_pop_up.visible = true
	settings_pop_up.popup_centered()


func close_settings():
	settings_pop_up.visible = false

func _on_dimmer_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		close_settings()

func _on_shop_pressed():
	SceneManager.goto_scene("res://Scenes/Shop/shop.tscn")
