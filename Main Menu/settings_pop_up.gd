extends PopupPanel

@onready var sfx_btn = $PopUpPanel/PopUpContent/GridContainer/SFXToggleBtn
@onready var music_btn = $PopUpPanel/PopUpContent/HBoxContainer/MusicBtn
@onready var prev_btn = $PopUpPanel/PopUpContent/HBoxContainer/PrevTrackBtn
@onready var next_btn = $PopUpPanel/PopUpContent/HBoxContainer/NextTrackBtn
@onready var sens_slider = $PopUpPanel/PopUpContent/SensitivityControl/SensitivitySlider
@onready var volume_slider: HSlider = $PopUpPanel/PopUpContent/VolumeControl/VolumeSlider
@onready var credits_btn: Button = $PopUpPanel/PopUpContent/GridContainer/CreditsBtn
@onready var credits_screen: Control = $"../../CreditsScreen"
@onready var margin_container: MarginContainer = $"../MarginContainer"
@onready var settings_pop_up: PopupPanel = $"." 
@onready var about: Button = $PopUpPanel/PopUpContent/GridContainer/About
@onready var about_pop_up: Control = $"../../AboutPopUp"
@onready var accept_privacy_btn: Button = $PopUpPanel/PopUpContent/GridContainer/AcceptPrivacy
@onready var login_btn: Button = $PopUpPanel/PopUpContent/GridContainer/LoginBtn
@onready var graphics: Button = $PopUpPanel/PopUpContent/GridContainer/Graphics
@onready var graphic_label: Label = $PopUpPanel/PopUpContent/GridContainer/GraphicLabel

@onready var play_games_sign_in_client: PlayGamesSignInClient = $PlayGamesSignInClient

var google_play_id := ""

func _ready():
	sens_slider.value = UserSettingsManager.sensitivity
	volume_slider.value = UserSettingsManager.music_volume

	update_buttons()

	var consent = load_consent()

	if consent == "accepted":
		accept_privacy_btn.visible = false
	else:
		accept_privacy_btn.visible = true
		accept_privacy_btn.pressed.connect(_on_accept_privacy)

	# UI connections
	sfx_btn.pressed.connect(toggle_sfx)
	music_btn.pressed.connect(toggle_music)
	prev_btn.pressed.connect(prev_music)
	next_btn.pressed.connect(next_music)
	about.pressed.connect(_on_about_pressed)
	sens_slider.value_changed.connect(change_sensitivity)
	credits_btn.pressed.connect(_on_creditsbtn_pressed)
	volume_slider.value_changed.connect(change_volume)
	graphics.pressed.connect(_on_graphics_pressed)
	login_btn.pressed.connect(_on_login_clicked)
	update_graphics_label()

	# Google signal
	play_games_sign_in_client.user_authenticated.connect(_on_play_games_result)


# -------------------------------------------------
# GOOGLE LOGIN + BACKEND LINK
# -------------------------------------------------

func _on_login_clicked():
	print("Attempting Google Play Sign-In...")
	login_btn.text = "Signing in..."
	login_btn.disabled = true
	play_games_sign_in_client.sign_in()


func _on_play_games_result(is_authenticated: bool):
	if not is_authenticated:
		print("Google Play Sign-In failed.")
		login_btn.text = "Login Failed - Try Again"
		login_btn.disabled = false
		return

	print("Google Play login success")

	var player = play_games_sign_in_client.get_current_player()
	google_play_id = player.get_player_id()

	print("Google ID: ", google_play_id)

	attempt_google_link()


func attempt_google_link():
	if google_play_id == "":
		print("No Google ID, skipping backend link")
		return

	print("Linking Google account with backend...")

	ApiClient.post_with_auth(
		"/api/v1/auth/google-link",
		{"google_play_id": google_play_id},
		func(code, body):
			if code == 200:
				var json = JSON.parse_string(body)
				if json != null and json.has("access_token"):
					save_session(json["access_token"], json["refresh_token"])
					print("Google link success + session updated")
				else:
					print("Google link success (no new tokens)")
				login_btn.text = "Linked ✅"
			else:
				print("Google link failed: ", code)
				login_btn.text = "Link Failed"

			login_btn.disabled = false
	)


# -------------------------------------------------
# SESSION SAVE (same as auth_check.gd)
# -------------------------------------------------

func save_session(access_token: String, refresh_token: String):
	var file = FileAccess.open("user://session.save", FileAccess.WRITE)
	file.store_string(JSON.stringify({
		"access_token": access_token,
		"refresh_token": refresh_token
	}))
	GameState.access_token = access_token


# -------------------------------------------------
# CONSENT
# -------------------------------------------------

func load_consent() -> String:
	if not FileAccess.file_exists("user://consent.save"):
		return "unknown"

	var file = FileAccess.open("user://consent.save", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	return data.get("ad_consent", "unknown") if data else "unknown"


func save_consent(value:String):
	var data = { "ad_consent": value }
	var file = FileAccess.open("user://consent.save", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()


func _on_accept_privacy():
	save_consent("accepted")
	accept_privacy_btn.text = "Privacy Accepted"
	accept_privacy_btn.disabled = true
	settings_pop_up.hide()
	margin_container.visible = true
	AdManager.init_ads()


# -------------------------------------------------
# AUDIO SETTINGS
# -------------------------------------------------

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


# -------------------------------------------------
# NAVIGATION
# -------------------------------------------------

func _on_creditsbtn_pressed():
	credits_screen.show_credits()
	margin_container.visible = false
	settings_pop_up.visible = false


func _on_about_pressed():
	about_pop_up.show_popup()
	margin_container.visible = false
	settings_pop_up.visible = false


func _on_privacy_clicked():
	OS.shell_open("https://kava-studios-privacy-869284059337.asia-south1.run.app")

# -------------------------
# GRAPHICS BUTTON
# -------------------------
func _on_graphics_pressed():
	GraphicsManager.cycle_mode()
	update_graphics_label()


func update_graphics_label():
	graphic_label.text = " : " + GraphicsManager.graphics_mode
