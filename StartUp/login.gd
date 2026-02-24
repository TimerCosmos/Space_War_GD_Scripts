extends Control

var auth_service = preload("res://Scripts/Services/auth_service.gd").new()

@onready var email_input = $VBoxContainer/EmailInput
@onready var password_input = $VBoxContainer/PasswordInput
@onready var login_button = $VBoxContainer/Login
@onready var error_label = $VBoxContainer/Error
@onready var register: Button = $VBoxContainer/Register


func _ready():
	error_label.visible = false


func _on_LoginButton_pressed():
	error_label.visible = false
	
	var email = email_input.text.strip_edges()
	var password = password_input.text.strip_edges()

	if email == "" or password == "":
		show_error("Email and password required.")
		return
	
	if password.length() < 8:
		show_error("Password must be at least 8 characters.")
		return

	login_button.disabled = true
	auth_service.login(email, password, _on_login_response)


func _on_login_response(code, response_text):
	login_button.disabled = false

	if code != 200:
		var json = JSON.parse_string(response_text)
		
		if json and json.has("detail"):
			var message = json["detail"]
			
			if message == "User not found":
				show_error("Account not found. Create one?")
				show_register_option()
				return
			
			if message == "Invalid credentials":
				show_error("Wrong password.")
				return
		
		show_error("Login failed.")
		return

	var json_success = JSON.parse_string(response_text)

	var token = json_success["access_token"]
	var user = json_success["user"]

	save_token(token)
	GameState.set_session(token, user)
	print(user)
	get_tree().change_scene_to_file("res://Scenes/Startup/loading.tscn")

func show_register_option():
	register.visible = true
	
func _on_RegisterButton_pressed():
	get_tree().change_scene_to_file("res://Scenes/Startup/register.tscn")

func show_error(message: String):
	error_label.text = message
	error_label.visible = true


func save_token(token: String):
	var file = FileAccess.open("user://session.save", FileAccess.WRITE)
	file.store_string(token)
	file.close()
