extends Panel

@onready var item_icon: TextureRect = $ItemIcon
@onready var name_label = $VBoxContainer/ItemName
@onready var amount_label = $VBoxContainer/Amount
@onready var buy_button = $VBoxContainer/Buy

var coin_icon = preload("res://Assets/Images/Coins.png")
var diamond_icon = preload("res://Assets/Images/Diamonds.png")

var shop_item_data

func setup(data):

	shop_item_data = data

	name_label.text = data["resource_name"]
	amount_label.text = str(data["amount"])
	buy_button.text = str(data["currency"]) + " " + str(int(data["display_price"]))

	var type = data["resource_code"].to_lower()

	if type == "coins":
		item_icon.texture = coin_icon
	elif type == "diamonds":
		item_icon.texture = diamond_icon
