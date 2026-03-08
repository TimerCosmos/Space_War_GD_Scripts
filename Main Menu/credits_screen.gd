extends Control

@onready var credits = $CreditsText
@onready var margin_container: MarginContainer = $"../MenuRoot/MarginContainer"

var speed := 40


func _ready():
	reset_scroll()


func reset_scroll():
	credits.position.y = get_viewport_rect().size.y


func _process(delta):
	if visible:
		credits.position.y -= speed * delta


func show_credits():
	reset_scroll()
	visible = true


func hide_credits():
	visible = false
	margin_container.visible = true
func _on_back_pressed():
	hide_credits()
