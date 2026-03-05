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
@onready var reward_result_label: Label = $CanvasLayer/Control/MarginContainer/VBoxContainer/RewardResultLabel


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
		print("Failed to load draw state")
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
		print("No tickets left")
		return

	reward_result_label.visible = false
	reward_result_label.text = ""

	show_loading(true)

	UserService.start_round(_on_round_started)


func _on_round_started(code, body):

	show_loading(false)

	if code != 200:
		print("Failed to start round")
		return

	var json = JSON.parse_string(body)

	round_id = json["round_id"]
	card_count = json["card_count"]

	round_active = true

	clear_grid()

	grid.columns = calculate_columns()

	for i in range(card_count):
		var card = create_card(i + 1)
		grid.add_child(card)


# -----------------------------------
# CREATE CARD
# -----------------------------------
func create_card(position: int) -> Button:

	var card_scene = preload("res://Scenes/Rewards/card.tscn")
	var card = card_scene.instantiate()

	card.text = "?"
	card.custom_minimum_size = Vector2(150, 200)

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
		print("Pick failed:", code, body)
		return

	var json = JSON.parse_string(body)

	# -----------------------------------
	# UPDATE USER ECONOMY (AUTHORITATIVE)
	# -----------------------------------

	GameState.user.coins = json.get("total_coins", GameState.user.coins)
	GameState.user.exp = json.get("total_exp", GameState.user.exp)
	GameState.user.diamonds = json.get("total_diamonds", GameState.user.diamonds)

	available_tickets = json.get("total_reward_tickets", available_tickets)

	update_remaining()

	# update AI UI
	difficulty_bar.value = json.get("difficulty_after", difficulty_bar.value)
	ai_confidence_bar.value = json.get("ai_confidence_after", ai_confidence_bar.value)

	# -----------------------------------
	# REWARD
	# -----------------------------------

	var reward = json.get("selected_reward", {})

	reveal_reward(reward, json)

	# start next round automatically
	await get_tree().create_timer(reveal_delay).timeout

	start_round()


# -----------------------------------
# REVEAL SELECTED CARD
# -----------------------------------
func reveal_reward(reward: Dictionary, json: Dictionary):

	var type = reward.get("name", "")
	var value = reward.get("value", 0)

	for card in grid.get_children():
		card.disabled = true

	var selected_position = json.get("selected_position", 0)

	if selected_position < grid.get_child_count():
		var card = grid.get_child(selected_position - 1)
		card.modulate = Color(0.6, 1.0, 0.6)

	var tier = reward.get("tier","")

	match tier:
		"high":
			reward_result_label.modulate = Color(1,0.9,0.3)
		"mid":
			reward_result_label.modulate = Color(0.5,0.8,1)
		"low":
			reward_result_label.modulate = Color(0.8,0.8,0.8)

	reward_result_label.visible = true
	reward_result_label.text = "Reward: " + type.capitalize() + " +" + str(value)


# -----------------------------------
# CLAIM REWARD
# -----------------------------------
func claim_reward(id):

	UserService.claim_result(id, _on_claim_result)


func _on_claim_result(code, body):

	if code != 200:
		print("Claim failed")
		return

	# Claim confirmation only
	# Economy already updated from pick response

	await get_tree().create_timer(reveal_delay).timeout

	start_round()


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
