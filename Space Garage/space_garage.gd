extends Node3D

# -------------------------------------------------
# Generic Garage Viewer (Ships + Drones)
# -------------------------------------------------

enum GarageMode { SHIPS, DRONES }
var mode = GarageMode.SHIPS

# -------------------------------------------------
# Runtime State
# -------------------------------------------------

var items: Array = []                 # Can contain ShipData OR DroneData
var current_index := 0
var current_item = null     # Generic resource
var current_preview: Node3D = null    # Instantiated 3D preview

var rotation_speed := 0.005
var is_owned := false

# -------------------------------------------------
# Node References
# -------------------------------------------------

@onready var pivot: Node3D = $ShipPivot
@onready var prev: Button = $CanvasLayer/Control/HBoxContainer/PreviewArea/MarginContainer/ShipScrolls/Prev
@onready var next: Button = $CanvasLayer/Control/HBoxContainer/PreviewArea/MarginContainer/ShipScrolls/Next
@onready var hit_points: Label = $"CanvasLayer/Control/StatsPanel/MarginContainer/GridContainer/Hit Points Label"
@onready var damage: Label = $"CanvasLayer/Control/StatsPanel/MarginContainer/GridContainer/Damage Label"
@onready var hit_rate: Label = $"CanvasLayer/Control/StatsPanel/MarginContainer/GridContainer/Hit Rate Label"
@onready var title: Label = $CanvasLayer/Control/HBoxContainer/PreviewArea/MarginContainer/Back/Title
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var glow_frame: ColorRect = $CanvasLayer/Control/GlowFrame


@onready var border_particles: Node2D = $CanvasLayer/Control/BorderParticles
@onready var p_top: GPUParticles2D = $CanvasLayer/Control/BorderParticles/Top
@onready var p_left: GPUParticles2D = $CanvasLayer/Control/BorderParticles/Left
@onready var p_right: GPUParticles2D = $CanvasLayer/Control/BorderParticles/Right
@onready var p_bottom: GPUParticles2D = $CanvasLayer/Control/BorderParticles/Bottom

@onready var select: Button = $CanvasLayer/Control/HBoxContainer/PreviewArea/MarginContainer/ShipScrolls/Select
@onready var buy_button: Button = $CanvasLayer/Control/HBoxContainer/PreviewArea/MarginContainer/ShipScrolls/BuyButton
@onready var grid_container: GridContainer = $CanvasLayer/Control/StatsPanel/MarginContainer/GridContainer

@onready var hit_points_button: Button = $"CanvasLayer/Control/StatsPanel/MarginContainer/GridContainer/Hit Points Button"
@onready var hit_points_up_value: Label = $"CanvasLayer/Control/StatsPanel/MarginContainer/GridContainer/Hit Points Up Value"
@onready var damage_button: Button = $"CanvasLayer/Control/StatsPanel/MarginContainer/GridContainer/Damage Button"
@onready var damage_up_value: Label = $"CanvasLayer/Control/StatsPanel/MarginContainer/GridContainer/Damage Up Value"
@onready var hit_rate_button: Button = $"CanvasLayer/Control/StatsPanel/MarginContainer/GridContainer/Hit Rate Button"
@onready var hit_rate_up_value: Label = $"CanvasLayer/Control/StatsPanel/MarginContainer/GridContainer/Hit Rate Up Value"

@onready var hit_points_level_label: Label = $"CanvasLayer/Control/StatsPanel/MarginContainer/GridContainer/Hit Points Level Label"
@onready var damage_level_label: Label = $"CanvasLayer/Control/StatsPanel/MarginContainer/GridContainer/Damage Level Label"
@onready var hit_rate_level_label: Label = $"CanvasLayer/Control/StatsPanel/MarginContainer/GridContainer/Hit Rate Level Label"


# -------------------------------------------------
# Ready
# -------------------------------------------------

func _ready():
	load_data()

	if items.is_empty():
		push_error("No data loaded for garage")
		return
	load_item(0)
	hit_points_button.pressed.connect(func(): upgrade_stat("health"))
	damage_button.pressed.connect(func(): upgrade_stat("damage"))
	hit_rate_button.pressed.connect(func(): upgrade_stat("hit_rate"))
