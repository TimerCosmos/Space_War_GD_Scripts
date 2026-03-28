extends Control

var server_version_code := 0
var min_required_version := 0
var play_store_url := ""
var google_play_id := ""

@onready var consent_popup = $ConsentPopup
@onready var accept_btn = $ConsentPopup/VBoxContainer/HBoxContainer/Accept
@onready var reject_btn = $ConsentPopup/VBoxContainer/HBoxContainer/Reject
@onready var view_policy_btn = $ConsentPopup/VBoxContainer/HBoxContainer/ViewPolicy

@onready var play_games_sign_in_client: PlayGamesSignInClient = $PlayGamesSignInClient
@onready var players_client: PlayGamesPlayersClient = $PlayGamesPlayersClient

# 👇 NEW POPUP
@onready var conflict_popup = $AccountConflictPopup
@onready var switch_btn = $AccountConflictPopup/VBoxContainer/HBoxContainer/SwitchButton
@onready var stay_btn = $AccountConflictPopup/VBoxContainer/HBoxContainer/StayButton

var google_response_received := false
var player_response_received := false
var login_finalized := false


# ---------------------------
# INIT
# ---------------------------
func _enter_tree() -> void:
	GodotPlayGameServices.initialize()

func _ready():
	play_games_sign_in_client.user_authenticated.connect(_on_play_games_result)
	players_client.current_player_loaded.connect(_on_player_loaded)

	var consent = load_consent()
	if consent == "unknown":
		show_consent_popup()
	else:
		start_auth_flow()


# ---------------------------
# AUTH FLOW
# ---------------------------
func start_auth_flow():
	proceed_to_backend_auth()


func proceed_to_backend_auth():
	var refresh_token = load_refresh_token()

	if refresh_token != "":
		refresh_session(refresh_token)
	else:
		create_guest()


func create_guest():
	ApiClient.post("/api/v1/auth/guest", {"guest": true},
		func(code, body): handle_auth_response(code, body))


func refresh_session(refresh_token: String):
	ApiClient.post("/api/v1/auth/refresh", {"refresh_token": refresh_token},
		func(code, body):
			if code == 200:
				handle_auth_response(code, body)
			else:
				create_guest()
	)


func handle_auth_response(code: int, body: String):
	if code != 200:
		create_guest()
		return

	var json = JSON.parse_string(body)
	if json == null or not json.has("access_token"):
		create_guest()
		return

	save_session(json["access_token"], json["refresh_token"])

	var version_data = json.get("current_version", {})
	server_version_code = int(version_data.get("version_code", 0))
	min_required_version = int(version_data.get("min_required_version", 0))
	play_store_url = str(version_data.get("play_store_uri", ""))

	if not check_version():
		return

	start_google_link_flow()


# ---------------------------
# GOOGLE FLOW
# ---------------------------
func start_google_link_flow():
	google_response_received = false

	play_games_sign_in_client.sign_in()

	await get_tree().create_timer(5.0).timeout

	if not google_response_received:
		finalize_login_once()


func _on_play_games_result(is_authenticated: bool):
	google_response_received = true

	if not is_authenticated:
		finalize_login_once()
		return

	player_response_received = false
	players_client.load_current_player(true)

	await get_tree().create_timer(5.0).timeout

	if not player_response_received:
		finalize_login_once()


func _on_player_loaded(player):
	player_response_received = true

	if player == null or player.player_id == "":
		finalize_login_once()
		return

	google_play_id = player.player_id
	attempt_google_link()


# ---------------------------
# GOOGLE LINK / SWITCH
# ---------------------------
func attempt_google_link():
	ApiClient.post_with_auth(
		"/api/v1/auth/google-link",
		{"google_play_id": google_play_id},
		func(code, body):

			if code == 200:
				var json = JSON.parse_string(body)
				if json != null and json.has("access_token"):
					save_session(json["access_token"], json["refresh_token"])

				finalize_login_once()

			elif code == 409:
				show_account_conflict_popup()

			else:
				finalize_login_once()
	)


func show_account_conflict_popup():
	conflict_popup.visible = true

	switch_btn.pressed.connect(_on_switch_account, CONNECT_ONE_SHOT)
	stay_btn.pressed.connect(_on_stay_local, CONNECT_ONE_SHOT)


func _on_switch_account():
	conflict_popup.visible = false

	ApiClient.post_with_auth(
		"/api/v1/auth/google-switch",
		{"google_play_id": google_play_id},
		func(code, body):

			if code == 200:
				var json = JSON.parse_string(body)
				if json != null and json.has("access_token"):
					save_session(json["access_token"], json["refresh_token"])

			finalize_login_once()
	)


func _on_stay_local():
	conflict_popup.visible = false
	finalize_login_once()


# ---------------------------
# VERSION CHECK
# ---------------------------
func get_local_version_code() -> int:
	var version = ProjectSettings.get_setting("application/config/version")

	if typeof(version) == TYPE_INT:
		return version

	if typeof(version) == TYPE_STRING and version.is_valid_int():
		return int(version)

	return 0


func check_version() -> bool:
	var local_version = get_local_version_code()

	if local_version < min_required_version:
		show_force_update()
		return false

	elif local_version < server_version_code:
		show_optional_update()

	return true


func show_force_update():
	if play_store_url != "":
		OS.shell_open(play_store_url)

	get_tree().paused = true


func show_optional_update():
	pass


# ---------------------------
# FINAL STEP
# ---------------------------
func finalize_login_once():
	if login_finalized:
		return

	login_finalized = true
	finalize_login()


func finalize_login():
	get_tree().change_scene_to_file("res://Scenes/StartUp/loading.tscn")


# ---------------------------
# HELPERS
# ---------------------------
func load_consent() -> String:
	if not FileAccess.file_exists("user://consent.save"):
		return "unknown"

	var file = FileAccess.open("user://consent.save", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	return data.get("ad_consent", "unknown") if data else "unknown"


func save_consent(value: String):
	var file = FileAccess.open("user://consent.save", FileAccess.WRITE)
	file.store_string(JSON.stringify({"ad_consent": value}))


func show_consent_popup():
	consent_popup.visible = true

	accept_btn.pressed.connect(func():
		save_consent("accepted")
		consent_popup.visible = false
		start_auth_flow()
	)

	reject_btn.pressed.connect(func():
		save_consent("rejected")
		consent_popup.visible = false
		start_auth_flow()
	)

	view_policy_btn.pressed.connect(func():
		OS.shell_open("https://kava-studios-privacy-869284059337.asia-south1.run.app")
	)


func load_refresh_token() -> String:
	if not FileAccess.file_exists("user://session.save"):
		return ""

	var file = FileAccess.open("user://session.save", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	return data.get("refresh_token", "") if data else ""


func save_session(access_token: String, refresh_token: String):
	var file = FileAccess.open("user://session.save", FileAccess.WRITE)
	file.store_string(JSON.stringify({
		"access_token": access_token,
		"refresh_token": refresh_token
	}))

	GameState.access_token = access_token
