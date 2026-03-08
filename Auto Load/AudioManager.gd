extends Node

var music_player := AudioStreamPlayer.new()
var sfx_player := AudioStreamPlayer.new()
var switch_delay := 0.5

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music_player)
	add_child(sfx_player)

func play_sfx(sound: AudioStream):

	if !UserSettingsManager.sfx_enabled:
		return

	sfx_player.stream = sound
	sfx_player.play()
	
func play_music():

	if !UserSettingsManager.music_enabled:
		music_player.stop()
		return

	if music_player.playing:
		return

	var track = UserSettingsManager.music_tracks[UserSettingsManager.music_index]

	music_player.stream = track

	update_music_volume()

	music_player.play()
	music_player.finished.connect(_on_music_finished)
# ---------------------------------
# Switch Track With Delay
# ---------------------------------

func switch_music():

	music_player.stop()

	await get_tree().create_timer(switch_delay).timeout

	if !UserSettingsManager.music_enabled:
		return

	var track = UserSettingsManager.music_tracks[UserSettingsManager.music_index]

	music_player.stream = track
	music_player.play()


# ---------------------------------
# Next Track
# ---------------------------------

func next_track():

	UserSettingsManager.music_index += 1

	if UserSettingsManager.music_index >= UserSettingsManager.music_tracks.size():
		UserSettingsManager.music_index = 0

	UserSettingsManager.save_settings()

	switch_music()


# ---------------------------------
# Previous Track
# ---------------------------------

func prev_track():

	UserSettingsManager.music_index -= 1

	if UserSettingsManager.music_index < 0:
		UserSettingsManager.music_index = UserSettingsManager.music_tracks.size() - 1

	UserSettingsManager.save_settings()

	switch_music()

func update_music_volume():

	var vol = UserSettingsManager.music_volume

	# convert linear (0-1) to decibels
	music_player.volume_db = linear_to_db(vol)

func stop_music():
	music_player.stop()

func _on_music_finished():
	music_player.play()