# -------------------------------------------------
# Load Data (Ships or Drones)
# -------------------------------------------------

func load_data():
	items.clear()

	mode = GameState.garage_mode
	if mode == GarageMode.SHIPS:
		for ship in GameState.all_ships:
			items.append(ship)
	else:
		for drone in GameState.all_drones:
			items.append(drone)

func update_stats_display(data):
	title.text = data.name
	hit_points.text = "Health: " + str(data.base_health)
	damage.text = "Damage: " + str(data.base_damage)
	hit_rate.text = "Hit Rate: " + str(data.base_hit_rate)

# -------------------------------------------------
# Load Preview Item
# -------------------------------------------------

func load_item(index: int):

	if current_preview:
		current_preview.queue_free()

	current_item = items[index]

	if mode == GarageMode.SHIPS:

		var backend_ship = current_item
		var resource_data: ShipData = load(backend_ship.tres_file_path)

		if resource_data == null or resource_data.ship_scene == null:
			push_error("Invalid Ship resource")
			return

		current_preview = resource_data.ship_scene.instantiate()
		current_preview.apply_data(resource_data, backend_ship)
		is_owned = GameState.return_owned_or_not("Ships", backend_ship.id)

		if is_owned:
			select.visible = true
			buy_button.visible = false
		else:
			select.visible = false
			buy_button.visible = true
			
			var resource_type = backend_ship.resource_type
			var item_cost = int(backend_ship.cost)
			var balance = get_user_balance(resource_type)
			
			var emoji = ""
			if resource_type == "COINS":
				emoji = " 🪙"
			elif resource_type == "DIAMONDS":
				emoji = " 💎"
			
			buy_button.text = "Buy " + str(item_cost) + emoji
			
			buy_button.disabled = balance < item_cost
		update_stats_display(backend_ship)
		var rarity_enum = RarityEnum.from_string(current_item.rarity)
		apply_rarity_glow(rarity_enum)
		apply_rarity_particles(rarity_enum)
	else:

		var backend_drone = current_item
		var resource_data: DroneData = load(backend_drone.tres_file_path)

		if resource_data == null or resource_data.scene_path == null:
			push_error("Invalid Drone resource")
			return

		current_preview = resource_data.scene_path.instantiate()
		current_preview.apply_data(resource_data, backend_drone)
		is_owned = GameState.return_owned_or_not("Drones", backend_drone.id)

		if is_owned:
			select.visible = true
			buy_button.visible = false
		else:
			select.visible = false
			buy_button.visible = true
			
			var resource_type = backend_drone.resource_type
			var item_cost = int(backend_drone.cost)
			var balance = get_user_balance(resource_type)
			
			var emoji = ""
			if resource_type == "COINS":
				emoji = " 🪙"
			elif resource_type == "DIAMONDS":
				emoji = " 💎"
			
			buy_button.text = "Buy " + str(item_cost) + emoji
			
			buy_button.disabled = balance < item_cost
		update_stats_display(backend_drone)
		var rarity_enum = RarityEnum.from_string(current_item.rarity)
		apply_rarity_glow(rarity_enum)
		apply_rarity_particles(rarity_enum)
	pivot.add_child(current_preview)
	current_preview.global_transform = pivot.global_transform
	pivot.rotation = Vector3.ZERO

	update_button_states()
	update_upgrade_visibility()

func get_user_balance(resource_type: String) -> int:
	match resource_type:
		"COINS":
			return GameState.user.coins
		"DIAMONDS":
			return GameState.user.diamonds
		_:
			return 0
			
# -------------------------------------------------
# Buttons
# -------------------------------------------------
func _on_buy_button_pressed():

	if is_owned:
		return
	
	if mode == GarageMode.SHIPS:
		UserService.buy_spaceship(
			current_item.id,
			_on_buy_done
		)
	else:
		UserService.buy_drone(
			current_item.id,
			_on_buy_done
		)
		
