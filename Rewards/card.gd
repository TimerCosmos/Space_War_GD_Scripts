extends Button

@onready var front: TextureRect = $Front
@onready var back: TextureRect = $Back

var is_revealed := false
var card_data : Dictionary

func setup(data: Dictionary):
	card_data = data
	front.visible = false
	back.visible = true

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
	
	# Shrink to center
	tween.tween_property(self, "scale", Vector2(0.0, 1.0), 0.15)

	# Swap textures at middle
	tween.tween_callback(func():
		back.visible = false
		front.visible = true
	)
	self.modulate = Color(1, 1, 1, 1)
	# Expand back out
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)
	
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
