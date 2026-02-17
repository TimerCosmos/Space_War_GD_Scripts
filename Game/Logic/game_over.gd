extends Control

@onready var restart: Button = $PopupPanel/Restart
@onready var menu: Button = $PopupPanel/Menu
@onready var final_score_label: Label = $PopupPanel/FinalScoreLabel


func _ready():
	add_to_group("game_over")
	visible = false
	
	restart.pressed.connect(_on_restart_pressed)
	menu.pressed.connect(_on_menu_pressed)


func show_game_over(final_score: int):
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	final_score_label.text = "Score: " + str(final_score)


func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_menu_pressed():
	get_tree().paused = false
	SceneManager.goto_scene("res://Scenes/MainMenu/main_menu.tscn")
