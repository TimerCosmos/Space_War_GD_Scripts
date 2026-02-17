# No api call is needed

extends Control

@onready var resume: Button = $Panel/VBoxContainer/Resume
@onready var quit: Button = $Panel/VBoxContainer/Quit
@onready var pause: Button = $"../Pause"

var is_paused := false


func _ready():
	visible = false
	pause.pressed.connect(toggle_pause)
	# Button connections
	resume.pressed.connect(_on_resume_pressed)
	quit.pressed.connect(_on_quit_pressed)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		toggle_pause()


func toggle_pause():
	is_paused = !is_paused
	get_tree().paused = is_paused
	visible = is_paused

	if is_paused:
		# Show mouse for UI interaction
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		# Capture mouse again for gameplay
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)



func _on_resume_pressed():
	toggle_pause()


func _on_quit_pressed():
	get_tree().paused = false
	SceneManager.goto_scene("res://Scenes/main_menu.tscn")
