extends Control
signal upgrade_requested(upgrade_id)
var data

var circle_textures = {
	"damage": preload("res://Assets/Images/Damage.png"),
	"health": preload("res://Assets/Images/Health.png"),
	"hit_rate": preload("res://Assets/Images/HitRate.png")
}

@onready var circle: TextureRect = $Circle

func setup(skill_data):
	data = skill_data
	
	set_circle_texture()
	$Circle/CenterContainer/VBoxContainer/NameLabel.text = data.name
	$Circle/CenterContainer/VBoxContainer/LevelLabel.text = "Level: %d / %d" % [data.user_level, data.max_level]

	update_cost()
	# Description OUTSIDE circle
	$DescriptionLabel.text = data.description

func set_circle_texture():

	var stat = data.stat_type.to_lower()
		
	if circle_textures.has(stat):
		$Circle.texture = circle_textures[stat]
	else:
		$Circle.texture = circle_textures["hit_rate"]
	$Circle.self_modulate = Color(0.4, 0.4, 0.4, 1.0)
		
func update_cost():
	circle.gui_input.connect(_on_circle_clicked)
	var cost_container = $Circle/CenterContainer/VBoxContainer/CostContainer
	var icon = $Circle/CenterContainer/VBoxContainer/CostContainer/CostIcon
	var amount_label = $Circle/CenterContainer/VBoxContainer/CostContainer/CostAmount

	if data.user_level >= data.max_level:
		cost_container.visible = false
		return

	var next_level = data.user_level + 1

	for c in data.costs:
		if c.level_no == next_level:

			amount_label.text = str(int(c.cost_amount))

			icon.texture = preload("res://Assets/Images/SkillPoint.png")
			icon.custom_minimum_size = Vector2(30, 30)
			icon.size = Vector2(10, 10)
			return

	cost_container.visible = false

func _on_circle_clicked(event):
	if event is InputEventMouseButton and event.pressed:
		if data.user_level < data.max_level:
			emit_signal("upgrade_requested", data.id)