func _on_buy_done(code, response_text):

	if code != 200:
		print("Buy failed")
		return

	var json = JSON.parse_string(response_text)
	if json == null:
		return

	if not json.get("success", false):
		print("Purchase failed:", json.get("message", ""))
		return

	# ----------------------------------
	# 1️⃣ Update Economy
	# ----------------------------------

	var economy = json.get("user_economy", null)
	if economy != null:
		GameState.update_resources(
			economy.get("COINS", GameState.user.coins),
			economy.get("XP", GameState.user.exp),
			economy.get("DIAMONDS", GameState.user.diamonds),
			GameState.user.level
		)

	# ----------------------------------
	# 2️⃣ Update Owned Ships
	# ----------------------------------

	GameState.owned_ship_ids = json.get("owned_ship_ids", [])

	# ----------------------------------
	# 3️⃣ Update Local Current Item Data
	# ----------------------------------

	var updated_ship = json.get("spaceship", null)
	if updated_ship != null:
		current_item.base_health = updated_ship.get("base_health", current_item.base_health)
		current_item.base_damage = updated_ship.get("base_damage", current_item.base_damage)
		current_item.base_hit_rate = updated_ship.get("base_hit_rate", current_item.base_hit_rate)

		update_stats_display(current_item)

	# ----------------------------------
	# 4️⃣ Immediately Apply Upgrade Preview
	# ----------------------------------

	var preview = json.get("upgrade_preview", null)
	if preview != null:
		apply_upgrade_preview(preview)

	# ----------------------------------
	# 5️⃣ Switch UI to Owned State
	# ----------------------------------

	is_owned = true
	select.visible = true
	buy_button.visible = false

	update_upgrade_visibility()

func apply_upgrade_preview(json):

	hit_points_button.disabled = true
	damage_button.disabled = true
	hit_rate_button.disabled = true

	for stat in json.get("stat_previews", []):

		var stat_type = stat.get("stat_type", "")
		var affordable = int(stat.get("affordable_count", 0))
		var upgrades = stat.get("upgrades", [])
		var upgrades_available = stat.get("upgrades_available", true)

		var button
		var label

		match stat_type:
			"health":
				button = hit_points_button
				label = hit_points_up_value
			"damage":
				button = damage_button
				label = damage_up_value
			"hit_rate":
				button = hit_rate_button
				label = hit_rate_up_value
			_:
				continue

		if not upgrades_available:
			label.text = "Maxed (Current Version)"
			button.disabled = true
			continue

		if upgrades.size() > 0:
			var first = upgrades[0]
			var cost = int(first.get("cost", 0))
			var value = first.get("upgrade_value", 0)

			label.text = "+" + str(value)
			button.text = str(cost)
			button.disabled = affordable <= 0
func _on_next_button_pressed():
	if current_index < items.size() - 1:
		current_index += 1
		load_item(current_index)
		load_animation()

func _on_prev_button_pressed():
	if current_index > 0:
		current_index -= 1
		load_item(current_index)
		load_animation()


func _on_select_button_pressed():

	if mode == GarageMode.SHIPS:
		var backend_ship = current_item   # DTO
		UserService.set_default_spaceship(
			backend_ship.id,
			_on_default_ship_updated
		)
	else:
		var backend_drone = current_item
		UserService.set_default_drone(
			backend_drone.id,
			_on_default_drone_updated
		)

func _on_default_ship_updated(code, response_text):

	if code != 200:
		print("Failed to set default ship")
		return

	var json = JSON.parse_string(response_text)
	if json == null:
		return

	# Update GameState user
	GameState.user = UserProfile.from_dict(json)

	# Update ShipManager
	ShipManager.selected_ship_id = GameState.user.default_spaceship_id

	SceneManager.goto_scene("res://Scenes/game.tscn")

func _on_default_drone_updated(code, response_text):

	if code != 200:
		print("Failed to set default drone")
		return

	var json = JSON.parse_string(response_text)
	if json == null:
		return

	GameState.user = UserProfile.from_dict(json)

	DroneManager.selected_drone_id = GameState.user.default_drone_id
	
func load_animation():
	animation_player.play("shippivot")


# -------------------------------------------------
# UI Helpers
# -------------------------------------------------

func update_button_states():
	fade_button(prev, current_index > 0)
	fade_button(next, current_index < items.size() - 1)


