# Api call is needed to get the player details

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
	
	## Should write an API call to get the user data
	load_player_ui(
		GameState.user.level,
		GameState.user.exp,
		GameState.user.exp_to_next_level,
		GameState.user.name,
		"res://assets/profile.png",
		GameState.user.coins,
		GameState.user.diamonds
	)
	load_ad_icons()
	GameState.economy_updated.connect(update_currency)
	GameState.ads_updated.connect(load_ad_icons)
	AdManager.load_rewarded("COINS")
	AdManager.load_rewarded("DIAMONDS")

func load_player_ui(level:int, current_exp:int, exp_to_next:int, username:String, profile_path:String, coins:int, diamonds:int):
	# Level number
	level_label.text = str(level)
	# EXP progress
	exp_ring.max_value = exp_to_next + current_exp
	exp_ring.value = current_exp

	# Username
	username_label.text = username
	coins_label.text = " : "+str(coins)
	diamonds_label.text = " : "+str(diamonds)
	high_score.text = "High Score : " + str(GameState.high_score)
	# Profile picture
	if ResourceLoader.exists(profile_path):
		profile_pic.texture = load(profile_path)

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
		
func watch_gold_coin_ad():
	AdManager.show_rewarded("coins")
	
func watch_diamond_coin_ad():
	AdManager.show_rewarded("diamonds")
	
func update_currency():
	coins_label.text = str(GameState.user.coins)
	diamonds_label.text = str(GameState.user.diamonds)
