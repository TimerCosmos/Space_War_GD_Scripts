extends Button

@onready var front: Control = $Front
@onready var back: TextureRect = $Back
@onready var reward_icon: TextureRect = $Front/RewardIcon
@onready var reward_bg: Panel = $Front/RewardBG

var is_revealed := false
var card_data : Dictionary

# -----------------------------------

# ICON DATABASE

# -----------------------------------

const REWARD_ICONS = {
"coins": preload("res://Assets/Images/Coins.png"),
"diamonds": preload("res://Assets/Images/Diamonds.png"),
"xp": preload("res://Assets/Images/XP.png"),
"achievementpoints": preload("res://Assets/Images/SkillPoint.png"),
"spaceship": preload("res://Assets/Images/ship.png"),
"drone": preload("res://Assets/Images/Drone.png"),
"dupdrone":preload("res://Assets/Images/Drone.png"),
"dupship": preload("res://Assets/Images/ship.png")
}

# -----------------------------------

# SETUP CARD DATA

# -----------------------------------

func setup(data: Dictionary):

	card_data = data

	front.visible = false
	back.visible = true

	if data.is_empty():
		return

	var reward_name = data.get("name","").to_lower()
	var reward_type = data.get("reward_type","").to_lower()
	var tier = data.get("tier","low")

	# set reward icon
	if reward_type == "resource":
		if REWARD_ICONS.has(reward_name):
			reward_icon.texture = REWARD_ICONS[reward_name]
	else:
		if REWARD_ICONS.has(reward_type):
			reward_icon.texture = REWARD_ICONS[reward_type]
	var style = reward_bg.get_theme_stylebox("panel").duplicate()

	match tier:
		"low":
			style.border_color = Color(0.3,0.7,1)
		"mid":
			style.border_color = Color(0.7,0.3,1)
		"high":
			style.border_color = Color(1,0.8,0.2)
		"super":
			style.border_color = Color(1.0, 0.25, 0.6)

	reward_bg.add_theme_stylebox_override("panel", style)


# -----------------------------------

# CARD FLIP

# -----------------------------------

func flip():

	if is_revealed:
		return

	is_revealed = true
	_play_flip_animation()


func _play_flip_animation():

	var tween = create_tween()

	self.modulate = Color(1, 1, 1, 0.95)

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	# shrink
	tween.tween_property(self, "scale", Vector2(0.0, 1.0), 0.15)

	# swap card sides
	tween.tween_callback(func():
		back.visible = false
		front.visible = true
	)

	# expand
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)

	self.modulate = Color(1, 1, 1, 1)


# -----------------------------------

# READY

# -----------------------------------

func _ready():

	await get_tree().process_frame
	pivot_offset = size / 2.0

	pressed.connect(_on_pressed)

	mouse_entered.connect(func():
		if not is_revealed:
			scale = Vector2(1.05, 1.05)
	)

	mouse_exited.connect(func():
		if not is_revealed:
			scale = Vector2(1, 1)
	)


func _on_pressed():
	flip()
