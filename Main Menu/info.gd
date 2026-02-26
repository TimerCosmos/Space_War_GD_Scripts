# Api call is needed to get the player details

extends Node
@onready var exp_ring: TextureProgressBar = $ProfileBlock/ExpWidget/ExpRing
@onready var level_label: Label = $ProfileBlock/ExpWidget/LevelLabel
@onready var profile_pic: TextureRect = $ProfileBlock/ProfilePic
@onready var username_label: Label = $ProfileBlock/UsernameLabel
@onready var coins_label: Label = $ProfileBlock/Coins
@onready var diamonds_label: Label = $ProfileBlock/Diamonds


func _ready():
	
	## Should write an API call to get the user data
	load_player_ui(
		GameState.user.level,
		GameState.user.exp,
		500,
		GameState.user.name,
		"res://assets/profile.png",
		GameState.user.coins,
		GameState.user.diamonds
	)


func load_player_ui(level:int, current_exp:int, exp_to_next:int, username:String, profile_path:String, coins:int, diamonds:int):
	# Level number
	level_label.text = str(level)

	# EXP progress
	exp_ring.max_value = exp_to_next
	exp_ring.value = current_exp

	# Username
	username_label.text = username
	coins_label.text = "Coins : "+str(coins)
	diamonds_label.text = "Diamonds : "+str(diamonds)
	# Profile picture
	if ResourceLoader.exists(profile_path):
		profile_pic.texture = load(profile_path)
