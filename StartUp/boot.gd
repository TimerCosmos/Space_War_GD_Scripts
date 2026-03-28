extends Node

func _ready():
	await get_tree().process_frame

	# Load saved graphics (or fallback)
	GraphicsManager.load_settings()

	# If no saved file → detect once
	if not FileAccess.file_exists("user://settings.cfg"):
		detect_graphics()
		GraphicsManager.save_settings()

	# Apply EVERYTHING (particles, etc)
	GraphicsManager.apply_to_scene(get_tree().current_scene)

	# Optional: FPS cap (keep this here, not in manager)
	apply_fps_limit()

	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://Scenes/StartUp/splash.tscn")


# -----------------------------
# DEVICE DETECTION (ONLY FIRST RUN)
# -----------------------------
func detect_graphics():
	var cores = OS.get_processor_count()

	if cores <= 4:
		GraphicsManager.graphics_mode = "LOW"
	elif cores <= 6:
		GraphicsManager.graphics_mode = "MEDIUM"
	else:
		GraphicsManager.graphics_mode = "HIGH"


# -----------------------------
# FPS LIMIT (OPTIONAL BUT GOOD)
# -----------------------------
func apply_fps_limit():
	match GraphicsManager.graphics_mode:
		"LOW":
			Engine.max_fps = 30
		"MEDIUM":
			Engine.max_fps = 60
		"HIGH":
			Engine.max_fps = 120
