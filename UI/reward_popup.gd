extends Control

@onready var reward_list = $Panel/VBoxContainer/RewardList
@onready var claim_button = $Panel/VBoxContainer/ClaimButton


func _ready():

	populate_rewards()

	claim_button.pressed.connect(_on_claim_pressed)


func populate_rewards():

	for child in reward_list.get_children():
		child.queue_free()

	for reward in GameState.unclaimed_level_rewards:

		var label = Label.new()

		label.text = "Level " + str(reward.level_no) + \
					 " → " + reward.resource_name + \
					 " : " + str(reward.amount)

		reward_list.add_child(label)


func _on_claim_pressed():

	UserService.claim_level_rewards(_on_claim_response)


func _on_claim_response(code, response_text):

	if code != 200:
		return

	var json = JSON.parse_string(response_text)

	if json == null:
		return

	# update GameState economy
	GameState.update_resources(
		json.get("total_coins", GameState.user.coins),
		json.get("total_exp", GameState.user.exp),
		json.get("total_diamonds", GameState.user.diamonds),
		GameState.user.level
	)

	GameState.unclaimed_level_rewards.clear()

	queue_free()
