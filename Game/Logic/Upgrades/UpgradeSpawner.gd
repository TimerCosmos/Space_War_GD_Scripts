extends Node3D

@export var upgrade_scene: PackedScene
@export var base_spacing := 5.0
@export var density_growth := 0.01

const FRONT_LIMIT_Z := -15.0
const BACK_LIMIT_Z := -100.0

const UPGRADE_PERCENT := 0.15

var lane_center := 0.0
var time_alive := 0.0
var spacing := base_spacing


func _ready():
	await get_tree().process_frame
	setup_lane()
	prefill_lane()


# ---------------------------------------
# Setup lane position
# ---------------------------------------

func setup_lane():

	var camera = get_viewport().get_camera_3d()

	if camera == null:
		push_error("UpgradeSpawner: No Camera3D found")
		return

	var world_width = BattlefieldLayout.get_world_width(camera, FRONT_LIMIT_Z)

	var upgrade_zone = world_width * UPGRADE_PERCENT

	var left_edge = -world_width / 2.0

	lane_center = left_edge + upgrade_zone * 0.5


# ---------------------------------------
# Prefill lane initially
# ---------------------------------------

func prefill_lane():

	var z := BACK_LIMIT_Z

	while z <= FRONT_LIMIT_Z:
		spawn_upgrade(z)
		z += spacing


# ---------------------------------------
# Maintain spacing as upgrades move
# ---------------------------------------

func _process(delta):

	time_alive += delta
	update_density()

	var farthest = get_farthest_upgrade_z()

	while -1 * (BACK_LIMIT_Z - farthest) >= spacing:
		farthest -= spacing
		spawn_upgrade(farthest)

# ---------------------------------------
# Spawn upgrade
# ---------------------------------------

func spawn_upgrade(z_pos):

	var upgrade = upgrade_scene.instantiate()

	get_tree().current_scene.add_child(upgrade)

	upgrade.global_position = Vector3(lane_center, 0, z_pos)

	var group_name = get_active_drop_group()
	var item = GameState.get_random_drop_item(group_name)

	if item != null:
		upgrade.configure_from_backend(item)


# ---------------------------------------
# Find farthest upgrade (most negative Z)
# ---------------------------------------

func get_farthest_upgrade_z():

	var upgrades = get_tree().get_nodes_in_group("upgrade")

	if upgrades.is_empty():
		return FRONT_LIMIT_Z

	var farthest = upgrades[0].global_position.z

	for u in upgrades:
		if u.global_position.z < farthest:
			farthest = u.global_position.z

	return farthest


# ---------------------------------------
# Density increases over time
# ---------------------------------------

func update_density():

	spacing = base_spacing / (1.0 + time_alive * density_growth)


# ---------------------------------------
# Choose drop group
# ---------------------------------------

func get_active_drop_group():

	var game = get_tree().get_first_node_in_group("game")

	if game == null:
		return "Initial Waves"

	var t = game.time_alive

	if t < 300:
		return "Initial Waves"
	elif t < 1200:
		return "Intermediate"
	else:
		return "Boss"