func fade_button(button: Button, enable: bool):
	button.disabled = !enable

	var target_alpha := 1.0 if enable else 0.3
	var tween := create_tween()

	tween.tween_property(button, "modulate:a", target_alpha, 0.25)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)


# -------------------------------------------------
# Rotation
# -------------------------------------------------

func _input(event):
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		pivot.rotate_y(event.relative.x * rotation_speed)
		pivot.rotate_x(-event.relative.y * rotation_speed)



func apply_glow_color(color: Color):
	var mat := glow_frame.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("glow_color", color)

func apply_rarity_glow(rarity: int):

	var mat := glow_frame.material as ShaderMaterial
	if mat == null:
		return

	var color = RarityEnum.get_glow_color(rarity)
	mat.set_shader_parameter("glow_color", color)
	mat.set_shader_parameter("intensity", 3.5)

	title.add_theme_color_override("font_color", color)
func apply_galactic_shader():

	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float border_px = 6.0;
uniform float glow_px = 40.0;
uniform float intensity = 3.5;

void fragment() {

	vec2 pixel_size = vec2(border_px) * SCREEN_PIXEL_SIZE;
	vec2 glow_size = vec2(glow_px) * SCREEN_PIXEL_SIZE;

	vec2 uv = UV;

	float dist_x = min(uv.x, 1.0 - uv.x);
	float dist_y = min(uv.y, 1.0 - uv.y);
	float edge = min(dist_x, dist_y);

	float border = step(edge, pixel_size.x);
	float glow = 1.0 - smoothstep(pixel_size.x,
	                              pixel_size.x + glow_size.x,
	                              edge);

	float alpha = max(border, glow);
	if (alpha <= 0.0) discard;

	// Rainbow animation
	float hue = fract(TIME * 0.2 + uv.x);
	vec3 col = vec3(
		0.5 + 0.5 * sin(6.2831 * (hue + 0.0)),
		0.5 + 0.5 * sin(6.2831 * (hue + 0.33)),
		0.5 + 0.5 * sin(6.2831 * (hue + 0.66))
	);

	COLOR = vec4(col * intensity * alpha, alpha);
}
"""

	var mat := ShaderMaterial.new()
	mat.shader = shader
	glow_frame.material = mat

func setup_particles(color: Color):

	var size = $CanvasLayer/Control.size

	# ---------------- TOP ----------------
	p_top.position = Vector2(size.x / 2, 0)

	var m_top := ParticleProcessMaterial.new()
	m_top.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m_top.emission_box_extents = Vector3(size.x / 2, 2, 1)
	m_top.direction = Vector3(0, 1, 0) # Down
	m_top.spread = 25
	m_top.initial_velocity_min = 70
	m_top.initial_velocity_max = 90
	m_top.gravity = Vector3.ZERO
	m_top.color = color
	p_top.process_material = m_top
	p_top.lifetime = 0.35


	# ---------------- BOTTOM ----------------
	p_bottom.position = Vector2(size.x / 2, size.y)

	var m_bottom := ParticleProcessMaterial.new()
	m_bottom.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m_bottom.emission_box_extents = Vector3(size.x / 2, 2, 1)
	m_bottom.direction = Vector3(0, -1, 0) # Up
	m_bottom.spread = 25
	m_bottom.initial_velocity_min = 70
	m_bottom.initial_velocity_max = 90
	m_bottom.gravity = Vector3.ZERO
	m_bottom.color = color
	p_bottom.process_material = m_bottom
	p_bottom.lifetime = 0.35


	# ---------------- LEFT ----------------
	p_left.position = Vector2(0, size.y / 2)

	var m_left := ParticleProcessMaterial.new()
	m_left.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m_left.emission_box_extents = Vector3(2, size.y / 2, 1)
	m_left.direction = Vector3(1, 0, 0) # Right
	m_left.spread = 25
	m_left.initial_velocity_min = 70
	m_left.initial_velocity_max = 90
	m_left.gravity = Vector3.ZERO
	m_left.color = color
	p_left.process_material = m_left
	p_left.lifetime = 0.35


	# ---------------- RIGHT ----------------
	p_right.position = Vector2(size.x, size.y / 2)

	var m_right := ParticleProcessMaterial.new()
	m_right.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m_right.emission_box_extents = Vector3(2, size.y / 2, 1)
	m_right.direction = Vector3(-1, 0, 0) # Left
	m_right.spread = 25
	m_right.initial_velocity_min = 70
	m_right.initial_velocity_max = 90
	m_right.gravity = Vector3.ZERO
	m_right.color = color
	p_right.process_material = m_right
	p_right.lifetime = 0.35
#func setup_particles():
#
	#var size = get_viewport().get_visible_rect().size
#
	## TOP
## TOP
	#p_top.position = Vector2(size.x / 2, 0)
#
	#var m_top := ParticleProcessMaterial.new()
	#m_top.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	#m_top.emission_box_extents = Vector3(size.x / 2, 2, 1)
	#m_top.direction = Vector3(0, 1, 0)
	#m_top.spread = 25
	#m_top.initial_velocity_min = 40
	#m_top.initial_velocity_max = 70
	#m_top.gravity = Vector3.ZERO
#
	#p_top.process_material = m_top
	#
	## BOTTOM
	#p_bottom.position = Vector2(size.x / 2, size.y)
	#var m_bottom = p_bottom.process_material as ParticleProcessMaterial
	#m_bottom.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	#m_bottom.emission_box_extents = Vector3(size.x / 2, 2, 1) # <- Z = 1
	#m_bottom.direction = Vector3(0, -1, 0)
	#m_bottom.gravity = Vector3.ZERO
#
	## LEFT
	#p_left.position = Vector2(0, size.y / 2)
	#var m_left = p_left.process_material as ParticleProcessMaterial
	#m_left.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	#m_left.emission_box_extents = Vector3(2, size.y / 2, 1) # <- Z = 1
	#m_left.direction = Vector3(1, 0, 0)
	#m_left.gravity = Vector3.ZERO
#
	## RIGHT
	#p_right.position = Vector2(size.x, size.y / 2)
	#var m_right = p_right.process_material as ParticleProcessMaterial
	#m_right.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	#m_right.emission_box_extents = Vector3(2, size.y / 2, 1) # <- Z = 1
	#m_right.direction = Vector3(-1, 0, 0)
	#m_right.gravity = Vector3.ZERO
func apply_rarity_particles(rarity: int):

	# Turn all off first
	for p in [p_top, p_bottom, p_left, p_right]:
		p.emitting = false

	var color = RarityEnum.get_glow_color(rarity)
	setup_particles(color)
	match rarity:

		RarityEnum.Rarity.EPIC:
			p_top.emitting = true
			p_bottom.emitting = true
			set_particle_color(color)

		RarityEnum.Rarity.LEGENDARY:
			p_top.emitting = true
			p_bottom.emitting = true
			p_left.emitting = true
			p_right.emitting = true
			set_particle_color(color * 1.5)

		RarityEnum.Rarity.GALACTIC:
			p_top.emitting = true
			p_bottom.emitting = true
			p_left.emitting = true
			p_right.emitting = true
			set_galactic_particles()
func set_particle_color(color: Color):

	for p in [p_top, p_bottom, p_left, p_right]:
		var mat = p.process_material as ParticleProcessMaterial
		mat.color = color * 2.5
		
func set_galactic_particles():

	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1,0,0))
	gradient.add_point(0.25, Color(1,1,0))
	gradient.add_point(0.5, Color(0,1,1))
	gradient.add_point(0.75, Color(0,0,1))
	gradient.add_point(1.0, Color(1,0,1))

	for p in [p_top, p_bottom, p_left, p_right]:
		var mat = p.process_material as ParticleProcessMaterial
		mat.color_ramp = gradient
		
# Upgrades


func load_upgrade_preview():

	if current_item == null:
		return

	if mode == GarageMode.SHIPS:
		UserService.get_spaceship_upgrade_preview(
			current_item.id,
			_on_upgrade_preview_loaded
		)
	else:
		UserService.get_drone_upgrade_preview(
			current_item.id,
			_on_upgrade_preview_loaded
		)

func _on_upgrade_preview_loaded(code, response_text):

	if code != 200:
		print("Upgrade preview failed")
		return

	var json = JSON.parse_string(response_text)
	if json == null:
		return

	var resource_type = json.get("resource_type", "COINS")

	var emoji = ""
	match resource_type:
		"COINS":
			emoji = " 🪙"
		"DIAMONDS":
			emoji = " 💎"

	# Reset UI
	hit_points_button.disabled = true
	damage_button.disabled = true
	hit_rate_button.disabled = true

	for stat in json.get("stat_previews", []):

		var stat_type = stat.get("stat_type", "")
		var affordable = int(stat.get("affordable_count", 0))
		var upgrades_available = stat.get("upgrades_available", true)
		var upgrades = stat.get("upgrades", [])
		var current_level = int(stat.get("current_level", 1))
		var button
		var label

		match stat_type:
			"health":
				button = hit_points_button
				label = hit_points_up_value
				hit_points_level_label.text = "Level: " + str(current_level)

			"damage":
				button = damage_button
				label = damage_up_value
				damage_level_label.text = "Level: " + str(current_level)

			"hit_rate":
				button = hit_rate_button
				label = hit_rate_up_value
				hit_rate_level_label.text = "Level: " + str(current_level)
			_:
				continue

		if not upgrades_available:
			button.disabled = true
			button.text = "MAXED"
			label.text = ""
			continue

		if upgrades.is_empty():
			button.disabled = true
			button.text = "-"
			label.text = ""
			continue

		var step = upgrades[0]
		var value = step.get("upgrade_value", 0)
		var cost = int(step.get("cost", 0))

		button.text = str(cost) + emoji
		label.text = "+" + str(value)

		button.disabled = affordable <= 0
func upgrade_stat(stat_type: String):

	if not is_owned:
		return

	var count = 1  # For now single upgrade

	if mode == GarageMode.SHIPS:
		UserService.upgrade_spaceship(
			current_item.id,
			stat_type,
			count,
			_on_upgrade_done
		)
	else:
		UserService.upgrade_drone(
			current_item.id,
			stat_type,
			count,
			_on_upgrade_done
		)

func _on_upgrade_done(code, response_text):

	print("Upgrade response:", code, response_text)

	if code != 200:
		print("Upgrade failed")
		return

	var json = JSON.parse_string(response_text)
	if json == null:
		return

	if not json.get("success", false):
		print("Upgrade not successful:", json.get("message", ""))
		return

	# -------------------------
	# 1️⃣ Update spaceship stats in garage
	# -------------------------

	var updated_stats = json.get("updated_stats", null)
	if updated_stats != null:
		current_item.base_health = int(updated_stats.get("health", current_item.base_health))
		current_item.base_damage = int(updated_stats.get("damage", current_item.base_damage))
		current_item.base_hit_rate = float(updated_stats.get("hit_rate", current_item.base_hit_rate))

		update_stats_display(current_item)

	# -------------------------
	# 2️⃣ Update GameState economy
	# -------------------------

	var economy = json.get("user_economy", null)
	if economy != null:
		GameState.update_resources(
			economy.get("COINS", GameState.user.coins),
			economy.get("XP", GameState.user.exp),
			economy.get("DIAMONDS", GameState.user.diamonds),
			GameState.user.level
		)

	# -------------------------
	# 3️⃣ Update owned ships list
	# -------------------------

	var owned_ids = json.get("owned_ship_ids", [])

	GameState.owned_ship_ids = owned_ids.map(func(id):
		return str(id)
	)

	# -------------------------
	# 4️⃣ Refresh upgrade preview
	# -------------------------

	load_upgrade_preview()

func update_upgrade_visibility():

	var visible = is_owned

	hit_points_button.visible = visible
	damage_button.visible = visible
	hit_rate_button.visible = visible
	
	hit_points_up_value.visible = visible
	damage_up_value.visible = visible
	hit_rate_up_value.visible = visible
	
	hit_points_level_label.visible = visible
	damage_level_label.visible= visible
	hit_rate_level_label.visible = visible

	if visible:
		grid_container.columns = 4
		load_upgrade_preview()
	else:
		grid_container.columns = 1
