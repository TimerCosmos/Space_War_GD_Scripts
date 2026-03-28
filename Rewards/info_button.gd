extends Button
@onready var ticket_info_popup: Control = $"../../../../../TicketInfoPopup"
@onready var close: Button = $"../../../../../TicketInfoPopup/Panel/VBoxContainer/Close"

func _on_ready_pressed():
	ticket_info_popup.visible = true

func _on_close_pressed():
	ticket_info_popup.visible = false
