extends Control

# ----------------------------------
# CONFIG
# ----------------------------------
const ROW_HEIGHT := 40
const LIMIT := 50  # items per page

var current_page := 0
var total := 0
var leaderboard_data := []

# ----------------------------------
# NODE REFS
# ----------------------------------
@onready var container = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer
@onready var header = $MarginContainer/VBoxContainer/Header

# Optional buttons (create if you want pagination UI)
@onready var next_btn = $"NextPage"
@onready var prev_btn = $"PrevPage"

# ----------------------------------
# READY
# ----------------------------------
func _ready():
	create_header()
	load_leaderboard()

# ----------------------------------
# API CALL
# ----------------------------------
const CACHE_DURATION := 60  # seconds

func load_leaderboard():

	var now = Time.get_unix_time_from_system()

	# 🧠 Use cache if valid
	if GameState.leaderboard_cache.size() > 0 and \
		now - GameState.leaderboard_last_fetch_time < CACHE_DURATION:

		print("Using cached leaderboard")
		leaderboard_data = GameState.leaderboard_cache
		total = leaderboard_data.size()
		current_page = 0
		render()
		return

	# 🌐 Otherwise fetch from API
	UserService.get_leaderboard(func(code, body):

		if code != 200:
			print("Leaderboard fetch failed")
			return

		var json = JSON.parse_string(body)
		if json == null:
			return
		leaderboard_data = json.get("leaderboard", [])
		total = leaderboard_data.size()

		# ✅ Save to cache
		GameState.leaderboard_cache = leaderboard_data
		GameState.leaderboard_last_fetch_time = Time.get_unix_time_from_system()

		current_page = 0
		render()
	)

# ----------------------------------
# RENDER TABLE
# ----------------------------------
func render():

	# Clear old rows
	for child in container.get_children():
		child.queue_free()

	# Show top 100 directly
	var end = min(LIMIT, leaderboard_data.size())

	for i in range(0, end):
		var entry = leaderboard_data[i]
		var row = create_row(entry)
		container.add_child(row)
# ----------------------------------
# CREATE ROW (NO EXTRA SCENE)
# ----------------------------------
func create_row(data: Dictionary) -> VBoxContainer:

	var row = HBoxContainer.new()
	row.custom_minimum_size.y = ROW_HEIGHT
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Alternate row color (zebra effect)
	if int(data.rank) % 2 == 0:
		row.modulate = Color(1,1,1,0.95)
	else:
		row.modulate = Color(0.9,0.9,0.9,0.85)
	# Highlight current player
	if GameState.user != null and data.username == GameState.user.name:
		row.modulate = Color(1, 1, 0.6)

	# Top 3 styling
	match int(data.rank):
		1: row.modulate = Color(1, 0.84, 0.2)
		2: row.modulate = Color(0.8, 0.8, 0.8)
		3: row.modulate = Color(0.8, 0.5, 0.3)

	# Add columns
	row.add_child(make_label(str(int(data.rank)), 50))
	row.add_child(make_label(data.username, 150))
	row.add_child(make_label(data.ship, 120))
	row.add_child(make_label(data.drone, 120))
	row.add_child(make_label(str(int(data.score)), 120))
	row.add_child(make_label(format_time(int(data.time_taken_seconds)), 100))
	
	var separator = ColorRect.new()
	separator.color = Color(1, 1, 1, 0.1) # subtle line
	separator.custom_minimum_size = Vector2(0, 1)

	# Wrap row + line inside a VBox
	var wrapper = VBoxContainer.new()
	wrapper.add_child(row)
	wrapper.add_child(separator)

	return wrapper

# ----------------------------------
# LABEL HELPER
# ----------------------------------
func make_label(text: String, min_width: int) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.custom_minimum_size.x = min_width
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return lbl

# ----------------------------------
# TIME FORMAT
# ----------------------------------
func format_time(seconds: int) -> String:
	var m = seconds / 60
	var s = seconds % 60
	return "%02d:%02d" % [m, s]

# ----------------------------------
# PAGINATION
# ----------------------------------
func next_page():
	if (current_page + 1) * LIMIT >= total:
		return

	current_page += 1
	load_leaderboard()

func prev_page():
	if current_page == 0:
		return

	current_page -= 1
	load_leaderboard()

func update_pagination_buttons():
	if next_btn:
		next_btn.disabled = (current_page + 1) * LIMIT >= total
	if prev_btn:
		prev_btn.disabled = current_page == 0

# ----------------------------------
# OPTIONAL: BUTTON SIGNALS
# ----------------------------------
func _on_NextPage_pressed():
	next_page()

func _on_PrevPage_pressed():
	prev_page()

func create_header():

	# Clear existing (safe)
	for child in header.get_children():
		child.queue_free()

	header.add_child(make_header_label("Rank", 50))
	header.add_child(make_header_label("Username", 150))
	header.add_child(make_header_label("Ship", 120))
	header.add_child(make_header_label("Drone", 120))
	header.add_child(make_header_label("Score", 120))
	header.add_child(make_header_label("Time", 100))
	
func make_header_label(text: String, min_width: int) -> Label:
	var lbl = Label.new()
	lbl.text = text	
	lbl.custom_minimum_size.x = min_width
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Styling
	lbl.add_theme_color_override("font_color", Color(1,1,1))
	lbl.add_theme_font_size_override("font_size", 25)

	return lbl
