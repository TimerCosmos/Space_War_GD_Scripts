extends Control

@onready var global_content = $MainVBox/ContentArea/GlobalContent
@onready var rarity_content = $MainVBox/ContentArea/RarityContent
@onready var type_content = $MainVBox/ContentArea/TypeContent

@onready var global_button = $MainVBox/SectionTabs/GlobalButton
@onready var rarity_button = $MainVBox/SectionTabs/RarityButton
@onready var type_button = $MainVBox/SectionTabs/TypeButton

@onready var skill_points: Label = $MainVBox/MarginContainer/HBoxContainer/SkillPoints/SkillPoints
@onready var skill_points_icon: TextureRect = $MainVBox/MarginContainer/HBoxContainer/SkillPoints/SkillPointsIcon

var skill_node_scene = preload("res://Scenes/Game Upgrades/skill_node.tscn")


func _ready():
	connect_tabs()
	show_section(global_content)
	load_catalog()


# ------------------------------------------------
# Tabs
# ------------------------------------------------

func connect_tabs():
	global_button.pressed.connect(func(): show_section(global_content))
	rarity_button.pressed.connect(func(): show_section(rarity_content))
	type_button.pressed.connect(func(): show_section(type_content))


func show_section(section):
	global_content.visible = false
	rarity_content.visible = false
	type_content.visible = false
	section.visible = true


# ------------------------------------------------
# Load
# ------------------------------------------------

func load_catalog():
	UserService.get_permanent_upgrade_catalog(_on_catalog_loaded)


func _on_catalog_loaded(code, response_text):
	if code != 200:
		return

	var json = JSON.parse_string(response_text)
	if json == null:
		return
	skill_points_icon.custom_minimum_size = Vector2(30, 30)
	skill_points.text = str(GameState.user.achievement_points)
	populate_sections(json.get("upgrades", []))


# ------------------------------------------------
# Populate
# ------------------------------------------------

func populate_sections(upgrades):

	clear_sections()

	var global_list = []
	var rarity_list = []
	var type_list = []

	for u in upgrades:
		match u.get("scope_type", "").to_lower():
			"global":
				global_list.append(u)
			"rarity":
				rarity_list.append(u)
			"type":
				type_list.append(u)

	build_progression(global_content, global_list)
	build_progression(rarity_content, rarity_list)
	build_progression(type_content, type_list)


# ------------------------------------------------
# Build Horizontal Progression
# ------------------------------------------------

func build_progression(container, list):

	list.sort_custom(func(a, b):
		return int(a.get("index", 0)) < int(b.get("index", 0))
	)

	# Group by index
	var grouped = {}

	for u in list:
		var idx = int(u.get("index", 0))
		if not grouped.has(idx):
			grouped[idx] = []
		grouped[idx].append(u)

	var sorted_indexes = grouped.keys()
	sorted_indexes.sort()

	await get_tree().process_frame

	var start_y = 30
	var vertical_spacing = 120     # 🔥 smaller gap between index groups
	var stack_spacing = 90         # 🔥 smaller stack gap
	var center_x = container.size.x / 2
	var horizontal_offset = 120    # 🔥 much closer to center

	var previous_nodes = []

	for i in range(sorted_indexes.size()):

		var idx = sorted_indexes[i]
		var group = grouped[idx]

		var current_nodes = []

		# alternate left/right but stay compact
		var is_left = i % 2 == 0
		var x_pos = center_x - horizontal_offset if is_left else center_x + horizontal_offset

		for j in range(group.size()):

			var node = skill_node_scene.instantiate()
			node.upgrade_requested.connect(_on_upgrade_requested)
			var lines_layer = container.get_node("LinesLayer")
			var nodes_layer = container.get_node("NodesLayer")

			nodes_layer.add_child(node)
			node.setup(group[j])

			var y_pos = start_y + i * vertical_spacing + j * stack_spacing

			node.position = Vector2(x_pos, y_pos)

			current_nodes.append(node)

		draw_group_connections(container, previous_nodes, current_nodes)

		previous_nodes = current_nodes

func _on_upgrade_requested(upgrade_id):
	UserService.buy_permanent_upgrade(_on_upgrade_response, upgrade_id)
	
func draw_group_connections(container, prev_nodes, current_nodes):

	if prev_nodes.is_empty():
		return

	var lines_layer = container.get_node("LinesLayer")

	for prev in prev_nodes:
		for curr in current_nodes:

			var line = Line2D.new()
			line.width = 3
			line.default_color = Color(0.8, 0.8, 0.8)

			var a = prev.position + prev.size / 2
			var b = curr.position + curr.size / 2

			line.add_point(a)
			line.add_point(b)

			lines_layer.add_child(line)
			
func clear_sections():

	for section in [global_content, rarity_content, type_content]:

		var lines_layer = section.get_node("LinesLayer")
		var nodes_layer = section.get_node("NodesLayer")

		for child in lines_layer.get_children():
			child.queue_free()

		for child in nodes_layer.get_children():
			child.queue_free()

#---------------------------------------------------------------------------

#Reset

func _on_reset_pressed():
	UserService.reset_permanent_upgrades(_on_reset_response)

func _on_reset_response(code, response_text):

	if code != 200:
		return
	var data = JSON.parse_string(response_text)

	if data == null:
		return
	var points = data["user_economy"]["ACHIEVEMENTPOINTS"]
	GameState.set_achievement_points(int(points))
	load_catalog()  # refresh UI

func _on_upgrade_response(code, response_text):

	if code != 200:
		return

	var data = JSON.parse_string(response_text)

	if data == null:
		return

	var points = data["user_economy"]["ACHIEVEMENTPOINTS"]

	GameState.set_achievement_points(int(points))

	load_catalog() # refresh everything
