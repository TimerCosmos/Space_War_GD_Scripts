extends Node

var graphics_mode := "MEDIUM"

func _ready():
	get_tree().node_added.connect(_on_node_added)
# -------------------------
# INIT
# -------------------------
func load_settings():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")

	if err == OK:
		graphics_mode = config.get_value("graphics", "mode", "MEDIUM")


func save_settings():
	var config = ConfigFile.new()
	config.load("user://settings.cfg")

	config.set_value("graphics", "mode", graphics_mode)
	config.save("user://settings.cfg")


# -------------------------
# SWITCH MODE
# -------------------------
func cycle_mode():
	match graphics_mode:
		"LOW":
			graphics_mode = "MEDIUM"
		"MEDIUM":
			graphics_mode = "HIGH"
		"HIGH":
			graphics_mode = "LOW"

	save_settings()
	apply_to_scene(get_tree().current_scene)


# -------------------------
# APPLY TO WHOLE SCENE
# -------------------------
func apply_to_scene(node: Node):
	if node == null:
		return

	_apply_recursive(node)


func _apply_recursive(node: Node):

	if node is GPUParticles3D:
		if not node.is_in_group("graphics_exempt"):
			apply_particles(node)

	if node.has_method("apply_graphics_settings"):
		node.apply_graphics_settings()

	for child in node.get_children():
		_apply_recursive(child)


# -------------------------
# PARTICLE OPTIMIZATION
# -------------------------
func apply_particles(p: GPUParticles3D):

	if not p.has_meta("base_amount"):
		p.set_meta("base_amount", p.amount)
		p.set_meta("base_lifetime", p.lifetime)

	var base_amount = p.get_meta("base_amount")
	var base_lifetime = p.get_meta("base_lifetime")

	match graphics_mode:
		"LOW":
			p.amount = int(base_amount * 0.2)
			p.lifetime = min(base_lifetime, 0.75)
		"MEDIUM":
			p.amount = int(base_amount * 0.5)
			p.lifetime = base_lifetime
		"HIGH":
			p.amount = base_amount
			p.lifetime = base_lifetime

func _on_node_added(node: Node):
	# Apply only when node enters scene tree
	call_deferred("_apply_if_needed", node)


func _apply_if_needed(node: Node):
	if node == null:
		return

	_apply_recursive(node)
