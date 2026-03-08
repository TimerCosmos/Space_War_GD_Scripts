extends PopupPanel

@onready var sfx_btn = $PopUpPanel/PopUpContent/SFXToggleBtn
@onready var music_btn = $PopUpPanel/PopUpContent/HBoxContainer/MusicBtn
@onready var prev_btn = $PopUpPanel/PopUpContent/HBoxContainer/PrevTrackBtn
@onready var next_btn = $PopUpPanel/PopUpContent/HBoxContainer/NextTrackBtn
@onready var sens_slider = $PopUpPanel/PopUpContent/SensitivityControl/SensitivitySlider
@onready var volume_slider: HSlider = $PopUpPanel/PopUpContent/VolumeControl/VolumeSlider
@onready var credits_btn: Button = $PopUpPanel/PopUpContent/CreditsBtn
@onready var credits_screen: Control = $"../../CreditsScreen"
@onready var margin_container: MarginContainer = $"../MarginContainer"
@onready var settings_pop_up: PopupPanel = $"."
@onready var about: Button = $PopUpPanel/PopUpContent/About
@onready var about_pop_up: Control = $"../../AboutPopUp"

func _ready():

	sens_slider.value = UserSettingsManager.sensitivity

	update_buttons()

	sfx_btn.pressed.connect(toggle_sfx)
	music_btn.pressed.connect(toggle_music)

	prev_btn.pressed.connect(prev_music)
	next_btn.pressed.connect(next_music)
	about.pressed.connect(_on_about_pressed)
	sens_slider.value_changed.connect(change_sensitivity)
	volume_slider.value = UserSettingsManager.music_volume
	credits_btn.pressed.connect(_on_creditsbtn_pressed)
	volume_slider.value_changed.connect(change_volume)

func update_buttons():

	sfx_btn.text = "SFX: ON" if UserSettingsManager.sfx_enabled else "SFX: OFF"
	music_btn.text = "Music: ON" if UserSettingsManager.music_enabled else "Music: OFF"


func toggle_sfx():

	UserSettingsManager.sfx_enabled = !UserSettingsManager.sfx_enabled
	UserSettingsManager.save_settings()

	update_buttons()


func toggle_music():

	UserSettingsManager.music_enabled = !UserSettingsManager.music_enabled
	UserSettingsManager.save_settings()

	AudioManager.play_music()

	update_buttons()


func next_music():

	AudioManager.next_track()


func prev_music():

	AudioManager.prev_track()


func change_sensitivity(value):

	UserSettingsManager.sensitivity = value
	UserSettingsManager.save_settings()

func change_volume(value):

	UserSettingsManager.music_volume = value

	UserSettingsManager.save_settings()

	AudioManager.update_music_volume()


func _on_creditsbtn_pressed():

	credits_screen.show_credits()
	margin_container.visible = false
	settings_pop_up.visible=false

func _on_about_pressed():
	about_pop_up.show_popup()
	margin_container.visible = false
	settings_pop_up.visible=false
