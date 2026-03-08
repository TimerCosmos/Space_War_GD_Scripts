extends Node
class_name SettingsManager

const SETTINGS_FILE := "user://settings.cfg"

var sfx_enabled := true
var music_enabled := true
var music_index := 0
var sensitivity := 1.0
var music_volume := 0.8
var music_tracks = [
	preload("res://Assets/Sound Tracks/Background Music/Endless Orbit.mp3"),
	preload("res://Assets/Sound Tracks/Background Music/Nebula Drift Loop.mp3"),
	preload("res://Assets/Sound Tracks/Background Music/Orbital Drift Loop.mp3")
]

func _ready():
	load_settings()


func load_settings():

	var config = ConfigFile.new()

	var err = config.load(SETTINGS_FILE)

	if err != OK:
		save_settings()
		return

	sfx_enabled = config.get_value("audio","sfx_enabled",true)
	music_enabled = config.get_value("audio","music_enabled",true)
	music_index = config.get_value("audio","music_index",0)
	music_volume = config.get_value("audio", "music_volume", 0.8)
	sensitivity = config.get_value("controls","sensitivity",1.0)


func save_settings():

	var config = ConfigFile.new()

	config.set_value("audio","sfx_enabled",sfx_enabled)
	config.set_value("audio","music_enabled",music_enabled)
	config.set_value("audio","music_index",music_index)

	config.set_value("controls","sensitivity",sensitivity)

	config.save(SETTINGS_FILE)
