extends Control

var version := ""

@onready var consent_popup = $ConsentPopup
@onready var accept_btn = $ConsentPopup/VBoxContainer/HBoxContainer/Accept
@onready var reject_btn = $ConsentPopup/VBoxContainer/HBoxContainer/Reject
@onready var view_policy_btn = $ConsentPopup/VBoxContainer/HBoxContainer/ViewPolicy


# -------------------------------------------------
# READY
# -------------------------------------------------

func _ready():
	var consent = load_consent()

	if consent == "unknown":
		show_consent_popup()
	else:
		start_auth_flow()


# -------------------------------------------------
# CONSENT HANDLING
# -------------------------------------------------

func load_consent() -> String:
	if not FileAccess.file_exists("user://consent.save"):
		return "unknown"

	var file = FileAccess.open("user://consent.save", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	if data == null:
		return "unknown"

	return data.get("ad_consent", "unknown")


func save_consent(value:String):
	var data = {
		"ad_consent": value
	}

	var file = FileAccess.open("user://consent.save", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()


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
		OS.shell_open("https://kava-studios-privacy-869284059337.asia-south1.run.app/")
	)


# -------------------------------------------------
# AUTH FLOW
# -------------------------------------------------

func start_auth_flow():
	var refresh_token = load_refresh_token()

	if refresh_token == "":
		create_guest()
	else:
		refresh_session(refresh_token)


# -------------------------------------------------
# SESSION FILE HANDLING
# -------------------------------------------------

func load_refresh_token() -> String:
	if not FileAccess.file_exists("user://session.save"):
		return ""

	var file = FileAccess.open("user://session.save", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	if data == null:
		return ""

	if data.has("refresh_token"):
		return data["refresh_token"]

	return ""


func save_session(access_token:String, refresh_token:String):
	var data = {
		"access_token": access_token,
		"refresh_token": refresh_token
	}

	var file = FileAccess.open("user://session.save", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

	GameState.access_token = access_token


# -------------------------------------------------
# BACKEND CALLS
# -------------------------------------------------

func create_guest():
	ApiClient.post(
		"/api/v1/auth/guest",
		{"guest": true},
		func(code, body):
			handle_auth_response(code, body)
	)


func refresh_session(refresh_token:String):
	ApiClient.post(
		"/api/v1/auth/refresh",
		{"refresh_token": refresh_token},
		func(code, body):
			if code != 200:
				create_guest()
			else:
				handle_auth_response(code, body)
	)


# -------------------------------------------------
# HANDLE AUTH RESPONSE
# -------------------------------------------------

func handle_auth_response(code:int, body:String):

	if code != 200:
		create_guest()
		return

	var json = JSON.parse_string(body)

	if json == null:
		create_guest()
		return

	if not json.has("access_token"):
		create_guest()
		return

	var access_token = json["access_token"]
	var refresh_token = json["refresh_token"]
	version = json["game_version"]

	if not check_version():
		print("Version mismatch")
		# get_tree().change_scene_to_file("res://Scenes/StartUp/update_required.tscn")
		return

	save_session(access_token, refresh_token)

	get_tree().change_scene_to_file("res://Scenes/StartUp/loading.tscn")


# -------------------------------------------------
# VERSION CHECK
# -------------------------------------------------

func check_version() -> bool:
	var local_version = ProjectSettings.get_setting("application/config/version")

	if local_version == null or version == null:
		return false

	local_version = str(local_version).strip_edges().to_lower()
	version = str(version).strip_edges().to_lower()

	return local_version == version
