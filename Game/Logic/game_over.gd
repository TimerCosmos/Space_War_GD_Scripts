extends Control

@onready var restart: Button = $PopupPanel/Restart
@onready var menu: Button = $PopupPanel/Menu

@onready var final_score_label: Label = $PopupPanel/FinalScoreLabel
@onready var level_label: Label = $PopupPanel/LevelLabel

@onready var coins_label: Label = $PopupPanel/HBoxContainer/CoinsRow/CoinsLabel
@onready var xp_label: Label = $PopupPanel/HBoxContainer/XpRow/XpLabel
@onready var diamonds_label: Label = $PopupPanel/HBoxContainer/DiamondsRow/DiamondsLabel

var reward_requested := false


func _ready():
	add_to_group("game_over")
	visible = false


func show_game_over(final_score: int, time_survived: int):

	if reward_requested:
		return

	reward_requested = true

	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	final_score_label.text = "Score: " + str(final_score)
	if final_score > GameState.high_score:
		GameState.high_score = final_score

	# Reset UI while loading
	coins_label.text = "..."
	xp_label.text = "..."
	diamonds_label.text = "..."
	level_label.text = ""

	var payload = {
		"score": final_score,
		"time_survived_sec": time_survived
	}

	ApiClient.post_with_auth(
		"/api/v1/users/rewards/score",
		payload,
		_on_reward_response
	)


func _on_reward_response(code, response_text):

	if code != 200:
		coins_label.text = "Error"
		xp_label.text = "Error"
		diamonds_label.text = "Error"
		return

	var json = JSON.parse_string(response_text)

	if json == null:
		coins_label.text = "Invalid"
		xp_label.text = "Invalid"
		diamonds_label.text = "Invalid"
		return

	# Update GameState
	GameState.update_resources(
		json["total_coins"],
		json["total_exp"],
		json["total_diamonds"],
		json["level_after"]
	)

	
	# Show earned rewards
	coins_label.text = "+" + str(json["coins_earned"])
	xp_label.text = "+" + str(json["exp_earned"])
	diamonds_label.text = "+" + str(json["diamonds_earned"])


	# Level change display
	if json["level_after"] > json["level_before"]:
		level_label.text = "LEVEL UP! " + \
			str(json["level_before"]) + " → " + str(json["level_after"])
	else:
		level_label.text = "Level: " + str(json["level_after"])



func _on_restart_pressed():
	get_tree().paused = false
	reward_requested = false
	get_tree().reload_current_scene()


func _on_menu_pressed():
	get_tree().paused = false
	reward_requested = false
	SceneManager.goto_scene("res://Scenes/main_menu.tscn")
