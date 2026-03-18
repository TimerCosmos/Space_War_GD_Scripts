extends Control
@onready var video_stream_player: VideoStreamPlayer = $VideoStreamPlayer

func _ready():
	video_stream_player.play()
	
func _on_video_stream_player_finished():
	get_tree().change_scene_to_file("res://Scenes/StartUp/auth_check.tscn")
