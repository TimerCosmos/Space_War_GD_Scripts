extends Node3D

# -----------------------------------

# CONFIG

# -----------------------------------

@export var reveal_delay: float = 1.5

# -----------------------------------

# NODES

# -----------------------------------

@onready var exit_button: Button = $CanvasLayer/Control/MarginContainer/VBoxContainer/Exit
@onready var grid: GridContainer = $CanvasLayer/Control/MarginContainer/VBoxContainer/GridContainer
@onready var remaining_label: Label = $CanvasLayer/Control/MarginContainer/VBoxContainer/TopStats/RemainingLabel
@onready var loading_label: Label = $CanvasLayer/Control/MarginContainer/VBoxContainer/LoadingLabel
@onready var difficulty_bar: ProgressBar = $CanvasLayer/Control/MarginContainer/VBoxContainer/TopStats/DifficultyBar
@onready var ai_confidence_bar: ProgressBar = $CanvasLayer/Control/MarginContainer/VBoxContainer/TopStats/AiConfidenceBar

@onready var dimmer: ColorRect = $CanvasLayer/Dimmer
@onready var reveal_layer: Control = $CanvasLayer/RevealLayer
@onready var reveal_label: Label = $CanvasLayer/RevealLayer/RevealLabel

# -----------------------------------

# STATE

# -----------------------------------

var available_tickets: int = 0
var round_id = null
var round_active := false
var card_count := 0

# -----------------------------------

# READY

# -----------------------------------

func _ready():


	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	exit_button.pressed.connect(_on_exit_pressed)
	grid.resized.connect(_on_grid_resized)

	await get_tree().process_frame

	load_state()

	difficulty_bar.tooltip_text = "AI difficulty level"
	ai_confidence_bar.tooltip_text = "AI prediction confidence"

	difficulty_bar.modulate = Color(1.0,0.6,0.2)
	ai_confidence_bar.modulate = Color(0.3,0.8,1.0)


# -----------------------------------

# LOAD DRAW STATE

# -----------------------------------

func load_state():


	show_loading(true)

	UserService.get_draw_state(_on_state_loaded)


func _on_state_loaded(code, body):


	show_loading(false)

	if code != 200:
		return

	var json = JSON.parse_string(body)

	available_tickets = json.get("available_tickets", 0)

	var difficulty = json.get("difficulty", 0.0)
	var ai_confidence = json.get("ai_confidence", 0.0)

	update_remaining()

	difficulty_bar.value = difficulty
	ai_confidence_bar.value = ai_confidence 

	if available_tickets > 0:
		start_round()

# -----------------------------------

# START ROUND

# -----------------------------------

func start_round():

	if available_tickets <= 0:
		return

	reveal_label.visible = false

	show_loading(true)

	UserService.start_round(_on_round_started)


func _on_round_started(code, body):
	
	show_loading(false)

	if code != 200:
		return

	var json = JSON.parse_string(body)

	round_id = json["round_id"]
	card_count = json["card_count"]

	round_active = true

	clear_grid()

	grid.columns = calculate_columns()

	for i in range(card_count):
		create_card(i+1)


# -----------------------------------

# CREATE CARD

# -----------------------------------

func create_card(position: int):

	var card_scene = preload("res://Scenes/Rewards/card.tscn")
	var card = card_scene.instantiate()

	card.custom_minimum_size = Vector2(150, 200)

	grid.add_child(card)

	await get_tree().process_frame

	card.setup({})

	card.pressed.connect(func():
		if round_active:
			pick_card(position)
	)

	return card


# -----------------------------------

# PICK CARD

# -----------------------------------

func pick_card(position: int):

	round_active = false

	var payload = {
		"position": position
	}

	show_loading(true)

	UserService.pick_card(round_id, payload, _on_pick_result)


func _on_pick_result(code, body):

	show_loading(false)

	if code != 200:
		return

	var json = JSON.parse_string(body)

	GameState.user.coins = json.get("total_coins", GameState.user.coins)
	GameState.user.exp = json.get("total_exp", GameState.user.exp)
	GameState.user.diamonds = json.get("total_diamonds", GameState.user.diamonds)

	available_tickets = json.get("total_reward_tickets", available_tickets)

	update_remaining()

	difficulty_bar.value = json.get("difficulty_after", difficulty_bar.value)
	ai_confidence_bar.value = json.get("ai_confidence_after", ai_confidence_bar.value)

	var reward = json.get("selected_reward", {})

	await reveal_reward(reward, json)

	start_round()


# -----------------------------------

# REVEAL SELECTED CARD

# -----------------------------------

func reveal_reward(reward: Dictionary, json: Dictionary):
	dimmer.visible = true
	reveal_layer.visible = true
	reveal_label.visible = false
	var selected_position = json.get("selected_position", 0)

	if selected_position <= 0:
		return

	var original_card = grid.get_child(selected_position - 1)
	for card in grid.get_children():
		card.disabled = true

	var card_scene = preload("res://Scenes/Rewards/card.tscn")
	var reveal_card = card_scene.instantiate()

	reveal_layer.add_child(reveal_card)
	reveal_card.setup(reward)

	reveal_card.z_index = 100

	reveal_card.size = original_card.size
	reveal_card.custom_minimum_size = original_card.size
	reveal_card.global_position = original_card.global_position
	reveal_card.scale = Vector2.ONE

	original_card.visible = false

	await get_tree().process_frame

	var center = reveal_layer.size / 2
	var target_pos = center - reveal_card.size / 2

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(reveal_card, "position", target_pos, 0.35)
	tween.parallel().tween_property(reveal_card, "scale", Vector2(2,2), 0.35)

	await tween.finished

	var flip_tween = create_tween()
	flip_tween.tween_property(reveal_card, "scale:x", 0.0, 0.15)

	await flip_tween.finished

	reveal_card.flip()

	var expand_tween = create_tween()
	expand_tween.tween_property(reveal_card, "scale:x", 2.0, 0.15)

	await expand_tween.finished

	show_reward_text(reward)
	await get_tree().create_timer(1.5).timeout

# remove reveal card
	for child in reveal_layer.get_children():
		if child != reveal_label:
			child.queue_free()

	# hide overlay
	dimmer.visible = false
	reveal_layer.visible = false
	reveal_label.visible = false

# -----------------------------------

# SHOW REWARD TEXT

# -----------------------------------

func show_reward_text(reward):

	var type = reward.get("name", "")
	var value = reward.get("value", 0)
	var tier = reward.get("tier","")

	match tier:
		"high":
			reveal_label.modulate = Color(1,0.9,0.3)
		"mid":
			reveal_label.modulate = Color(0.5,0.8,1)
		"low":
			reveal_label.modulate = Color(0.8,0.8,0.8)

	reveal_label.visible = true
	reveal_label.text = "Reward: " + type.capitalize() + " +" + str(value)


# -----------------------------------

# GRID HELPERS

# -----------------------------------

func calculate_columns() -> int:

	var grid_width = grid.size.x
	var card_width = 150
	var spacing = grid.get_theme_constant("h_separation")

	var columns = int(grid_width / (card_width + spacing))

	return max(columns, 1)


func _on_grid_resized():
	grid.columns = calculate_columns()

func clear_grid():
	for child in grid.get_children():
		child.queue_free()

# -----------------------------------

# UI HELPERS

# -----------------------------------

func update_remaining():
	remaining_label.text = "Remaining Tickets: " + str(available_tickets)

func show_loading(value: bool):
	loading_label.visible = value

# -----------------------------------

# EXIT

# -----------------------------------

func _on_exit_pressed():
	SceneManager.goto_scene("res://Scenes/main_menu.tscn")
