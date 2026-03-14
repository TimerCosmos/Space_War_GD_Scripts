extends Control


# -----------------------------
# CURRENCY GRIDS
# -----------------------------

@onready var coins_grid = $ScrollContainer/MarginContainer/VBoxContainer/TabContainer/Currency/CoinItems/CenterContainer/CoinsGrid
@onready var diamonds_grid = $ScrollContainer/MarginContainer/VBoxContainer/TabContainer/Currency/DiamondItems/CenterContainer/DiamondsGrid


# -----------------------------
# OFFERS CONTAINER
# -----------------------------

@onready var offers_container = $ScrollContainer/MarginContainer/VBoxContainer/TabContainer/Offers/OfferBox/CenterContainer/OfferContainer


# -----------------------------
# SCENES
# -----------------------------

var shop_card_scene = preload("res://scenes/shop/shop_card.tscn")
var offer_card_scene = preload("res://scenes/shop/offer_card.tscn")


func _ready():

	print("Shop loaded")

	UserService.get_shop_items(_on_shop_items_received)

	# OFFERS COME FROM BOOTSTRAP
	populate_offers(GameState.offers)



# =========================================================
# SHOP ITEMS (COINS / DIAMONDS)
# =========================================================

func _on_shop_items_received(response_code, response_text):

	if response_code != 200:
		print("Shop request failed with code:", response_code)
		return


	if response_text == null or response_text == "":
		print("Empty shop response")
		return


	var parsed = JSON.parse_string(response_text)

	if typeof(parsed) != TYPE_DICTIONARY:
		print("Invalid shop JSON response")
		return


	if not parsed.has("items"):
		print("No shop items found")
		return


	var items = parsed["items"]

	populate_shop(items)



func populate_shop(items):

	items.sort_custom(func(a, b): return a["sort_order"] < b["sort_order"])


	for child in coins_grid.get_children():
		child.queue_free()

	for child in diamonds_grid.get_children():
		child.queue_free()


	for item in items:

		var card = shop_card_scene.instantiate()

		var type = item["resource_code"].to_lower()

		if type == "coins":
			coins_grid.add_child(card)

		elif type == "diamonds":
			diamonds_grid.add_child(card)


		card.setup(item)



# =========================================================
# OFFERS (FROM GAMESTATE)
# =========================================================

func populate_offers(offers):

	if offers == null:
		return


	offers.sort_custom(func(a, b): return a["sort_order"] < b["sort_order"])


	for child in offers_container.get_children():
		child.queue_free()


	for offer in offers:

		if not offer.get("is_active", true):
			continue


		var card = offer_card_scene.instantiate()

		offers_container.add_child(card)

		card.setup(offer)
