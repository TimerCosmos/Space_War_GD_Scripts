extends Node

@onready var exp_ring: TextureProgressBar = $ProfileBlock/ExpWidget/ExpRing
@onready var level_label: Label = $ProfileBlock/ExpWidget/LevelLabel
@onready var profile_pic: TextureRect = $ProfileBlock/ProfilePic
@onready var username_label: Label = $ProfileBlock/UsernameLabel
@onready var coins_label: Label = $ProfileBlock/CoinsRow/Coins
@onready var diamonds_label: Label = $ProfileBlock/DiamondsRow/Diamonds
@onready var gold_coin_ads: Button = $ProfileBlock/CoinsRow/GoldCoinAds
@onready var diamond_ads: Button = $ProfileBlock/DiamondsRow/DiamondAds
@onready var gold_coin_ads_remaining: Label = $ProfileBlock/CoinsRow/CoinAdRemaining
@onready var diamond_ads_remaining: Label = $ProfileBlock/DiamondsRow/DiamondAdRemaining
@onready var high_score: Label = $HighScore


func _ready():

	load_player_ui(	)

	load_ad_icons()

	GameState.economy_updated.connect(update_currency)
	GameState.ads_updated.connect(load_ad_icons)
	GameState.user_updated.connect(load_player_ui)

# -------------------------------------------------
# PLAYER UI
# -------------------------------------------------

func load_player_ui():

	level_label.text = str(GameState.user.level)

	exp_ring.max_value = GameState.user.exp_to_next_level + GameState.user.exp
	exp_ring.value = GameState.user.exp

	username_label.text = GameState.user.name
	coins_label.text = " : " + str(GameState.user.coins)
	diamonds_label.text = " : " + str(GameState.user.diamonds)
	high_score.text = "High Score : " + str(GameState.high_score)

	var profile_path = "res://assets/profile.png"
	if ResourceLoader.exists(profile_path):
		profile_pic.texture = load(profile_path)


# -------------------------------------------------
# AD UI
# -------------------------------------------------

func load_ad_icons():

	var mapping = {
		"coins": {
			"button": gold_coin_ads,
			"label": gold_coin_ads_remaining
		},
		"diamonds": {
			"button": diamond_ads,
			"label": diamond_ads_remaining
		}
	}

	for type in mapping:

		var button = mapping[type]["button"]
		var label = mapping[type]["label"]

		var remaining := 0
		var limit := 0

		if GameState.ad_limits.has(type):
			var ad : Ad = GameState.ad_limits[type]
			remaining = ad.remaining
			limit = ad.limit

		button.disabled = remaining <= 0
		label.text = str(remaining) + "/" + str(limit)


# -------------------------------------------------
# AD BUTTONS
# -------------------------------------------------

func watch_gold_coin_ad():
	AdManager.show_rewarded("coins")


func watch_diamond_coin_ad():
	AdManager.show_rewarded("diamonds")


# -------------------------------------------------
# ECONOMY UPDATE
# -------------------------------------------------

func update_currency():
	coins_label.text = str(GameState.user.coins)
	diamonds_label.text = str(GameState.user.diamonds)
