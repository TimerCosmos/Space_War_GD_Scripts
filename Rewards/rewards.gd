extends Node3D

# -----------------------------------
# CONFIG
# -----------------------------------
@export var default_chances: int = 5
@export var cards_per_round: int = 6
@export var reveal_delay: float = 1.5


# -----------------------------------
# NODES
# -----------------------------------
@onready var exit_button: Button = $CanvasLayer/Control/MarginContainer/VBoxContainer/Exit
@onready var grid: GridContainer = $CanvasLayer/Control/MarginContainer/VBoxContainer/GridContainer
@onready var remaining_label: Label = $CanvasLayer/Control/MarginContainer/VBoxContainer/RemainingLabel


# -----------------------------------
# STATE
# -----------------------------------
var remaining_chances := 0
var current_cards: Array = []
var round_active := false


# -----------------------------------
# READY
# -----------------------------------
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	remaining_chances = default_chances
	exit_button.pressed.connect(_on_exit_pressed)

	grid.resized.connect(_on_grid_resized)

	await get_tree().process_frame
	start_round()


func _on_grid_resized():
	grid.columns = calculate_columns()


# -----------------------------------
# START NEW ROUND
# -----------------------------------
func start_round():

	if remaining_chances <= 0:
		print("All reward chances used.")
		return

	round_active = true
	update_remaining()
	clear_grid()

	# Set grid columns dynamically
	grid.columns = calculate_columns()

	current_cards = generate_random_cards(cards_per_round)

	for card_data in current_cards:
		var card = create_card(card_data)
		grid.add_child(card)


# -----------------------------------
# RANDOM CARD DATA (TEMP MOCK)
# -----------------------------------
func generate_random_cards(count: int) -> Array:

	var pool = [
		{"type":"coins","value":100},
		{"type":"damage","value":1},
		{"type":"health","value":20},
		{"type":"drone","value":1},
		{"type":"exp","value":50}
	]

	var result: Array = []

	for i in count:
		result.append(pool[randi() % pool.size()])

	return result


# -----------------------------------
# CREATE CARD BUTTON
# -----------------------------------
func create_card(card_data: Dictionary) -> Button:

	var card_scene = preload("res://Scenes/Rewards/card.tscn")
	var card = card_scene.instantiate()
	grid.add_child(card)
	card.setup(card_data)

	card.pressed.connect(func():
		if round_active:
			reveal_all_cards(card, card_data)
	)

	card.text = "?"
	card.custom_minimum_size = Vector2(150,200)
	card.add_theme_font_size_override("font_size", 32)

	card.pressed.connect(func():
		if round_active:
			reveal_all_cards(card, card_data)
	)

	return card


# -----------------------------------
# REVEAL LOGIC
# -----------------------------------
func reveal_all_cards(selected_card: Button, selected_data: Dictionary):

	round_active = false
	remaining_chances -= 1

	var index := 0

	for card in grid.get_children():
		var data = current_cards[index]

		card.text = data["type"].capitalize() + "\n+" + str(data["value"])
		card.disabled = true

		if card == selected_card:
			card.modulate = Color(0.6, 1.0, 0.6)
		else:
			card.modulate = Color(1, 1, 1)

		index += 1

	apply_reward(selected_data)
	update_remaining()

	await get_tree().create_timer(reveal_delay).timeout

	start_round()


# -----------------------------------
# APPLY REWARD
# -----------------------------------
func apply_reward(data: Dictionary):

	match data["type"]:
		"coins":
			print("Coins +", data["value"])
		"damage":
			print("Damage +", data["value"])
		"health":
			print("Health +", data["value"])
		"drone":
			print("Drone +", data["value"])
		"exp":
			print("Exp +", data["value"])


# -----------------------------------
# GRID HELPERS
# -----------------------------------
func calculate_columns() -> int:
	var grid_width = grid.size.x
	var card_width = 150  # match your real card width
	var spacing = grid.get_theme_constant("h_separation")

	var columns = int(grid_width / (card_width + spacing))

	return max(columns, 1)


func update_remaining():
	remaining_label.text = "Remaining Chances: " + str(remaining_chances)


func clear_grid():
	for child in grid.get_children():
		child.queue_free()


# -----------------------------------
# EXIT
# -----------------------------------
func _on_exit_pressed():
	SceneManager.goto_scene("res://Scenes/main_menu.tscn")
