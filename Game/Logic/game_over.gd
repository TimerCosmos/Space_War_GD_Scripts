extends Control

@onready var restart: Button = $PopupPanel/Restart
@onready var menu: Button = $PopupPanel/Menu
@onready var final_score_label: Label = $PopupPanel/FinalScoreLabel
@onready var reward_label: Label = $PopupPanel/RewardLabel
@onready var level_label: Label = $PopupPanel/LevelLabel

var reward_requested := false

func _ready():
	add_to_group("game_over")
	visible = false
	
	restart.pressed.connect(_on_restart_pressed)
	menu.pressed.connect(_on_menu_pressed)


func show_game_over(final_score: int, time_survived: int):
	if reward_requested:
		return
	
	reward_requested = true
	
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	final_score_label.text = "Score: " + str(final_score)
	reward_label.text = "Calculating rewards..."
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
		reward_label.text = "Reward error. Try again."
		return

	var json = JSON.parse_string(response_text)
	if json == null:
		reward_label.text = "Invalid reward response."
		return

	# Update GameState
	GameState.update_resources(
		json["total_coins"],
		json["total_exp"],
		json["total_diamonds"],
		json["level_after"]
	)

	# Show earned rewards
	reward_label.text = \
		"+ Coins: " + str(json["coins_earned"]) + "\n" + \
		"+ XP: " + str(json["exp_earned"]) + "\n" + \
		"+ Diamonds: " + str(json["diamonds_earned"])

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
