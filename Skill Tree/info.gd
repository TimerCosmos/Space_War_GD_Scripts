extends Button


@onready var skill_tree_info_pop_up: Control = $"../../../SkillTreeInfoPopUp"
@onready var close: Button = $"../../../SkillTreeInfoPopUp/Panel/VBoxContainer/Close"
@onready var content_area: Control = $"../../ContentArea"

func _on_skill_info_pressed():
	content_area.visible=false
	skill_tree_info_pop_up.visible = true

func _on_close_pressed():
	content_area.visible=true
	skill_tree_info_pop_up.visible = false
