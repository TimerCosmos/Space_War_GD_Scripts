extends PopupPanel

signal name_changed(new_name)

@onready var line_edit: LineEdit = $PopUpPanel/MarginContainer/VBoxContainer/LineEdit
@onready var error_label: Label = $PopUpPanel/MarginContainer/VBoxContainer/Error

@onready var save: Button = $PopUpPanel/MarginContainer/VBoxContainer/HBoxContainer/Save
@onready var cancel: Button = $PopUpPanel/MarginContainer/VBoxContainer/HBoxContainer/Cancel


# Called when popup opens
func open_with_name():
	line_edit.text = GameState.user.name
	error_label.visible = false
	popup_centered()
	line_edit.grab_focus()


# 🔥 VALIDATION
func validate_name(name: String) -> String:
	name = name.strip_edges()

	if name.length() == 0:
		return "Name cannot be empty"

	if name.length() < 3:
		return "Minimum 3 characters required"

	if name.length() > 20:
		return "Maximum 20 characters allowed"

	if not name.is_valid_identifier():
		return "Only letters, numbers, and underscores allowed"

	return ""


func _on_save_pressed():
	var name = line_edit.text.strip_edges()
	var error = validate_name(name)

	if error != "":
		error_label.text = error
		error_label.visible = true
		return

	error_label.visible = false
	save.disabled = true

	UserService.update_name(name, func(response_code, response_text):

		save.disabled = false

		# 🔴 USERNAME TAKEN
		if response_code == 409:
			var json = JSON.parse_string(response_text)
			
			if json != null and json.has("detail"):
				error_label.text = json.detail
			else:
				error_label.text = "Username already taken"

			error_label.visible = true
			return


		# ❌ OTHER ERRORS
		if response_code != 200:
			error_label.text = "Something went wrong. Try again."
			error_label.visible = true
			return


		# ✅ SUCCESS
		var json = JSON.parse_string(response_text)

		if json == null:
			error_label.text = "Invalid server response"
			error_label.visible = true
			return

		# Update GameState
		GameState.user.name = json.name
		GameState.user_updated.emit()

		hide()

	)

func _on_cancel_pressed():
	hide()
