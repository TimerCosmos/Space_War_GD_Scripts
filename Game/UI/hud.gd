# No api call is needed

extends Control

@onready var health_bar: ProgressBar = $HealthBar

func _ready():
	add_to_group("hud")

func set_max_health(max_hp: int):
	health_bar.max_value = max_hp

func update_health(value: int, max_hp := -1):
	health_bar.value = value

func update_score(value: int):
	$ScoreLabel.text = "Score: " + str(value)
