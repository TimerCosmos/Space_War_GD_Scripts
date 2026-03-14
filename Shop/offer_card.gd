extends Panel

@onready var name_label = $VBoxContainer/OfferName
@onready var rewards_container = $VBoxContainer/RewardsContainer
@onready var buy_button = $VBoxContainer/Buy


var coin_icon = preload("res://Assets/Images/Coins.png")
var diamond_icon = preload("res://Assets/Images/Diamonds.png")
var ship_icon = preload("res://Assets/Images/ship.png")


func setup(data):

	name_label.text = data["name"]

	buy_button.text = str(data["currency"]) + " " + str(int(data["display_price"]))


	for child in rewards_container.get_children():
		child.queue_free()


	for item in data["items"]:

		add_reward_row(item)



func add_reward_row(item):

	var row = HBoxContainer.new()

	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)


	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(32,32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


	var label = Label.new()


	var name = item["name"]
	var amount = int(item["amount"])


	label.text = str(amount) + " " + name


	if name.to_lower() == "coins":
		icon.texture = coin_icon

	elif name.to_lower() == "diamonds":
		icon.texture = diamond_icon

	else:
		icon.texture = ship_icon


	row.add_child(icon)
	row.add_child(label)

	rewards_container.add_child(row)
