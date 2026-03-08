# No api call is needed

extends Button

@onready var animation_player: AnimationPlayer = $"../../../../../AnimationPlayer"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_pressed() -> void:
	animation_player.play("start_game_transition")

func _on_animation_player_animation_finished(anim_name):
	DropService.load_drop_groups(_on_drop_groups_loaded)
		
func _on_drop_groups_loaded(code, body):

	if code != 200:
		return

	var json = JSON.parse_string(body)

	if json == null:
		return

	GameState.drop_groups = json["drop_groups"]

	SceneManager.goto_scene("res://Scenes/game.tscn")
